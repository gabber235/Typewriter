package com.typewritermc.realm.repository.search

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.surrealdb.Value
import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementSearchMode
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ElementValuePath
import com.typewritermc.library.BookId
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.PageId
import com.typewritermc.library.PageKindRef
import com.typewritermc.library.TagId
import com.typewritermc.realm.repository.AuthoringResourceRef
import com.typewritermc.realm.repository.utils.elementPlacement
import com.typewritermc.realm.repository.utils.pageKindRef
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.realm.repository.utils.toElementInstanceId
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.realm.repository.utils.toResourceId
import com.typewritermc.realm.repository.utils.toTagId
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.ReferenceFamily
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.acceptsReferenceCandidate
import com.typewritermc.types.referenceFamily

internal fun Surreal.searchAuthoring(
    request: AuthoringSearchRequest,
    catalog: Map<ElementTypeId, ElementSearchCatalogEntry>,
    typeCatalog: TypeCatalog,
): AuthoringSearchResult {
    val textQuery =
        AuthoringTextQuery(
            request.terms
                .map(String::lowercase)
                .filter(String::isNotBlank)
                .take(MAX_QUERY_TERMS)
                .toSet(),
        )
    val scope = resolveScope(request, catalog, typeCatalog)
    if (textQuery.terms.isEmpty()) {
        val defaults = searchDefaults(scope, DEFAULT_SEARCH_LIMIT)
        val contexts = searchContexts(request, scope)
        return AuthoringSearchResult(
            resolveBookTags(AuthoringSearchPlanner.rankDefaults(defaults, contexts)),
            scope.selectorValidations,
        )
    }
    val limit = DEFAULT_SEARCH_LIMIT
    val batch = AuthoringSearchQueryBatch(this)
    val pendingCandidates = mutableListOf<PendingSearchResult<List<AuthoringSearchCandidate>>>()
    exactIdentity(batch, request.query.trim(), scope)?.let(pendingCandidates::add)
    if (scope.allows(AuthoringResultKind.ELEMENT)) {
        textQuery.terms.mapTo(pendingCandidates) { term -> exactElement(batch, term, scope) }
    }

    fun searchNames(
        term: String,
        lane: NameSearchLane,
    ) {
        if (scope.allows(AuthoringResultKind.BOOK)) pendingCandidates += searchBookNames(batch, term, scope, limit, lane)
        if (scope.allows(AuthoringResultKind.PAGE)) pendingCandidates += searchPageNames(batch, term, scope, limit, lane)
        if (scope.allows(AuthoringResultKind.TAG)) pendingCandidates += searchTagNames(batch, term, scope, limit, lane)
        if (scope.allows(AuthoringResultKind.ELEMENT)) {
            pendingCandidates += searchElementNames(batch, term, scope, limit, lane)
        }
    }

    NameSearchLane.entries.forEach { lane ->
        textQuery.terms.forEach { term ->
            if (lane != NameSearchLane.APPROXIMATE || term.approximateNgrams().isNotEmpty()) {
                searchNames(term, lane)
            }
        }
    }
    if (scope.allows(AuthoringResultKind.ELEMENT)) {
        pendingCandidates += searchElementContent(batch, textQuery, scope, catalog, limit)
    }
    batch.execute()
    val candidates = pendingCandidates.flatMap(PendingSearchResult<List<AuthoringSearchCandidate>>::value)
    val contexts = searchContexts(request, scope)
    val ranked = AuthoringSearchPlanner.rank(candidates, contexts, limit)
    return AuthoringSearchResult(resolveBookTags(ranked), scope.selectorValidations)
}

internal fun Surreal.suggestAuthoring(
    request: AuthoringSelectorSuggestionRequest,
    catalog: Map<ElementTypeId, ElementSearchCatalogEntry>,
): AuthoringSelectorSuggestions {
    val scope = resolveGeneralScope(request.filter, catalog)
    if (request.kind == AuthoringSelectorKind.ELEMENT_TYPE) {
        val partial = request.partial.trim().lowercase()
        return catalog
            .map { (id, entry) -> id.value.toString() to entry.displayName }
            .filter { (id, name) -> partial.isEmpty() || id.lowercase().contains(partial) || name.lowercase().contains(partial) }
            .sortedWith(compareBy<Pair<String, String>> { !it.second.lowercase().startsWith(partial) }.thenBy { it.second })
            .map(Pair<String, String>::second)
            .distinct()
            .toSuggestions()
    }
    val (table, field, fields) =
        when (request.kind) {
            AuthoringSelectorKind.BOOK -> Triple("book", "title", SearchResourceFields(book = "id"))
            AuthoringSelectorKind.PAGE -> Triple("page", "name", SearchResourceFields(book = "book", page = "id"))
            AuthoringSelectorKind.TAG -> Triple("tag", "name", SearchResourceFields(tag = "id"))
            AuthoringSelectorKind.ELEMENT_TYPE -> error("Handled above")
        }
    val conditions = mutableListOf<String>()
    val bindings =
        mutableMapOf<String, Any>(
            "partial" to request.partial.trim().lowercase(),
            "threshold" to FUZZY_THRESHOLD,
            "limit" to SELECTOR_SUGGESTION_LIMIT + 1,
        )
    scope.addSqlFilter(conditions, bindings, fields)
    conditions +=
        $$"($partial = '' OR string::lowercase($$field) CONTAINS $partial " +
        $$"OR string::similarity::jaro_winkler(string::lowercase($$field), $partial) >= $threshold)"
    return query(
        "SELECT $field AS value, string::starts_with(string::lowercase($field), \$partial) AS prefix, " +
            "string::similarity::jaro_winkler(string::lowercase($field), \$partial) AS similarity " +
            "FROM $table WHERE ${conditions.joinToString(" AND ")} " +
            "ORDER BY prefix DESC, similarity DESC, value LIMIT \$limit;",
        bindings,
    ).take(0).array.map { it.getObject().get("value").string }.distinct().toSuggestions()
}

private fun List<String>.toSuggestions(): AuthoringSelectorSuggestions =
    AuthoringSelectorSuggestions(
        values = take(SELECTOR_SUGGESTION_LIMIT),
        exhaustive = size <= SELECTOR_SUGGESTION_LIMIT,
    )

internal data class AuthoringSearchContext(
    val page: PageId,
    val book: BookId,
    val chapter: ChapterPath,
)

private fun Surreal.searchContext(page: PageId): AuthoringSearchContext? {
    val value =
        query(
            $$"SELECT id, book, chapter FROM page WHERE id = $page LIMIT 1;",
            mapOf("page" to page.surrealId()),
        ).take(0).firstObjectOrNull() ?: return null
    return AuthoringSearchContext(
        page = value.get("id").recordId.toPageId(),
        book = value.get("book").recordId.toBookId(),
        chapter = ChapterPath.parse(value.get("chapter").string),
    )
}

private fun Surreal.searchContexts(
    request: AuthoringSearchRequest,
    scope: ResolvedSearchScope,
): List<AuthoringSearchContext> {
    request.contextPage?.let(::searchContext)?.let { return listOf(it) }
    return scope.reference
        ?.origins
        .orEmpty()
        .mapNotNull(::originPage)
        .distinct()
        .mapNotNull(::searchContext)
}

