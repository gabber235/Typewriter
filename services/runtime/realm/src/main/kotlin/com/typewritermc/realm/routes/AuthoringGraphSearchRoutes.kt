package com.typewritermc.realm.routes

import com.typewritermc.elements.ElementCatalog
import com.typewritermc.library.AuthoringResultKind
import com.typewritermc.library.AuthoringSearchContext
import com.typewritermc.library.AuthoringSearchMatch
import com.typewritermc.library.BOOK_PAGES_RELATION_ID
import com.typewritermc.library.Book
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.PAGE_ELEMENTS_RELATION_ID
import com.typewritermc.library.Page
import com.typewritermc.library.ResourceIdentity
import com.typewritermc.library.ResourceTypeDescriptor
import com.typewritermc.library.Tag
import com.typewritermc.pages.PageCatalog
import com.typewritermc.realm.repository.AuthoringGraphQueryResult
import com.typewritermc.realm.repository.AuthoringGraphRepository
import com.typewritermc.realm.repository.AuthoringGraphResource
import com.typewritermc.realm.repository.AuthoringResourceKind
import com.typewritermc.realm.repository.GraphSelection
import com.typewritermc.realm.repository.ResourceFilter
import com.typewritermc.realm.repository.ResourceSeed
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.Color
import com.typewritermc.types.DataValue
import com.typewritermc.types.Icon
import com.typewritermc.types.Ref
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.search.RealmSearchSelector
import skirout.editor.v1.search.RealmSearchSelectorExpression
import skirout.editor.v1.search.RealmSearchSelectorOperator
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.library.v1.authoring.AuthoringDiagnostic
import skirout.library.v1.authoring.AuthoringSearchHit
import skirout.library.v1.authoring.PresentationSubject
import skirout.library.v1.authoring.SearchAuthoringGraphRequest
import skirout.library.v1.authoring.SearchAuthoringGraphResponse
import skirout.library.v1.authoring.SearchFacetResult

/** Executes ranked text search over the same hydrated graph used by deterministic authoring queries. */
internal class AuthoringGraphSearchRoutes(
    private val repository: AuthoringGraphRepository,
    private val contracts: LibraryContracts,
    private val subjects: AuthoringSubjectProjector,
    private val elements: () -> ElementCatalog,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.searchAuthoringGraph) { call ->
                runCatching { search(call.request) }
                    .getOrElse { failure ->
                        SearchAuthoringGraphResponse.createInvalid(
                            diagnostics =
                                listOf(
                                    AuthoringDiagnostic(
                                        code = "invalid-search",
                                        message = failure.message ?: "Invalid authoring graph search.",
                                        resource = null,
                                        path = null,
                                    ),
                                ),
                        )
                    }
            }
        }

    private suspend fun search(request: SearchAuthoringGraphRequest): SearchAuthoringGraphResponse {
        val filter = request.resources.toDomain().withTarget(request.referenceTarget)
        val selection =
            request.scope?.toDomain()?.let { scoped ->
                scoped.copy(
                    seed =
                        when (val seed = scoped.seed) {
                            is ResourceSeed.Ids -> seed
                            is ResourceSeed.Scan -> ResourceSeed.Scan(seed.filter.intersect(filter))
                        },
                )
            } ?: GraphSelection(
                SEARCH_SELECTION,
                ResourceSeed.Scan(filter),
                listOf(
                    com.typewritermc.realm.repository.RelationStep(
                        direction = com.typewritermc.realm.repository.RelationDirection.BOTH,
                    ),
                ),
            )
        return when (val result = repository.query(request.generation.value, listOf(selection))) {
            is AuthoringGraphQueryResult.CatalogChanged -> {
                SearchAuthoringGraphResponse.createCatalogChanged(
                    actualGeneration = CatalogGeneration(value = result.actualGeneration),
                )
            }

            is AuthoringGraphQueryResult.Invalid -> {
                SearchAuthoringGraphResponse.createInvalid(
                    diagnostics =
                        listOf(
                            AuthoringDiagnostic(
                                code = result.code,
                                message = result.message,
                                resource = null,
                                path = null,
                            ),
                        ),
                )
            }

            is AuthoringGraphQueryResult.Success -> {
                val membership =
                    result.snapshot.selections
                        .single()
                        .resourceIds
                        .toSet()
                val candidates =
                    result.snapshot.resources.filter {
                        it.id in membership && (filter.kinds.isEmpty() || it.kind in filter.kinds)
                    }
                val index = SearchGraphIndex(result.snapshot.resources, result.snapshot.edges, elements())
                val terms =
                    request.query.terms
                        .map(String::lowercase)
                        .filter(String::isNotBlank)
                val ranked =
                    candidates
                        .mapNotNull { resource ->
                            if (!index.matchesSelectors(resource, request.query.selectors, request.query.selectorExpression)) {
                                null
                            } else {
                                index.score(resource, terms)?.let { score -> resource to score }
                            }
                        }.sortedWith(compareByDescending<Pair<AuthoringGraphResource, Int>> { it.second }.thenBy { it.first.id.value })
                        .take(MAX_SEARCH_RESULTS)
                        .map { (resource) -> resource.toSearchHit(result.snapshot.edges, index, terms) }
                SearchAuthoringGraphResponse.createSuccess(
                    generation = CatalogGeneration(value = result.snapshot.generation),
                    sequence = result.snapshot.sequence,
                    hits = ranked,
                    facets = request.facets.map { facet -> index.facet(candidates, facet) },
                    diagnostics = emptyList(),
                )
            }
        }
    }

    private fun AuthoringGraphResource.toSearchHit(
        edges: List<com.typewritermc.realm.repository.StoredResourceRelation>,
        index: SearchGraphIndex,
        terms: List<String>,
    ): AuthoringSearchHit {
        val context = index.context(this, terms)
        return AuthoringSearchHit(
            resource = id.toWire(),
            subject = subjects.project(this, edges),
            context = subjects.encode(context),
        )
    }
}

