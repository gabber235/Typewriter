package com.typewritermc.realm.repository.search

import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ElementValuePath
import com.typewritermc.elements.StoredElement
import com.typewritermc.elements.elementName
import com.typewritermc.realm.repository.records.ElementRecordParser
import com.typewritermc.realm.repository.records.StoredPageElements
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.realm.repository.utils.toElementInstanceId
import com.typewritermc.types.TypeCatalog
import kotlinx.serialization.json.Json

/**
 * Owns element search projections and keeps their lifecycle inside canonical Surreal transactions.
 *
 * Mutation writes use the caller transaction. Reconciliation processes stable element id pages and uses the same
 * projector, making bootstrap and live updates converge on identical embedded values.
 */
internal class SurrealAuthoringSearchRepository(
    private val database: Surreal,
    private val catalog: () -> Map<ElementTypeId, ElementSearchCatalogEntry>,
    private val typeCatalog: () -> TypeCatalog = {
        TypeCatalog(catalog().values.flatMap { it.graph.definitions }.distinctBy { it.id })
    },
    private val projector: ElementSearchProjector = ElementSearchProjector(),
) : AuthoringSearchRepository {
    override fun search(request: AuthoringSearchRequest): AuthoringSearchResult =
        database.searchAuthoring(request, catalog(), typeCatalog())

    override fun suggest(request: AuthoringSelectorSuggestionRequest): AuthoringSelectorSuggestions =
        database.suggestAuthoring(request, catalog())

    override fun resolve(request: AuthoringReferenceResolutionRequest): List<AuthoringReferenceSummary> =
        database.resolveAuthoringReferences(request, catalog(), typeCatalog())

    internal fun update(
        transaction: Transaction,
        dirty: Set<ElementInstanceId>,
    ) {
        val elements = transaction.loadSearchElements(dirty).elements.associateBy(StoredElement::id)
        dirty.forEach { id ->
            val element = elements[id] ?: return@forEach
            when (val result = projector.project(element, catalog()[element.elementType])) {
                is ElementSearchProjectionResult.Projected -> transaction.replaceSearch(result.projection)
                is ElementSearchProjectionResult.Unavailable -> transaction.replaceUnavailableSearch(element)
            }
        }
    }

    /**
     * Rebuilds embedded search projections in bounded id ordered transactions.
     *
     * Every batch rereads the current catalog. Live mutations already update the canonical element records, so
     * reconciliation can run alongside authoring without opening a second persistence boundary.
     */
    fun reconcile(batchSize: Int = DEFAULT_RECONCILE_BATCH_SIZE): AuthoringSearchReconciliation {
        require(batchSize > 0) { "Search reconciliation batch size must be positive." }
        var after: ElementInstanceId? = null
        var projected = 0
        var unavailable = 0
        do {
            val result =
                database.inTransaction { transaction ->
                    val elements = transaction.loadSearchElementBatch(after, batchSize)
                    val currentCatalog = catalog()
                    elements.forEach { element ->
                        when (val projection = projector.project(element, currentCatalog[element.elementType])) {
                            is ElementSearchProjectionResult.Projected -> {
                                transaction.replaceSearch(projection.projection)
                                projected++
                            }

                            is ElementSearchProjectionResult.Unavailable -> {
                                transaction.replaceUnavailableSearch(element)
                                unavailable++
                            }
                        }
                    }
                    elements.lastOrNull()?.id to elements.size
                }
            after = result.first
        } while (result.second == batchSize)
        return AuthoringSearchReconciliation(projected, unavailable)
    }
}

data class AuthoringSearchReconciliation(
    val projected: Int,
    val unavailable: Int,
)

internal fun encodeSearchPath(path: ElementValuePath): String = searchJson.encodeToString(ElementValuePath.serializer(), path)

internal fun decodeSearchPath(value: String): ElementValuePath = searchJson.decodeFromString(ElementValuePath.serializer(), value)

private fun Transaction.replaceSearch(projection: ElementSearchProjection) {
    query(
        $$"UPDATE ONLY $element SET search = $search;",
        mapOf(
            "element" to projection.element.id.surrealId(),
            "search" to
                mapOf(
                    "name" to mapOf("values" to listOf(projection.name)),
                    "policy_revision" to projection.policyRevision,
                    "summary" to projection.summary.databaseValue(),
                    "body" to projection.body.databaseValue(),
                    "keyword" to projection.keyword.databaseValue(),
                ),
        ),
    ).take(0)
}

private fun List<SearchFragment>.databaseValue(): Map<String, List<String>> =
    mapOf(
        "values" to map(SearchFragment::text),
        "paths" to map { encodeSearchPath(it.path) },
    )

private fun Transaction.replaceUnavailableSearch(element: StoredElement) {
    query(
        $$"UPDATE ONLY $element SET search = $search;",
        mapOf(
            "element" to element.id.surrealId(),
            "search" to
                mapOf(
                    "name" to mapOf("values" to listOf(element.value.valueWithSlots.elementName())),
                    "policy_revision" to "unavailable",
                    "summary" to emptyList<SearchFragment>().databaseValue(),
                    "body" to emptyList<SearchFragment>().databaseValue(),
                    "keyword" to emptyList<SearchFragment>().databaseValue(),
                ),
        ),
    ).take(0)
}

private fun Transaction.loadSearchElements(ids: Collection<ElementInstanceId>): StoredPageElements {
    if (ids.isEmpty()) return StoredPageElements(emptyList(), emptyMap())
    val result =
        query(
            $$"""
                LET $elements = SELECT * FROM element WHERE id INSIDE $ids ORDER BY id;
                LET $references = SELECT * FROM resource_reference WHERE source INSIDE $ids ORDER BY source, slot;
                RETURN { elements: $elements, references: $references };
            """.trimIndent(),
            mapOf("ids" to ids.map(ElementInstanceId::surrealId)),
        ).takeTransaction(2)
            .getObject()
    return ElementRecordParser.parse(result.get("elements"), result.get("references"))
}

private fun Transaction.loadSearchElementBatch(
    after: ElementInstanceId?,
    limit: Int,
): List<StoredElement> {
    val ids =
        if (after == null) {
            query($$"SELECT VALUE id FROM element ORDER BY id LIMIT $limit;", mapOf("limit" to limit)).take(0)
        } else {
            query(
                $$"SELECT VALUE id FROM element WHERE id > $after ORDER BY id LIMIT $limit;",
                mapOf("after" to after.surrealId(), "limit" to limit),
            ).take(0)
        }.array
            .map { it.recordId.toElementInstanceId() }
    return loadSearchElements(ids).elements
}

private const val DEFAULT_RECONCILE_BATCH_SIZE = 250
private val searchJson = Json { encodeDefaults = true }