private data class ResolvedSearchScope(
    val expression: SearchFilterExpression<ResolvedAuthoringSearchFilter>?,
    val selectorValidations: List<AuthoringSelectorValidation> = emptyList(),
    val reference: ResolvedReferenceScope? = null,
) {
    fun allows(kind: AuthoringResultKind): Boolean =
        (expression?.resultKinds()?.contains(kind) ?: true) &&
            (reference?.kind == null || reference.kind == kind)
}

private data class ResolvedReferenceScope(
    val kind: AuthoringResultKind,
    val origins: List<ResourceId>,
    val allowedBook: RecordId? = null,
    val allowedPageKinds: Set<PageKindRef> = emptySet(),
    val allowedElementTypes: Set<ElementTypeId> = emptySet(),
)

private enum class AuthoringResultKind {
    BOOK,
    TAG,
    PAGE,
    ELEMENT,
}

private data class ResolvedAuthoringSearchFilter(
    val kind: AuthoringSelectorKind,
    val records: Set<RecordId> = emptySet(),
    val taggedBooks: Set<RecordId> = emptySet(),
    val elementTypes: Set<ElementTypeId> = emptySet(),
) {
    val accepted: Boolean
        get() = records.isNotEmpty() || elementTypes.isNotEmpty()
}

private fun Surreal.resolveScope(
    request: AuthoringSearchRequest,
    catalog: Map<ElementTypeId, ElementSearchCatalogEntry>,
    typeCatalog: TypeCatalog,
): ResolvedSearchScope {
    val reference = request.referenceScope?.let { resolveReferenceScope(it, catalog, typeCatalog) }
    val general = resolveGeneralScope(request.filter, catalog)
    return general.copy(reference = reference)
}

private fun Surreal.resolveGeneralScope(
    filter: SearchFilterExpression<AuthoringSearchFilter>?,
    catalog: Map<ElementTypeId, ElementSearchCatalogEntry>,
): ResolvedSearchScope {
    if (filter == null) return ResolvedSearchScope(null)
    val values = filter.values().distinct()
    val resolved = values.associateWith { resolveFilter(it, catalog) }
    return ResolvedSearchScope(
        expression = filter.mapValues(resolved::getValue),
        selectorValidations =
            resolved.map { (source, value) ->
                AuthoringSelectorValidation(source.kind, source.value, value.accepted)
            },
    )
}

private fun Surreal.resolveReferenceScope(
    scope: AuthoringReferenceScope,
    catalog: Map<ElementTypeId, ElementSearchCatalogEntry>,
    typeCatalog: TypeCatalog,
): ResolvedReferenceScope {
    val family = typeCatalog.referenceFamily(scope.target)
    val kind =
        when (family) {
            ReferenceFamily.BOOK -> AuthoringResultKind.BOOK
            ReferenceFamily.PAGE -> AuthoringResultKind.PAGE
            ReferenceFamily.TAG -> AuthoringResultKind.TAG
            ReferenceFamily.ELEMENT -> AuthoringResultKind.ELEMENT
        }
    val allowedBook =
        if (family == ReferenceFamily.PAGE || family == ReferenceFamily.ELEMENT) {
            require(scope.origins.isNotEmpty()) { "Page and element references require an origin." }
            val books = scope.origins.mapNotNull(::originBook)
            require(books.size == scope.origins.size && books.distinct().size == 1) {
                "Every reference origin must resolve to one shared Book."
            }
            books.first()
        } else {
            null
        }
    val acceptsBroadPage = typeCatalog.acceptsReferenceCandidate(scope.target, listOf(PAGE_TYPE))
    val allowedPageKinds =
        if (family == ReferenceFamily.PAGE && !acceptsBroadPage) {
            typeCatalog.definitions
                .map { it.id }
                .filter { typeCatalog.acceptsReferenceCandidate(scope.target, listOf(it)) }
                .mapNotNullTo(linkedSetOf()) { reference ->
                    val id = reference.id as? com.typewritermc.types.TypeId.Declared ?: return@mapNotNullTo null
                    PageKindRef(com.typewritermc.library.PageKindId(id.id), reference.revision)
                }
        } else {
            emptySet()
        }
    val allowedElementTypes =
        if (family == ReferenceFamily.ELEMENT) {
            catalog
                .filterValues { entry ->
                    entry.rootType()?.let { typeCatalog.acceptsReferenceCandidate(scope.target, listOf(it)) } == true
                }.keys
        } else {
            emptySet()
        }
    require(family != ReferenceFamily.ELEMENT || allowedElementTypes.isNotEmpty()) {
        "Reference target has no compatible element types."
    }
    return ResolvedReferenceScope(kind, scope.origins, allowedBook, allowedPageKinds, allowedElementTypes)
}

private fun Surreal.originPage(origin: ResourceId): PageId? =
    when (origin.table) {
        "page" -> {
            origin.surrealId().toPageId()
        }

        "element" -> {
            val value = query("SELECT VALUE page FROM ONLY \$origin;", mapOf("origin" to origin.surrealId())).take(0)
            value.takeUnless { it.isNone || it.isNull }?.getRecordId()?.toPageId()
        }

        else -> {
            null
        }
    }

private fun Surreal.originBook(origin: ResourceId): RecordId? {
    val id = origin.surrealId()
    val expression =
        when (origin.table) {
            "book" -> "IF record::exists(\$origin) { RETURN \$origin; }; RETURN NONE;"
            "page" -> "SELECT VALUE book FROM ONLY \$origin;"
            "element" -> "SELECT VALUE page.book FROM ONLY \$origin;"
            else -> return null
        }
    val value = query(expression, mapOf("origin" to id)).take(0)
    return value.takeUnless { it.isNone || it.isNull }?.getRecordId()
}

private fun Surreal.resolveFilter(
    filter: AuthoringSearchFilter,
    catalog: Map<ElementTypeId, ElementSearchCatalogEntry>,
): ResolvedAuthoringSearchFilter {
    val value = filter.value.trim()
    return when (filter.kind) {
        AuthoringSelectorKind.BOOK -> {
            ResolvedAuthoringSearchFilter(
                AuthoringSelectorKind.BOOK,
                resolveNamedRecords("book", "title", listOf(value)),
            )
        }

        AuthoringSelectorKind.PAGE -> {
            ResolvedAuthoringSearchFilter(
                AuthoringSelectorKind.PAGE,
                resolveNamedRecords("page", "name", listOf(value)),
            )
        }

        AuthoringSelectorKind.TAG -> {
            val selected = resolveNamedRecords("tag", "name", listOf(value))
            ResolvedAuthoringSearchFilter(
                AuthoringSelectorKind.TAG,
                records = selected,
                taggedBooks = booksWithEffectiveTags(selected),
            )
        }

        AuthoringSelectorKind.ELEMENT_TYPE -> {
            val normalized = value.lowercase()
            val selectedTypes =
                catalog
                    .filter { (id, entry) ->
                        id.value.toString().lowercase() == normalized || entry.displayName.lowercase() == normalized
                    }.values
                    .mapNotNull(ElementSearchCatalogEntry::rootType)
            ResolvedAuthoringSearchFilter(
                AuthoringSelectorKind.ELEMENT_TYPE,
                elementTypes =
                    catalog
                        .filterValues { entry -> selectedTypes.any(entry::isTypeOrSubtypeOf) }
                        .keys,
            )
        }
    }
}

internal fun ElementSearchCatalogEntry.rootType(): ResolvedTypeRef? = (graph.root as? TypeExpression.Named)?.reference