private fun ResourceFilter.withTarget(target: skirout.editor.v1.type_catalog.TypeExpression?): ResourceFilter =
    if (target == null) this else copy(assignableTo = SkirTypeCodec.decode(target).getOrThrow())

private fun ResourceFilter.intersect(other: ResourceFilter): ResourceFilter =
    ResourceFilter(
        kinds =
            when {
                kinds.isEmpty() -> other.kinds
                other.kinds.isEmpty() -> kinds
                else -> kinds intersect other.kinds
            },
        assignableTo = other.assignableTo ?: assignableTo,
    )

internal class SearchGraphIndex(
    resources: List<AuthoringGraphResource>,
    edges: List<com.typewritermc.realm.repository.StoredResourceRelation>,
    elements: ElementCatalog,
) {
    private val resources = resources.associateBy(AuthoringGraphResource::id)
    private val pagesByElement = declaredOwners(edges, PAGE_ELEMENTS_RELATION_ID)
    private val booksByPage = declaredOwners(edges, BOOK_PAGES_RELATION_ID)
    private val descriptors = elements.entries.associateBy { it.descriptor.type }
    private val tags = resources.filter { it.kind == AuthoringResourceKind.TAG }.associateBy(AuthoringGraphResource::id)

    fun score(
        resource: AuthoringGraphResource,
        terms: List<String>,
    ): Int? {
        val text = searchableText(resource).map(String::lowercase)
        if (terms.any { term -> text.none { candidate -> candidate.matchesTerm(term) } }) return null
        return terms.sumOf { term -> text.maxOfOrNull { candidate -> candidate.matchScore(term) } ?: 0 }
    }

    fun matchesSelectors(
        resource: AuthoringGraphResource,
        selectors: List<RealmSearchSelector>,
        expression: RealmSearchSelectorExpression?,
    ): Boolean {
        val evaluator: (RealmSearchSelector) -> Boolean = { selector ->
            val value = selector.value?.trim()?.lowercase()
            value == null || selectorValues(resource, selector.selectorId).any { it.lowercase() == value }
        }
        return expression?.evaluate(evaluator) ?: selectors.all(evaluator)
    }

    fun context(
        resource: AuthoringGraphResource,
        terms: List<String>,
    ): AuthoringSearchContext {
        val page = owningPage(resource)
        val book = owningBook(resource, page)
        val match =
            terms.firstNotNullOfOrNull { term ->
                searchableText(resource).firstNotNullOfOrNull { text ->
                    val start = text.lowercase().indexOf(term)
                    if (start < 0) null else AuthoringSearchMatch(text, start, start + term.length)
                }
            }
        return AuthoringSearchContext(
            kind = resource.kind.toResultKind(),
            book = book?.let { Ref<Book>(it.id) },
            page = page?.let { Ref<Page>(it.id) },
            chapter = page?.stringField("chapter")?.let(ChapterPath::parse),
            match = match,
        )
    }

    fun facet(
        candidates: List<AuthoringGraphResource>,
        request: skirout.library.v1.authoring.SearchFacetRequest,
    ): SearchFacetResult {
        val values = candidates.flatMap { selectorValues(it, request.facetId.value) }.distinct().sorted()
        val partial = request.partial?.lowercase().orEmpty()
        val suggestions = values.filter { partial.isEmpty() || it.lowercase().startsWith(partial) }.take(MAX_FACET_RESULTS)
        val normalized = values.associateBy(String::lowercase)
        return SearchFacetResult(
            facetId = request.facetId,
            suggestions = suggestions,
            accepted = request.validate.filter { it.lowercase() in normalized },
            rejected = request.validate.filterNot { it.lowercase() in normalized },
        )
    }

    private fun selectorValues(
        resource: AuthoringGraphResource,
        selectorId: String,
    ): List<String> =
        when (selectorId.lowercase()) {
            "book" -> {
                owningBook(resource, owningPage(resource))?.identityValues().orEmpty()
            }

            "page" -> {
                owningPage(resource)?.identityValues().orEmpty()
            }

            "tag" -> {
                owningBook(resource, owningPage(resource))?.tagValues().orEmpty()
            }

            "type" -> {
                if (resource.kind != AuthoringResourceKind.ELEMENT) {
                    emptyList()
                } else {
                    val root = (resource.content.rootType as TypeExpression.Named).reference
                    listOfNotNull(root.id.toString(), descriptors[root]?.descriptor?.name)
                }
            }

            "kind" -> {
                listOf(resource.kind.name.lowercase())
            }

            else -> {
                emptyList()
            }
        }

    private fun searchableText(resource: AuthoringGraphResource): List<String> =
        buildList {
            add(resource.id.value)
            add(resource.kind.name)
            resource.content.rootValue.collectText(this)
            owningPage(resource)?.let { addAll(it.identityValues()) }
            owningBook(resource, owningPage(resource))?.let { addAll(it.identityValues()) }
            val root = (resource.content.rootType as TypeExpression.Named).reference
            descriptors[root]?.descriptor?.name?.let(::add)
        }

    private fun owningPage(resource: AuthoringGraphResource): AuthoringGraphResource? =
        when (resource.kind) {
            AuthoringResourceKind.PAGE -> resource
            AuthoringResourceKind.ELEMENT -> pagesByElement[resource.id]?.let(resources::get)
            else -> null
        }

    private fun owningBook(
        resource: AuthoringGraphResource,
        page: AuthoringGraphResource?,
    ): AuthoringGraphResource? =
        when (resource.kind) {
            AuthoringResourceKind.BOOK -> resource
            AuthoringResourceKind.PAGE -> booksByPage[resource.id]?.let(resources::get)
            AuthoringResourceKind.ELEMENT -> page?.let { booksByPage[it.id] }?.let(resources::get)
            AuthoringResourceKind.TAG -> null
        }

    private fun AuthoringGraphResource.identityValues(): List<String> = listOfNotNull(id.value, stringField("title"), stringField("name"))

    private fun AuthoringGraphResource.tagValues(): List<String> {
        val direct = referenceIds("tags")
        val inherited =
            buildSet {
                val pending = ArrayDeque<ResourceId>()
                pending.addAll(direct)
                while (pending.isNotEmpty()) {
                    val id = pending.removeFirst()
                    if (!add(id)) continue
                    tags[id]?.referenceIds("parents")?.forEach(pending::addLast)
                }
            }
        return inherited.flatMap { id -> tags[id]?.identityValues() ?: listOf(id.value) }
    }
}

