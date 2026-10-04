package com.typewritermc.realm.search

import com.surrealdb.RecordId
import com.surrealdb.Transaction
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.SearchSelectorId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.realm.authoring.authoringStorageJson
import com.typewritermc.realm.repository.AuthoringMutationPlan
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedCatalog
import kotlinx.serialization.encodeToString
import java.security.MessageDigest

internal data class IndexedDocument(
    val resource: ResourceId,
    val definition: ResourceDefinitionId,
    val record: AuthoringRecord,
    val text: String,
    val selectors: Map<SearchSelectorId, Set<String>>,
    val ownerPath: List<ResourceId>,
)

internal fun interface SearchDocumentProjector {
    fun project(
        resource: ResourceId,
        definition: ResourceDefinitionId,
        record: AuthoringRecord,
        ownerPath: List<ResourceId>,
    ): IndexedDocument
}

/** Updates search rows inside the authoring acceptance transaction. */
internal class AuthoringSearchIndexer(
    private val projector: SearchDocumentProjector = SearchDocumentProjector(::defaultDocument),
) {
    fun apply(
        transaction: Transaction,
        plan: AuthoringMutationPlan,
        resources: Map<ResourceId, AuthoringRecord>,
        definitions: Map<ResourceId, ResourceDefinitionId>,
        catalog: CheckedCatalog,
        contracts: List<RelationContract>,
        endpointBindings: List<EndpointBindingTemplate>,
        snapshot: Long,
    ) {
        val affected =
            buildSet {
                addAll(plan.resources.keys)
                addAll(plan.removedResources)
                plan.relations.removed.forEach {
                    add(it.first)
                    add(it.second)
                }
                plan.relations.created.forEach {
                    add(it.first)
                    add(it.second)
                }
                plan.relations.metadataChanged.forEach {
                    add(it.first)
                    add(it.second)
                }
            }
        if (affected.isEmpty()) return
        val ownerPaths = ownerPaths(resources, contracts, catalog, endpointBindings)
        affected.sortedBy(ResourceId::value).forEach { resource ->
            transaction.deleteSearch(resource)
            val record = resources[resource] ?: return@forEach
            val definition = requireNotNull(definitions[resource]) { "Resource ${resource.value} is missing its definition identity." }
            val document = projector.project(resource, definition, record, ownerPaths[resource].orEmpty())
            transaction
                .query(
                    "CREATE ONLY \$search CONTENT { resource: \$resource, definition: \$definition, content: \$content, " +
                        "text: \$text, owner_path: \$owner_path, snapshot: \$snapshot };",
                    mapOf(
                        "search" to RecordId("authoring_search", resource.value),
                        "resource" to resource.unifiedSurrealId(),
                        "definition" to document.definition.value,
                        "content" to authoringStorageJson.encodeToString(AuthoringRecord.serializer(), document.record),
                        "text" to document.text,
                        "owner_path" to document.ownerPath.map(ResourceId::value),
                        "snapshot" to snapshot,
                    ),
                ).take(0)
            document.selectors.forEach { (facet, values) ->
                values.groupBy(::normalize).forEach { (normalized, displays) ->
                    transaction
                        .query(
                            "CREATE ONLY \$selector CONTENT { resource: \$resource, facet: \$facet, " +
                                "normalized: \$normalized, display: \$display };",
                            mapOf(
                                "selector" to RecordId("authoring_search_selector", selectorId(resource, facet, normalized)),
                                "resource" to resource.unifiedSurrealId(),
                                "facet" to facet.value,
                                "normalized" to normalized,
                                "display" to displays.sorted().first(),
                            ),
                        ).take(0)
                }
            }
        }
    }
}

private fun Transaction.deleteSearch(resource: ResourceId) {
    query("DELETE ONLY \$search;", mapOf("search" to RecordId("authoring_search", resource.value))).take(0)
    query("DELETE authoring_search_selector WHERE resource = \$resource;", mapOf("resource" to resource.unifiedSurrealId())).take(0)
}

private fun defaultDocument(
    resource: ResourceId,
    definition: ResourceDefinitionId,
    record: AuthoringRecord,
    ownerPath: List<ResourceId>,
): IndexedDocument {
    val terms = mutableListOf(resource.value, definition.value)
    record.fields.values.forEach { it.collectText(terms) }
    return IndexedDocument(resource, definition, record, terms.distinct().joinToString(" "), emptyMap(), ownerPath)
}

private fun DataValue.collectText(target: MutableList<String>) {
    when (this) {
        is DataValue.StringValue -> {
            target += value
        }

        is DataValue.EnumCase -> {
            target += key
        }

        is DataValue.Named -> {
            payload.collectText(target)
        }

        is DataValue.Record -> {
            fields.values.forEach { it.collectText(target) }
        }

        is DataValue.ListValue -> {
            items.forEach { it.value.collectText(target) }
        }

        is DataValue.SetValue -> {
            items.forEach { it.value.collectText(target) }
        }

        is DataValue.MapValue -> {
            rows.forEach { row ->
                row.key.collectText(target)
                row.value.collectText(target)
            }
        }

        else -> {
            Unit
        }
    }
}

private fun ownerPaths(
    resources: Map<ResourceId, AuthoringRecord>,
    contracts: List<RelationContract>,
    catalog: CheckedCatalog,
    endpointBindings: List<EndpointBindingTemplate>,
): Map<ResourceId, List<ResourceId>> {
    val ownership =
        contracts.filter { RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID) in it.families }.mapTo(hashSetOf()) { it.id }
    val projections =
        ResourceValueMapper
            .project(ResourceValueMapper.discover(resources), resources, contracts, catalog)
            .projections
    val parent = projections.filter { it.contract in ownership }.associate { it.second to it.first }
    return resources.keys.associateWith { resource ->
        buildList {
            val visited = linkedSetOf<ResourceId>()
            var current = parent[resource]
            while (current != null && visited.add(current)) {
                add(current)
                current = parent[current]
            }
        }
    }
}

private fun normalize(value: String): String = value.trim().lowercase()

private fun selectorId(
    resource: ResourceId,
    facet: SearchSelectorId,
    normalized: String,
): String =
    MessageDigest
        .getInstance("SHA-256")
        .digest("${resource.value}:${facet.value}:$normalized".toByteArray())
        .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