private fun ElementSearchCatalogEntry.isTypeOrSubtypeOf(target: ResolvedTypeRef): Boolean {
    val candidate = rootType() ?: return false
    if (candidate == target) return true
    val declaration = candidate.copy(arguments = emptyList())
    return TypeCatalog(graph.definitions).subtypesOf(target).any { it.id == declaration }
}

private fun SearchFilterExpression<ResolvedAuthoringSearchFilter>.resultKinds(): Set<AuthoringResultKind> =
    when (this) {
        is SearchFilterExpression.Value -> filter.kind.resultKinds()
        is SearchFilterExpression.And -> left.resultKinds() intersect right.resultKinds()
        is SearchFilterExpression.Or -> left.resultKinds() union right.resultKinds()
        is SearchFilterExpression.Not -> AuthoringResultKind.entries.toSet()
    }

private fun AuthoringSelectorKind.resultKinds(): Set<AuthoringResultKind> =
    when (this) {
        AuthoringSelectorKind.BOOK -> setOf(AuthoringResultKind.PAGE, AuthoringResultKind.ELEMENT)
        AuthoringSelectorKind.PAGE, AuthoringSelectorKind.ELEMENT_TYPE -> setOf(AuthoringResultKind.ELEMENT)
        AuthoringSelectorKind.TAG -> setOf(AuthoringResultKind.BOOK, AuthoringResultKind.PAGE, AuthoringResultKind.ELEMENT)
    }

private fun <From, To> SearchFilterExpression<From>.mapValues(transform: (From) -> To): SearchFilterExpression<To> =
    when (this) {
        is SearchFilterExpression.Value -> SearchFilterExpression.Value(transform(filter))
        is SearchFilterExpression.And -> SearchFilterExpression.And(left.mapValues(transform), right.mapValues(transform))
        is SearchFilterExpression.Or -> SearchFilterExpression.Or(left.mapValues(transform), right.mapValues(transform))
        is SearchFilterExpression.Not -> SearchFilterExpression.Not(expression.mapValues(transform))
    }

private fun <Filter> SearchFilterExpression<Filter>.values(): List<Filter> =
    when (this) {
        is SearchFilterExpression.Value -> listOf(filter)
        is SearchFilterExpression.And -> left.values() + right.values()
        is SearchFilterExpression.Or -> left.values() + right.values()
        is SearchFilterExpression.Not -> expression.values()
    }

private fun Surreal.resolveNamedRecords(
    table: String,
    nameField: String,
    selectors: List<String>,
): Set<RecordId> {
    val normalized = selectors.map(String::lowercase).toSet()
    return query($$"SELECT id, $$nameField AS name FROM type::table($table);", mapOf("table" to table))
        .take(0)
        .array
        .mapNotNull { row ->
            val value = row.getObject()
            val id = value.get("id").recordId
            val name = value.get("name").string
            id.takeIf { name.lowercase() in normalized || id.selectorText().lowercase() in normalized }
        }.toSet()
}

private fun Surreal.booksWithEffectiveTags(selected: Set<RecordId>): Set<RecordId> {
    if (selected.isEmpty()) return emptySet()
    val parentsByChild =
        query("SELECT source, target FROM resource_reference WHERE string::starts_with(slot, 'parents:');")
            .take(0)
            .array
            .associate { row ->
                val value = row.getObject()
                value.get("source").recordId to value.get("target").recordId
            }.entries
            .groupBy({ it.key }, { it.value })

    fun effectiveTags(direct: RecordId): Set<RecordId> {
        val effective = linkedSetOf(direct)
        val pending = ArrayDeque<RecordId>().apply { add(direct) }
        while (pending.isNotEmpty()) {
            parentsByChild[pending.removeFirst()].orEmpty().forEach { parent ->
                if (effective.add(parent)) pending.add(parent)
            }
        }
        return effective
    }
    return query("SELECT source, target FROM resource_reference WHERE string::starts_with(slot, 'tags:');")
        .take(0)
        .array
        .map(Value::getObject)
        .filter { edge -> effectiveTags(edge.get("target").recordId).any(selected::contains) }
        .mapTo(linkedSetOf()) { edge -> edge.get("source").recordId }
}

private data class SearchResourceFields(
    val book: String? = null,
    val page: String? = null,
    val tag: String? = null,
    val elementType: String? = null,
    val pageKind: String? = null,
)

private data class SearchSqlFilter(
    val condition: String,
    val bindings: Map<String, Any>,
)

private fun ResolvedSearchScope.sqlFilter(fields: SearchResourceFields): SearchSqlFilter? {
    val expression = expression ?: return null
    val bindings = linkedMapOf<String, Any>()
    var nextBinding = 0

    fun bind(
        field: String,
        values: List<Any>,
    ): String {
        val name = "search_filter_${nextBinding++}"
        bindings[name] = values
        return "$field INSIDE $$name"
    }

    fun compile(node: SearchFilterExpression<ResolvedAuthoringSearchFilter>): String? =
        when (node) {
            is SearchFilterExpression.Value -> {
                val filter = node.filter
                when (filter.kind) {
                    AuthoringSelectorKind.BOOK -> {
                        fields.book?.let { bind(it, filter.records.toList()) }
                    }

                    AuthoringSelectorKind.PAGE -> {
                        fields.page?.let { bind(it, filter.records.toList()) }
                    }

                    AuthoringSelectorKind.TAG -> {
                        when {
                            fields.tag != null -> bind(fields.tag, filter.records.toList())
                            fields.book != null -> bind(fields.book, filter.taggedBooks.toList())
                            else -> null
                        }
                    }

                    AuthoringSelectorKind.ELEMENT_TYPE -> {
                        fields.elementType?.let { field ->
                            bind(field, filter.elementTypes.map { it.value.toString() })
                        }
                    }
                }
            }

            is SearchFilterExpression.And -> {
                combineSql(compile(node.left), "AND", compile(node.right))
            }

            is SearchFilterExpression.Or -> {
                combineSql(compile(node.left), "OR", compile(node.right))
            }

            is SearchFilterExpression.Not -> {
                compile(node.expression)?.let { "NOT ($it)" }
            }
        }

    val condition = compile(expression) ?: return null
    return SearchSqlFilter(condition, bindings)
}

private fun combineSql(
    left: String?,
    operator: String,
    right: String?,
): String? =
    when {
        left == null -> right
        right == null -> left
        else -> "($left $operator $right)"
    }

private fun ResolvedSearchScope.addSqlFilter(
    conditions: MutableList<String>,
    bindings: MutableMap<String, Any>,
    fields: SearchResourceFields,
) {
    sqlFilter(fields)?.let { filter ->
        conditions += filter.condition
        bindings += filter.bindings
    }
    reference?.allowedBook?.let { book ->
        fields.book?.let { field ->
            conditions += "$field = \$reference_book"
            bindings["reference_book"] = book
        }
    }
    if (reference?.allowedElementTypes?.isNotEmpty() == true) {
        fields.elementType?.let { field ->
            conditions += "$field INSIDE \$reference_element_types"
            bindings["reference_element_types"] = reference.allowedElementTypes.map { it.value.toString() }
        }
    }
    if (reference?.allowedPageKinds?.isNotEmpty() == true) {
        fields.pageKind?.let { field ->
            conditions += "$field INSIDE \$reference_page_kinds"
            bindings["reference_page_kinds"] =
                reference.allowedPageKinds.map { mapOf("id" to it.id.value.toString(), "revision" to it.revision) }
        }
    }
}