private fun declaredOwners(
    edges: List<com.typewritermc.realm.repository.StoredResourceRelation>,
    relationId: String,
): Map<ResourceId, ResourceId> =
    edges
        .mapNotNull { edge ->
            val declared = edge.origin as? com.typewritermc.realm.repository.ResourceRelationOrigin.Declared
            if (declared?.relationId == RelationId(relationId)) edge.target to edge.source else null
        }.toMap()

private fun AuthoringGraphResource.stringField(name: String): String? =
    ((content.rootValue as? DataValue.Record)?.fields?.get(name) as? DataValue.StringValue)?.value

private fun AuthoringGraphResource.referenceIds(name: String): List<ResourceId> =
    when (val value = (content.rootValue as? DataValue.Record)?.fields?.get(name)) {
        is DataValue.Reference -> listOf(value.id)
        is DataValue.ListValue -> value.values.filterIsInstance<DataValue.Reference>().map(DataValue.Reference::id)
        else -> emptyList()
    }

private fun RealmSearchSelectorExpression.evaluate(predicate: (RealmSearchSelector) -> Boolean): Boolean =
    when (this) {
        is RealmSearchSelectorExpression.SelectorWrapper -> {
            predicate(value)
        }

        is RealmSearchSelectorExpression.BinaryWrapper -> {
            when (value.operator_) {
                RealmSearchSelectorOperator.AND -> value.left.evaluate(predicate) && value.right.evaluate(predicate)
                RealmSearchSelectorOperator.OR -> value.left.evaluate(predicate) || value.right.evaluate(predicate)
                else -> false
            }
        }

        is RealmSearchSelectorExpression.NotWrapper -> {
            !value.expression.evaluate(predicate)
        }

        else -> {
            false
        }
    }

