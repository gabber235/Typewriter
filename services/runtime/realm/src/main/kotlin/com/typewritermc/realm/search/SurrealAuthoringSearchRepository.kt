package com.typewritermc.realm.search

import com.surrealdb.Surreal
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.authoredDatabaseValues
import com.typewritermc.realm.repository.utils.inPreviewTransaction
import com.typewritermc.realm.repository.utils.toUnifiedResourceId
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog

internal data class IndexedAuthoringSearchCandidate(
    val resource: ResourceId,
    val definition: ResourceDefinitionId,
    val record: AuthoringRecord,
    val text: String,
)

internal interface AuthoringSearchRepository {
    fun search(
        view: AuthoringView,
        query: String,
        contexts: Set<ResourceId>,
        roots: Set<TypeDefinitionId>,
        target: TypeUse.Named?,
        limit: Int,
    ): List<IndexedAuthoringSearchCandidate>
}

/** The caller holds the current view lock throughout the database read. */
internal class SurrealAuthoringSearchRepository(
    private val database: Surreal,
) : AuthoringSearchRepository {
    override fun search(
        view: AuthoringView,
        query: String,
        contexts: Set<ResourceId>,
        roots: Set<TypeDefinitionId>,
        target: TypeUse.Named?,
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
            bindings["contexts"] = view.ownershipClosure(contexts).map(ResourceId::unifiedSurrealId)
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
                            "SELECT id, definition, content, search.text AS text, $score AS score FROM resource$index$where " +
                                "ORDER BY score DESC, id LIMIT \$limit START \$offset;",
                            bindings + mapOf("limit" to pageSize, "offset" to offset),
                        ).take(0)
                        .getArray()
                rows.forEach { value ->
                    val row = value.getObject()
                    val record = authoredDatabaseValues.decode(AuthoringRecord.serializer(), row.get("content"))
                    if (record.matches(roots, target, view.catalog.checked)) {
                        candidates +=
                            IndexedAuthoringSearchCandidate(
                                row.get("id").getRecordId().toUnifiedResourceId(),
                                ResourceDefinitionId(row.get("definition").getString()),
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
    val ownership = catalog.relations.filter { RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID) in it.families }.mapTo(hashSetOf()) { it.id }
    val outgoing = linksForOwnership(ownership)
    val reached = contexts.toMutableSet()
    val pending = ArrayDeque(contexts)
    while (pending.isNotEmpty()) {
        outgoing[pending.removeFirst()].orEmpty().forEach { if (reached.add(it)) pending.addLast(it) }
    }
    return reached
}

private fun AuthoringView.linksForOwnership(contracts: Set<com.typewritermc.types.RelationId>): Map<ResourceId, List<ResourceId>> =
    com.typewritermc.realm.repository.ResourceValueMapper
        .project(links.values, resources, catalog.relations, catalog.checked)
        .projections
        .filter { it.contract in contracts }
        .groupBy({ it.first }, { it.second })

private fun AuthoringRecord.matches(
    roots: Set<TypeDefinitionId>,
    target: TypeUse.Named?,
    catalog: CheckedCatalog,
): Boolean {
    val actualDefinition =
        when (val selected = configuration) {
            is TypeSelection.Complete -> selected.use.definition
            is TypeSelection.Pending -> selected.definition
        }
    if (roots.isNotEmpty() && roots.none { catalog.isNominalSubtype(actualDefinition, it) }) return false
    if (target == null) return true
    return when (val selected = configuration) {
        is TypeSelection.Complete -> catalog.isReadableAs(selected.use, target)
        is TypeSelection.Pending -> catalog.knownApplications(selected).any { catalog.isReadableAs(it, target) }
    }
}