private fun Surreal.searchDefaults(
    scope: ResolvedSearchScope,
    limit: Int,
): List<AuthoringSearchHit> {
    val eligible = listOf(AuthoringResultKind.BOOK, AuthoringResultKind.PAGE, AuthoringResultKind.ELEMENT).filter(scope::allows)
    if (eligible.isEmpty()) return emptyList()
    val perKind = (limit + eligible.size - 1) / eligible.size
    return buildList {
        if (AuthoringResultKind.BOOK in eligible) addAll(searchDefaultBooks(scope, perKind))
        if (AuthoringResultKind.PAGE in eligible) addAll(searchDefaultPages(scope, perKind))
        if (AuthoringResultKind.ELEMENT in eligible) addAll(searchDefaultElements(scope, perKind))
    }.take(limit)
}

private fun Surreal.searchDefaultBooks(
    scope: ResolvedSearchScope,
    limit: Int,
): List<AuthoringSearchHit> {
    val conditions = mutableListOf<String>()
    val bindings = mutableMapOf<String, Any>("limit" to limit)
    scope.addSqlFilter(conditions, bindings, SearchResourceFields(book = "id"))
    val where = conditions.takeIf(List<String>::isNotEmpty)?.joinToString(" AND ", prefix = " WHERE ").orEmpty()
    return query(
        "SELECT id, title, icon, color FROM book$where ORDER BY title LIMIT \$limit;",
        bindings,
    ).take(0)
        .array
        .map { row ->
            val value = row.getObject()
            AuthoringSearchHit.Book(
                id = value.get("id").recordId.toBookId(),
                title = value.get("title").string,
                icon = Icon.parse(value.get("icon").string),
                color = Color(value.get("color").long.toUInt()),
                tagIds = emptyList(),
            )
        }
}

private fun Surreal.searchDefaultPages(
    scope: ResolvedSearchScope,
    limit: Int,
): List<AuthoringSearchHit> {
    val conditions = mutableListOf<String>()
    val bindings = mutableMapOf<String, Any>("limit" to limit)
    scope.addSqlFilter(conditions, bindings, SearchResourceFields(book = "book", page = "id", pageKind = "kind"))
    val where = conditions.takeIf(List<String>::isNotEmpty)?.joinToString(" AND ", prefix = " WHERE ").orEmpty()
    return query(
        "SELECT id, name, book, book.title AS book_title, chapter, kind, priority FROM page$where " +
            "ORDER BY priority DESC, name LIMIT \$limit;",
        bindings,
    ).take(0).array.map { row ->
        val value = row.getObject()
        AuthoringSearchHit.Page(
            id = value.get("id").recordId.toPageId(),
            title = value.get("name").string,
            book = value.get("book").recordId.toBookId(),
            bookTitle = value.get("book_title").string,
            chapter = ChapterPath.parse(value.get("chapter").string),
            kind = value.pageKind(),
        )
    }
}

private fun Surreal.searchDefaultElements(
    scope: ResolvedSearchScope,
    limit: Int,
): List<AuthoringSearchHit> =
    searchElementRows("true", "", scope, limit, "0 AS score").map { value ->
        val type = value.elementType()
        AuthoringSearchHit.Element(
            id = value.get("id").recordId.toElementInstanceId(),
            title = value.get("name").string,
            elementType = type,
            page = value.get("page").recordId.toPageId(),
            pageTitle = value.get("page_name").string,
            book = value.get("book").recordId.toBookId(),
            bookTitle = value.get("book_title").string,
            chapter = ChapterPath.parse(value.get("chapter").string),
            kind = value.pageKind("page_kind"),
            placement = value.get("placement").elementPlacement(),
        )
    }

private fun exactElement(
    batch: AuthoringSearchQueryBatch,
    queryText: String,
    scope: ResolvedSearchScope,
): PendingSearchResult<List<AuthoringSearchCandidate>> {
    val id = RecordId("element", queryText.identityKey("element"))
    val conditions = mutableListOf($$"id = $id")
    val bindings = mutableMapOf<String, Any>("id" to id)
    scope.addSqlFilter(
        conditions,
        bindings,
        SearchResourceFields(
            book = "page.book",
            page = "page",
            elementType = "element_type",
            pageKind = "page.kind",
        ),
    )
    return batch.enqueue(
        "SELECT id, $ELEMENT_NAME_VALUE AS name, page, page.name AS page_name, page.book AS book, " +
            "page.book.title AS book_title, " +
            "page.chapter AS chapter, page.kind AS page_kind, element_type, placement " +
            "FROM element WHERE ${conditions.joinToString(" AND ")} LIMIT 1;",
        bindings,
    ) { result ->
        val value = result.firstObjectOrNull() ?: return@enqueue emptyList()
        listOf(
            candidate(
                hit =
                    AuthoringSearchHit.Element(
                        id = value.get("id").recordId.toElementInstanceId(),
                        title = value.get("name").string,
                        elementType = value.elementType(),
                        page = value.get("page").recordId.toPageId(),
                        pageTitle = value.get("page_name").string,
                        book = value.get("book").recordId.toBookId(),
                        bookTitle = value.get("book_title").string,
                        chapter = ChapterPath.parse(value.get("chapter").string),
                        kind = value.pageKind("page_kind"),
                        placement = value.get("placement").elementPlacement(),
                    ),
                term = queryText,
                kind = AuthoringMatchKind.IDENTITY,
                score = EXACT_ID_SCORE,
            ),
        )
    }
}

private fun exactIdentity(
    batch: AuthoringSearchQueryBatch,
    queryText: String,
    scope: ResolvedSearchScope,
): PendingSearchResult<List<AuthoringSearchCandidate>>? =
    when (queryText.substringBefore(':').lowercase()) {
        "book" -> if (scope.allows(AuthoringResultKind.BOOK)) exactBook(batch, queryText, scope) else null
        "page" -> if (scope.allows(AuthoringResultKind.PAGE)) exactPage(batch, queryText, scope) else null
        "tag" -> if (scope.allows(AuthoringResultKind.TAG)) exactTag(batch, queryText, scope) else null
        "element" -> if (scope.allows(AuthoringResultKind.ELEMENT)) exactElement(batch, queryText, scope) else null
        else -> null
    }

private fun exactBook(
    batch: AuthoringSearchQueryBatch,
    queryText: String,
    scope: ResolvedSearchScope,
): PendingSearchResult<List<AuthoringSearchCandidate>> {
    val id = RecordId("book", queryText.identityKey("book"))
    val conditions = mutableListOf($$"id = $id")
    val bindings = mutableMapOf<String, Any>("id" to id)
    scope.addSqlFilter(conditions, bindings, SearchResourceFields(book = "id"))
    return batch.enqueue(
        "SELECT id, title, icon, color FROM book WHERE ${conditions.joinToString(" AND ")} LIMIT 1;",
        bindings,
    ) { result ->
        val value = result.firstObjectOrNull() ?: return@enqueue emptyList()
        listOf(
            candidate(
                hit =
                    AuthoringSearchHit.Book(
                        id = value.get("id").recordId.toBookId(),
                        title = value.get("title").string,
                        icon = Icon.parse(value.get("icon").string),
                        color = Color(value.get("color").long.toUInt()),
                        tagIds = emptyList(),
                    ),
                term = queryText,
                kind = AuthoringMatchKind.IDENTITY,
                score = EXACT_ID_SCORE,
            ),
        )
    }
}

