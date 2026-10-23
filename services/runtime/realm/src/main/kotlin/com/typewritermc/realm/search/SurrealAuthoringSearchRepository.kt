package com.typewritermc.realm.search

import com.surrealdb.Surreal
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.use
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.realm.catalog.ownershipRelationIds
import com.typewritermc.realm.storage.decodeSkir
import com.typewritermc.realm.storage.inPreviewTransaction
import com.typewritermc.realm.storage.surrealRecordId
import com.typewritermc.realm.storage.toResourceId
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.requireValid
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection

internal data class IndexedAuthoringSearchCandidate(
    val resource: ResourceId,
    val record: AuthoringRecord,
    val text: String,
)

internal interface AuthoringSearchRepository {
    fun search(
        view: AuthoringView,
        query: String,
        contexts: Set<ResourceId>,
        roots: Set<TypeDefinitionId>,
        target: NamedTypeUse?,
        limit: Int,
    ): List<IndexedAuthoringSearchCandidate>
}

/**
 * Searches the stored text projection while the caller holds the current authoring view lock.
 *
 * Text ranking and ownership context narrow database candidates; catalog type matching then selects results
 * within a consistent preview transaction and leaves out the catalog's realm root. Holding the view lock keeps repository writes from advancing saved
 * state while candidate rows are matched to the supplied catalog and resource graph.
 */
internal class SurrealAuthoringSearchRepository(
    private val database: Surreal,
) : AuthoringSearchRepository {
    override fun search(
        view: AuthoringView,
        query: String,
        contexts: Set<ResourceId>,
        roots: Set<TypeDefinitionId>,
        target: NamedTypeUse?,
        limit: Int,
    ): List<IndexedAuthoringSearchCandidate> {
        require(limit > 0)
        val predicates = mutableListOf<String>()
        val bindings = mutableMapOf<String, Any?>()
        if (query.isNotBlank()) {
            predicates += "search.text @0@ \$query"
            bindings["query"] = query
        }
        if (contexts.isNotEmpty()) {
            predicates += "id IN \$contexts"
            bindings["contexts"] = view.ownershipClosure(contexts).map(ResourceId::surrealRecordId)
        }
        val where =
            predicates
                .takeIf { it.isNotEmpty() }
                ?.joinToString(" AND ")
                ?.let { " WHERE $it" }
                .orEmpty()
        val score = if (query.isBlank()) "0" else "search::score(0)"
        val index = if (query.isBlank()) "" else " WITH INDEX resource_text"
        return database.inPreviewTransaction { transaction ->
            val candidates = mutableListOf<IndexedAuthoringSearchCandidate>()
            var offset = 0
            val pageSize = maxOf(limit, 256)
            while (candidates.size < limit) {
                val rows =
                    transaction
                        .query(
                            "SELECT id, content, search.text AS text, $score AS score FROM resource$index$where " +
                                "ORDER BY score DESC, id LIMIT \$limit START \$offset;",
                            bindings + mapOf("limit" to pageSize, "offset" to offset),
                        ).take(0)
                        .getArray()
                rows.forEach { value ->
                    val row = value.getObject()
                    val record = decodeSkir(AuthoringRecord.serializer, row.get("content")).requireValid()
                    if (record.matches(roots, target, view.catalog.realmRoot, view.catalog.checked)) {
                        candidates +=
                            IndexedAuthoringSearchCandidate(
                                row.get("id").getRecordId().toResourceId(),
                                record,
                                row.get("text").getString(),
                            )
                    }
                }
                if (rows.len() < pageSize) break
                offset += rows.len()
            }
            candidates.take(limit)
        }
    }
}

internal fun AuthoringView.ownershipClosure(contexts: Set<ResourceId>): Set<ResourceId> {
    val outgoing = linksForOwnership(catalog.ownershipRelationIds)
    val reached = contexts.toMutableSet()
    val pending = ArrayDeque(contexts)
    while (pending.isNotEmpty()) {
        outgoing[pending.removeFirst()].orEmpty().forEach { if (reached.add(it)) pending.addLast(it) }
    }
    return reached
}

private fun AuthoringView.linksForOwnership(contracts: Set<RelationId>): Map<ResourceId, List<ResourceId>> =
    ResourceValueMapper
        .project(links.values, resources, catalog.relations, catalog.checked)
        .projections
        .filter { it.contract in contracts }
        .groupBy({ it.first }, { it.second })

private fun AuthoringRecord.matches(
    roots: Set<TypeDefinitionId>,
    target: NamedTypeUse?,
    realmRoot: TypeDefinitionId,
    catalog: CheckedCatalog,
): Boolean {
    val actualDefinition = configuration.definition
    // The realm root is the shell itself, never a search result; sections stay searchable for navigation.
    if (actualDefinition == realmRoot || catalog.isNominalSubtype(actualDefinition, realmRoot)) return false
    if (roots.isNotEmpty() && roots.none { catalog.isNominalSubtype(actualDefinition, it) }) return false
    if (target == null) return true
    return when (val selected = configuration) {
        is TypeSelection.CompleteWrapper -> catalog.isReadableAs(selected.use.use, target.use)
        is TypeSelection.PendingWrapper -> catalog.knownApplications(selected).any { catalog.isReadableAs(it.use, target.use) }
        else -> unknownVariant(selected)
    }
}