private fun DataValue.collectText(target: MutableList<String>) {
    when (this) {
        is DataValue.StringValue -> target += value
        is DataValue.Record -> fields.values.forEach { it.collectText(target) }
        is DataValue.ListValue -> values.forEach { it.collectText(target) }
        is DataValue.MapValue -> entries.forEach { entry -> entry.value.collectText(target) }
        is DataValue.Polymorphic -> value.collectText(target)
        else -> Unit
    }
}

private fun String.matchScore(term: String): Int =
    when {
        this == term -> 100
        startsWith(term) -> 50
        term in this -> 10
        levenshteinDistance(term) <= 1 -> 5
        else -> 0
    }

private fun String.matchesTerm(term: String): Boolean = term in this || levenshteinDistance(term) <= 1

private fun String.levenshteinDistance(other: String): Int {
    if (this == other) return 0
    if (kotlin.math.abs(length - other.length) > 1) return 2
    var previous = IntArray(other.length + 1) { it }
    for (leftIndex in indices) {
        val current = IntArray(other.length + 1)
        current[0] = leftIndex + 1
        for (rightIndex in other.indices) {
            current[rightIndex + 1] =
                minOf(
                    current[rightIndex] + 1,
                    previous[rightIndex + 1] + 1,
                    previous[rightIndex] + if (this[leftIndex] == other[rightIndex]) 0 else 1,
                )
        }
        previous = current
    }
    return previous.last()
}

private fun AuthoringResourceKind.toResultKind(): AuthoringResultKind =
    when (this) {
        AuthoringResourceKind.BOOK -> AuthoringResultKind.BOOK
        AuthoringResourceKind.TAG -> AuthoringResultKind.TAG
        AuthoringResourceKind.PAGE -> AuthoringResultKind.PAGE
        AuthoringResourceKind.ELEMENT -> AuthoringResultKind.ELEMENT
    }

private const val SEARCH_SELECTION = "search"
private const val MAX_SEARCH_RESULTS = 100
private const val MAX_FACET_RESULTS = 20