private fun exactPage(
    batch: AuthoringSearchQueryBatch,
    queryText: String,
    scope: ResolvedSearchScope,
): PendingSearchResult<List<AuthoringSearchCandidate>> {
    val id = RecordId("page", queryText.identityKey("page"))
    val conditions = mutableListOf($$"id = $id")
    val bindings = mutableMapOf<String, Any>("id" to id)
    scope.addSqlFilter(conditions, bindings, SearchResourceFields(book = "book", page = "id", pageKind = "kind"))
    return batch.enqueue(
        "SELECT id, name, book, book.title AS book_title, chapter, kind FROM page " +
            "WHERE ${conditions.joinToString(" AND ")} LIMIT 1;",
        bindings,
    ) { result ->
        val value = result.firstObjectOrNull() ?: return@enqueue emptyList()
        listOf(
            candidate(
                hit =
                    AuthoringSearchHit.Page(
                        id = value.get("id").recordId.toPageId(),
                        title = value.get("name").string,
                        book = value.get("book").recordId.toBookId(),
                        bookTitle = value.get("book_title").string,
                        chapter = ChapterPath.parse(value.get("chapter").string),
                        kind = value.pageKind(),
                    ),
                term = queryText,
                kind = AuthoringMatchKind.IDENTITY,
                score = EXACT_ID_SCORE,
            ),
        )
    }
}

private fun exactTag(
    batch: AuthoringSearchQueryBatch,
    queryText: String,
    scope: ResolvedSearchScope,
): PendingSearchResult<List<AuthoringSearchCandidate>> {
    val id = RecordId("tag", queryText.identityKey("tag"))
    val conditions = mutableListOf($$"id = $id")
    val bindings = mutableMapOf<String, Any>("id" to id)
    scope.addSqlFilter(conditions, bindings, SearchResourceFields(tag = "id"))
    return batch.enqueue(
        "SELECT id, name, color FROM tag WHERE ${conditions.joinToString(" AND ")} LIMIT 1;",
        bindings,
    ) { result ->
        val value = result.firstObjectOrNull() ?: return@enqueue emptyList()
        listOf(
            candidate(
                hit =
                    AuthoringSearchHit.Tag(
                        id = value.get("id").recordId.toTagId(),
                        title = value.get("name").string,
                        color = Color(value.get("color").long.toUInt()),
                    ),
                term = queryText,
                kind = AuthoringMatchKind.IDENTITY,
                score = EXACT_ID_SCORE,
            ),
        )
    }
}

private fun searchBookNames(
    batch: AuthoringSearchQueryBatch,
    queryText: String,
    scope: ResolvedSearchScope,
    limit: Int,
    lane: NameSearchLane = NameSearchLane.LEXICAL,
): PendingSearchResult<List<AuthoringSearchCandidate>> {
    val bindings = mutableMapOf<String, Any>("query" to queryText, "limit" to limit)
    val conditions = mutableListOf(lane.condition("title", queryText, bindings))
    scope.addSqlFilter(conditions, bindings, SearchResourceFields(book = "id"))
    return batch.enqueue(
        "SELECT id, title, icon, color, ${lane.scoreProjection("title")} " +
            "FROM book WITH INDEX book_title_${lane.indexSuffix} " +
            $$"WHERE $${conditions.joinToString(
                " AND ",
            )} ORDER BY lexical_score DESC, prefix_score DESC, approximate_score DESC LIMIT $limit;",
        bindings,
    ) { result ->
        result.array.map { row ->
            val value = row.getObject()
            candidate(
                hit =
                    AuthoringSearchHit.Book(
                        id = value.get("id").recordId.toBookId(),
                        title = value.get("title").string,
                        icon = Icon.parse(value.get("icon").string),
                        color = Color(value.get("color").long.toUInt()),
                        tagIds = emptyList(),
                    ),
                term = queryText,
                kind = value.nameMatchKind("title", queryText, lane),
                score = value.nameScore("title", queryText, "book"),
            )
        }
    }
}

private fun searchPageNames(
    batch: AuthoringSearchQueryBatch,
    queryText: String,
    scope: ResolvedSearchScope,
    limit: Int,
    lane: NameSearchLane = NameSearchLane.LEXICAL,
): PendingSearchResult<List<AuthoringSearchCandidate>> {
    val bindings = mutableMapOf<String, Any>("query" to queryText, "limit" to limit)
    val conditions = mutableListOf(lane.condition("name", queryText, bindings))
    scope.addSqlFilter(conditions, bindings, SearchResourceFields(book = "book", page = "id", pageKind = "kind"))
    return batch.enqueue(
        "SELECT id, name, book, book.title AS book_title, chapter, kind, ${lane.scoreProjection("name")} " +
            "FROM page WITH INDEX page_name_${lane.indexSuffix} " +
            $$"WHERE $${conditions.joinToString(
                " AND ",
            )} ORDER BY lexical_score DESC, prefix_score DESC, approximate_score DESC LIMIT $limit;",
        bindings,
    ) { result ->
        result.array.map { row ->
            val value = row.getObject()
            candidate(
                hit =
                    AuthoringSearchHit.Page(
                        id = value.get("id").recordId.toPageId(),
                        title = value.get("name").string,
                        book = value.get("book").recordId.toBookId(),
                        bookTitle = value.get("book_title").string,
                        chapter = ChapterPath.parse(value.get("chapter").string),
                        kind = value.pageKind(),
                    ),
                term = queryText,
                kind = value.nameMatchKind("name", queryText, lane),
                score = value.nameScore("name", queryText, "page"),
            )
        }
    }
}

private fun searchTagNames(
    batch: AuthoringSearchQueryBatch,
    queryText: String,
    scope: ResolvedSearchScope,
    limit: Int,
    lane: NameSearchLane = NameSearchLane.LEXICAL,
): PendingSearchResult<List<AuthoringSearchCandidate>> {
    val bindings = mutableMapOf<String, Any>("query" to queryText, "limit" to limit)
    val conditions = mutableListOf(lane.condition("name", queryText, bindings))
    scope.addSqlFilter(conditions, bindings, SearchResourceFields(tag = "id"))
    return batch.enqueue(
        "SELECT id, name, color, ${lane.scoreProjection("name")} FROM tag WITH INDEX tag_name_${lane.indexSuffix} " +
            $$"WHERE $${conditions.joinToString(
                " AND ",
            )} ORDER BY lexical_score DESC, prefix_score DESC, approximate_score DESC LIMIT $limit;",
        bindings,
    ) { result ->
        result.array.map { row ->
            val value = row.getObject()
            candidate(
                hit =
                    AuthoringSearchHit.Tag(
                        id = value.get("id").recordId.toTagId(),
                        title = value.get("name").string,
                        color = Color(value.get("color").long.toUInt()),
                    ),
                term = queryText,
                kind = value.nameMatchKind("name", queryText, lane),
                score = value.nameScore("name", queryText, "tag"),
            )
        }
    }
}

private fun searchElementNames(
    batch: AuthoringSearchQueryBatch,
    queryText: String,
    scope: ResolvedSearchScope,
    limit: Int,
    lane: NameSearchLane = NameSearchLane.LEXICAL,
): PendingSearchResult<List<AuthoringSearchCandidate>> {
    val bindings = mutableMapOf<String, Any>("query" to queryText)
    val conditions = mutableListOf(lane.condition(ELEMENT_NAME_FIELD, queryText, bindings))
    bindings["limit"] = limit
    scope.addSqlFilter(
        conditions,
        bindings,
        SearchResourceFields(
            book = "page.book",
            page = "page",
            elementType = "element_type",
            pageKind = "page.kind",
        ),
    )
    return batch.enqueue(
        "SELECT id, $ELEMENT_NAME_VALUE AS name, page, page.book AS book, page.name AS page_name, " +
            "page.book.title AS book_title, " +
            "page.chapter AS chapter, page.kind AS page_kind, element_type, placement, " +
            "${lane.scoreProjection(ELEMENT_NAME_VALUE)}, ${lane.rawScore(ELEMENT_NAME_VALUE)} AS score " +
            "FROM element WITH INDEX element_name_${lane.indexSuffix} " +
            "WHERE ${conditions.joinToString(" AND ")} ORDER BY score DESC LIMIT \$limit;",
        bindings,
    ) { result ->
        result.array.map { row ->
            val value = row.getObject()
            val type = value.elementType()
            candidate(
                hit =
                    AuthoringSearchHit.Element(
                        id = value.get("id").recordId.toElementInstanceId(),
                        title = value.get("name").string,
                        elementType = type,
                        page = value.get("page").recordId.toPageId(),
                        pageTitle = value.get("page_name").string,
                        book = value.get("book").recordId.toBookId(),
                        bookTitle = value.get("book_title").string,
                        chapter = ChapterPath.parse(value.get("chapter").string),
                        kind = value.pageKind("page_kind"),
                        placement = value.get("placement").elementPlacement(),
                    ),
                term = queryText,
                kind = value.nameMatchKind("name", queryText, lane),
                score = value.nameScore("name", queryText, "element"),
            )
        }
    }
}

private fun searchElementContent(
    batch: AuthoringSearchQueryBatch,
    textQuery: AuthoringTextQuery,
    scope: ResolvedSearchScope,
    catalog: Map<ElementTypeId, ElementSearchCatalogEntry>,
    limit: Int,
): List<PendingSearchResult<List<AuthoringSearchCandidate>>> =
    textQuery.terms.flatMap { term ->
        buildList {
            add(searchExactElementContent(batch, term, scope, catalog, limit))
            if (term.approximateNgrams().isNotEmpty()) {
                add(searchApproximateElementContent(batch, term, scope, catalog, limit))
            }
        }
    }

private fun searchExactElementContent(
    batch: AuthoringSearchQueryBatch,
    term: String,
    scope: ResolvedSearchScope,
    catalog: Map<ElementTypeId, ElementSearchCatalogEntry>,
    limit: Int,
): PendingSearchResult<List<AuthoringSearchCandidate>> {
    val conditions =
        mutableListOf(
            $$"(search.summary.values @0@ $query OR search.body.values @1@ $query OR search.keyword.values @2@ $query)",
        )
    val bindings =
        mutableMapOf<String, Any>(
            "query" to term,
            "limit" to (limit * CONTENT_CANDIDATE_FACTOR),
        )
    scope.addSqlFilter(
        conditions,
        bindings,
        SearchResourceFields(
            book = "page.book",
            page = "page",
            elementType = "element_type",
            pageKind = "page.kind",
        ),
    )
    return batch.enqueue(
        "SELECT id, $ELEMENT_NAME_VALUE AS name, page, page.book AS book, page.name AS page_name, " +
            "page.book.title AS book_name, " +
            "page.chapter AS chapter, page.kind AS page_kind, element_type, placement, " +
            "search.policy_revision AS policy_revision, " +
            "search.summary.values AS summary_values, search.summary.paths AS summary_paths, " +
            "search.body.values AS body_values, search.body.paths AS body_paths, " +
            "search.keyword.values AS keyword_values, search.keyword.paths AS keyword_paths, " +
            "search::score(0) AS summary_score, search::score(1) AS body_score, " +
            "search::score(2) AS keyword_score, search::offsets(0) AS summary_offsets, " +
            "search::offsets(1) AS body_offsets, search::offsets(2) AS keyword_offsets " +
            "FROM element WITH INDEX element_search_summary, element_search_body, element_search_keyword " +
            $$"WHERE $${conditions.joinToString(" AND ")} LIMIT $limit;",
        bindings,
    ) { result ->
        result.array.flatMap { value ->
            val row = value.getObject()
            val element = row.elementSearchMetadata()
            val type = row.elementType()
            val definition = catalog[type]?.definition ?: return@flatMap emptyList()
            if (row.get("policy_revision").string != elementSearchPolicyRevision(definition)) {
                return@flatMap emptyList()
            }
            buildList {
                addMatches(row, element, type, ElementSearchMode.SUMMARY, SUMMARY_BAND, term = term)
                addMatches(row, element, type, ElementSearchMode.BODY, BODY_BAND, term = term)
                addMatches(row, element, type, ElementSearchMode.KEYWORD, KEYWORD_BAND, term = term)
            }
        }
    }
}

private fun searchApproximateElementContent(
    batch: AuthoringSearchQueryBatch,
    term: String,
    scope: ResolvedSearchScope,
    catalog: Map<ElementTypeId, ElementSearchCatalogEntry>,
    limit: Int,
): PendingSearchResult<List<AuthoringSearchCandidate>> {
    val bindings = mutableMapOf<String, Any>("limit" to (limit * CONTENT_CANDIDATE_FACTOR))
    val conditions = mutableListOf(approximateContentCondition(term, bindings))
    scope.addSqlFilter(
        conditions,
        bindings,
        SearchResourceFields(
            book = "page.book",
            page = "page",
            elementType = "element_type",
            pageKind = "page.kind",
        ),
    )
    return batch.enqueue(
        "SELECT id, $ELEMENT_NAME_VALUE AS name, page, page.book AS book, page.name AS page_name, " +
            "page.book.title AS book_name, " +
            "page.chapter AS chapter, page.kind AS page_kind, element_type, placement, " +
            "search.policy_revision AS policy_revision, " +
            "search.summary.values AS summary_values, search.summary.paths AS summary_paths, " +
            "search.body.values AS body_values, search.body.paths AS body_paths, " +
            "search.keyword.values AS keyword_values, search.keyword.paths AS keyword_paths " +
            "FROM element WITH INDEX element_search_summary_approximate, element_search_body_approximate, " +
            "element_search_keyword_approximate " +
            "WHERE ${conditions.joinToString(" AND ")} LIMIT \$limit;",
        bindings,
    ) { result ->
        result.array.flatMap { value ->
            val row = value.getObject()
            val element = row.elementSearchMetadata()
            val type = row.elementType()
            val definition = catalog[type]?.definition ?: return@flatMap emptyList()
            if (row.get("policy_revision").string != elementSearchPolicyRevision(definition)) {
                return@flatMap emptyList()
            }
            SEARCH_CONTENT_MODES.mapNotNull { mode ->
                row.approximateContentCandidate(element, type, mode, term)
            }
        }
    }
}

private fun approximateContentCondition(
    term: String,
    bindings: MutableMap<String, Any>,
): String {
    val ngrams = term.approximateNgrams()
    require(ngrams.isNotEmpty()) { "Approximate content search requires at least one ngram." }
    var reference = 0
    return SEARCH_CONTENT_MODES
        .flatMap { mode ->
            val field = "search.${mode.name.lowercase()}.values"
            ngrams.mapIndexed { index, ngram ->
                val binding = "approximate_${mode.name.lowercase()}_$index"
                bindings[binding] = ngram
                "$field @${reference++}@ \$$binding"
            }
        }.joinToString(" OR ", prefix = "(", postfix = ")")
}

private fun Surreal.searchElementRows(
    searchCondition: String,
    queryText: String,
    scope: ResolvedSearchScope,
    limit: Int,
    projection: String,
    identity: RecordId? = null,
    indexHint: String? = null,
    additionalBindings: Map<String, Any> = emptyMap(),
): List<com.surrealdb.Object> {
    val conditions = mutableListOf(searchCondition)
    val bindings =
        mutableMapOf<String, Any>("query" to queryText, "limit" to limit).apply {
            putAll(additionalBindings)
        }
    identity?.let { bindings["id"] = it }
    scope.addSqlFilter(
        conditions,
        bindings,
        SearchResourceFields(
            book = "page.book",
            page = "page",
            elementType = "element_type",
            pageKind = "page.kind",
        ),
    )
    return query(
        "SELECT id, $ELEMENT_NAME_VALUE AS name, page, page.book AS book, page.name AS page_name, " +
            "page.book.title AS book_title, " +
            "page.chapter AS chapter, page.kind AS page_kind, element_type, placement, $projection " +
            "FROM element ${indexHint?.let { "WITH INDEX $it " }.orEmpty()}" +
            $$"WHERE $${conditions.joinToString(" AND ")} ORDER BY score DESC LIMIT $limit;",
        bindings,
    ).take(0).array.map(Value::getObject)
}

private data class ElementSearchMetadata(
    val name: String,
    val bookId: BookId,
    val pageId: PageId,
    val pageName: String,
    val bookName: String,
    val chapter: ChapterPath,
    val kind: PageKindRef,
    val placement: ElementPlacement,
)

private fun com.surrealdb.Object.elementSearchMetadata(): ElementSearchMetadata =
    ElementSearchMetadata(
        name = get("name").string,
        bookId = get("book").recordId.toBookId(),
        pageId = get("page").recordId.toPageId(),
        pageName = get("page_name").string,
        bookName = get("book_name").string,
        chapter = ChapterPath.parse(get("chapter").string),
        kind = pageKind("page_kind"),
        placement = get("placement").elementPlacement(),
    )

private fun MutableList<AuthoringSearchCandidate>.addMatches(
    row: com.surrealdb.Object,
    element: ElementSearchMetadata,
    type: ElementTypeId,
    mode: ElementSearchMode,
    band: Double,
    term: String,
) {
    val prefix = mode.name.lowercase()
    val texts = row.get("${prefix}_values").array.map(Value::getString)
    val paths = row.get("${prefix}_paths").array.map(Value::getString)
    val score = relevanceScore(band, row.get("${prefix}_score").number())
    require(texts.size == paths.size) { "Search fragment and path arrays must have equal length." }
    val offsets = row.get("${prefix}_offsets")
    if (!offsets.isObject) return
    offsets.getObject().forEach { offsetEntry ->
        val index = offsetEntry.key.toInt()
        val text = texts[index]
        offsetEntry.value.array.forEach { rangeValue ->
            val range = rangeValue.getObject()
            add(
                candidate(
                    hit =
                        AuthoringSearchHit.Element(
                            id = row.get("id").recordId.toElementInstanceId(),
                            title = element.name,
                            elementType = type,
                            page = element.pageId,
                            pageTitle = element.pageName,
                            book = element.bookId,
                            bookTitle = element.bookName,
                            chapter = element.chapter,
                            kind = element.kind,
                            placement = element.placement,
                            match =
                                AuthoringSearchMatch(
                                    text = text,
                                    start = range.get("s").long.toInt(),
                                    end = range.get("e").long.toInt(),
                                ),
                        ),
                    term = term,
                    kind = AuthoringMatchKind.EXACT_CONTENT,
                    score = score,
                ),
            )
        }
    }
}

private fun com.surrealdb.Object.approximateContentCandidate(
    element: ElementSearchMetadata,
    type: ElementTypeId,
    mode: ElementSearchMode,
    term: String,
): AuthoringSearchCandidate? {
    val prefix = mode.name.lowercase()
    val texts = get("${prefix}_values").array.map(Value::getString)
    val paths = get("${prefix}_paths").array.map(Value::getString)
    require(texts.size == paths.size) { "Search fragment and path arrays must have equal length." }
    val match =
        texts.mapNotNull { it.bestApproximateMatch(term) }.maxByOrNull(ApproximateTextMatch::similarity)
            ?: return null
    if (match.similarity < FUZZY_THRESHOLD) return null
    return candidate(
        hit =
            AuthoringSearchHit.Element(
                id = get("id").recordId.toElementInstanceId(),
                title = element.name,
                elementType = type,
                page = element.pageId,
                pageTitle = element.pageName,
                book = element.bookId,
                bookTitle = element.bookName,
                chapter = element.chapter,
                kind = element.kind,
                placement = element.placement,
                match = AuthoringSearchMatch(match.text, match.start, match.end),
            ),
        term = term,
        kind = AuthoringMatchKind.APPROXIMATE_CONTENT,
        score = relevanceScore(FUZZY_BAND, match.similarity),
    )
}

private data class ApproximateTextMatch(
    val text: String,
    val start: Int,
    val end: Int,
    val similarity: Double,
)

private fun String.bestApproximateMatch(term: String): ApproximateTextMatch? =
    SEARCH_WORD
        .findAll(this)
        .map { match ->
            ApproximateTextMatch(
                text = this,
                start = match.range.first,
                end = match.range.last + 1,
                similarity = jaroWinkler(match.value.lowercase(), term),
            )
        }.maxByOrNull(ApproximateTextMatch::similarity)

private fun jaroWinkler(
    left: String,
    right: String,
): Double {
    if (left == right) return 1.0
    if (left.isEmpty() || right.isEmpty()) return 0.0
    val distance = (maxOf(left.length, right.length) / 2 - 1).coerceAtLeast(0)
    val leftMatches = BooleanArray(left.length)
    val rightMatches = BooleanArray(right.length)
    var matches = 0
    left.indices.forEach { leftIndex ->
        val start = (leftIndex - distance).coerceAtLeast(0)
        val end = (leftIndex + distance + 1).coerceAtMost(right.length)
        for (rightIndex in start until end) {
            if (rightMatches[rightIndex] || left[leftIndex] != right[rightIndex]) continue
            leftMatches[leftIndex] = true
            rightMatches[rightIndex] = true
            matches++
            break
        }
    }
    if (matches == 0) return 0.0
    val leftCharacters = left.indices.filter(leftMatches::get).map(left::get)
    val rightCharacters = right.indices.filter(rightMatches::get).map(right::get)
    val transpositions = leftCharacters.zip(rightCharacters).count { (a, b) -> a != b } / 2.0
    val jaro =
        (
            matches.toDouble() / left.length +
                matches.toDouble() / right.length +
                (matches - transpositions) / matches
        ) / 3.0
    val prefix =
        left
            .zip(right)
            .takeWhile { (a, b) -> a == b }
            .take(MAX_JARO_WINKLER_PREFIX)
            .size
    return jaro + prefix * JARO_WINKLER_SCALING * (1.0 - jaro)
}

private fun Surreal.resolveBookTags(hits: List<AuthoringSearchHit>): List<AuthoringSearchHit> {
    val bookIds = hits.filterIsInstance<AuthoringSearchHit.Book>().map { it.id.surrealId() }
    if (bookIds.isEmpty()) return hits
    val tagsByBook =
        query(
            "SELECT source, target FROM resource_reference " +
                "WHERE source INSIDE \$books AND string::starts_with(slot, 'tags:');",
            mapOf("books" to bookIds),
        ).take(0)
            .array
            .map(Value::getObject)
            .groupBy(
                { it.get("source").recordId.toBookId() },
                { it.get("target").recordId.toTagId() },
            )
    val tagIds = tagsByBook.values.flatten().distinct()
    if (tagIds.isEmpty()) return hits
    val tags =
        query(
            "SELECT id, name, color FROM tag WHERE id INSIDE \$ids;",
            mapOf("ids" to tagIds.map(TagId::surrealId)),
        ).take(0).array.associate { row ->
            val value = row.getObject()
            val id = value.get("id").recordId.toTagId()
            id to
                AuthoringSearchTag(
                    id = id,
                    name = value.get("name").string,
                    color = Color(value.get("color").long.toUInt()),
                )
        }
    return hits.map { hit ->
        if (hit is AuthoringSearchHit.Book) {
            val ids = tagsByBook[hit.id].orEmpty()
            hit.copy(tagIds = ids, tags = ids.mapNotNull(tags::get))
        } else {
            hit
        }
    }
}

private fun com.surrealdb.Object.pageKind(field: String = "kind"): PageKindRef {
    val value = get(field).getObject()
    return pageKindRef(value.get("id").string, value.get("revision").long.toInt())
}

private fun com.surrealdb.Object.elementType(): ElementTypeId =
    ElementTypeId(
        com.typewritermc.types.DeclaredTypeId
            .parse(get("element_type").string),
    )

private fun Value.optionalString(): String? = if (isNone || isNull) null else string

private fun Value.firstObjectOrNull(): com.surrealdb.Object? {
    val values = array
    if (values.len() == 0) return null
    return values.first().getObject()
}

private fun Value.number(): Double =
    when {
        isDouble -> double
        isLong -> long.toDouble()
        else -> 0.0
    }

private fun relevanceScore(
    band: Double,
    rawScore: Double,
): Double = band + rawScore.coerceIn(0.0, MAX_SCORE_INSIDE_BAND)

private enum class NameSearchLane(
    val indexSuffix: String,
    val matchKind: AuthoringMatchKind,
) {
    LEXICAL(
        "search",
        AuthoringMatchKind.LEXICAL_NAME,
    ),
    PREFIX(
        "prefix",
        AuthoringMatchKind.PREFIX_NAME,
    ),
    APPROXIMATE(
        "approximate",
        AuthoringMatchKind.APPROXIMATE_NAME,
    ),

    ;

    fun condition(
        field: String,
        query: String,
        bindings: MutableMap<String, Any>,
    ): String =
        when (this) {
            LEXICAL,
            PREFIX,
            -> {
                "$field @0@ \$query"
            }

            APPROXIMATE -> {
                val ngrams = query.approximateNgrams()
                if (ngrams.isEmpty()) return "false"
                ngrams
                    .mapIndexed { index, ngram ->
                        val binding = "approximate_$index"
                        bindings[binding] = ngram
                        "$field @$index@ \$$binding"
                    }.joinToString(" OR ", prefix = "(", postfix = ")")
            }
        }

    fun scoreProjection(field: String): String =
        when (this) {
            LEXICAL -> {
                "${rawScore(field)} AS lexical_score, 0 AS prefix_score, 0 AS approximate_score"
            }

            PREFIX -> {
                "0 AS lexical_score, ${rawScore(field)} AS prefix_score, 0 AS approximate_score"
            }

            APPROXIMATE -> {
                "0 AS lexical_score, 0 AS prefix_score, ${rawScore(field)} AS approximate_score"
            }
        }

    fun rawScore(field: String): String =
        when (this) {
            LEXICAL,
            PREFIX,
            -> "search::score(0)"

            APPROXIMATE -> "string::similarity::jaro_winkler(string::lowercase($field), \$query)"
        }
}

private fun com.surrealdb.Object.nameMatchKind(
    field: String,
    query: String,
    lane: NameSearchLane,
): AuthoringMatchKind =
    if (get(field).string.equals(query, ignoreCase = true)) {
        AuthoringMatchKind.EXACT_NAME
    } else {
        lane.matchKind
    }

private fun com.surrealdb.Object.nameScore(
    field: String,
    query: String,
    table: String,
): Double {
    val id = get("id").recordId
    val name = get(field).string
    val lexical = get("lexical_score").number()
    val prefix = get("prefix_score").number()
    val approximate = get("approximate_score").number()
    return when {
        id == RecordId(table, query.identityKey(table)) -> EXACT_ID_SCORE
        name.equals(query, ignoreCase = true) -> EXACT_NAME_SCORE
        prefix > 0.0 -> relevanceScore(PREFIX_BAND, prefix)
        lexical > 0.0 -> relevanceScore(NAME_BAND, lexical)
        else -> relevanceScore(FUZZY_BAND, approximate)
    }
}

private fun String.approximateNgrams(): List<String> {
    val codePoints = codePoints().toArray()
    if (codePoints.size < MIN_APPROXIMATE_NGRAM) return emptyList()
    return buildList {
        for (size in MIN_APPROXIMATE_NGRAM..minOf(MAX_APPROXIMATE_NGRAM, codePoints.size)) {
            for (start in 0..codePoints.size - size) {
                add(String(codePoints, start, size))
            }
        }
    }.distinct().take(MAX_APPROXIMATE_QUERY_NGRAMS)
}

private fun RecordId.selectorText(): String = if (id.isString) id.string else toString()

private fun String.identityKey(table: String): String = removePrefix("$table:")

private data class AuthoringTextQuery(
    val terms: Set<String>,
)

private fun candidate(
    hit: AuthoringSearchHit,
    term: String?,
    kind: AuthoringMatchKind,
    score: Double,
): AuthoringSearchCandidate =
    AuthoringSearchCandidate(
        hit = hit,
        evidence = AuthoringMatchEvidence(term = term, kind = kind, score = score),
    )

internal const val DEFAULT_SEARCH_LIMIT = 12
private const val SELECTOR_SUGGESTION_LIMIT = 20
private const val ELEMENT_NAME_FIELD = "search.name.values"
private const val ELEMENT_NAME_VALUE = "search.name.values[0]"
private const val CONTENT_CANDIDATE_FACTOR = 4
private const val MAX_QUERY_TERMS = 12
private const val MIN_APPROXIMATE_NGRAM = 2
private const val MAX_APPROXIMATE_NGRAM = 4
private const val MAX_APPROXIMATE_QUERY_NGRAMS = 24
private val SEARCH_CONTENT_MODES =
    listOf(ElementSearchMode.SUMMARY, ElementSearchMode.BODY, ElementSearchMode.KEYWORD)
private val SEARCH_WORD = Regex("[\\p{L}\\p{N}_]+")
private val PAGE_TYPE =
    ResolvedTypeRef(
        com.typewritermc.types.TypeId
            .Qualified("com.typewritermc.library", "Page"),
        revision = 1,
    )
private const val MAX_JARO_WINKLER_PREFIX = 4
private const val JARO_WINKLER_SCALING = 0.1
private const val FUZZY_THRESHOLD = 0.84
private const val EXACT_ID_SCORE = 7_000.0
private const val EXACT_NAME_SCORE = 6_900.0
private const val PREFIX_BAND = 6_000.0
private const val NAME_BAND = 5_000.0
private const val SUMMARY_BAND = 4_000.0
private const val KEYWORD_BAND = 3_000.0
private const val BODY_BAND = 2_000.0
private const val FUZZY_BAND = 1_000.0
private const val MAX_SCORE_INSIDE_BAND = 0.8
