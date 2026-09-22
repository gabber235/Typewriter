package com.typewritermc.realm.repository

import com.surrealdb.RecordId
import com.surrealdb.Transaction
import com.typewritermc.realm.repository.utils.StructuredDatabaseCodec
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.types.DataPath
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId

/** Writes canonical resource and relation rows inside the caller owned transaction. */
internal class SurrealResourceGraphStore {
    fun apply(
        transaction: Transaction,
        delta: AuthoringGraphDelta,
    ) {
        delta.relationRemovals.sorted().forEach { relationId ->
            transaction
                .query(
                    "DELETE ONLY \$edge;",
                    mapOf("edge" to RecordId("resource_relation", relationId)),
                ).consumeAll()
        }
        delta.resourceRemovals.sortedBy(ResourceId::value).forEach { id ->
            transaction
                .query(
                    "DELETE ONLY \$resource;",
                    mapOf("resource" to id.unifiedSurrealId()),
                ).consumeAll()
        }
        delta.resourceUpserts.toSortedMap(compareBy(ResourceId::value)).forEach { (id, value) ->
            if (id in delta.resourceCreates) {
                createResource(transaction, value)
            } else {
                updateResource(transaction, value)
            }
        }
        delta.relationUpserts
            .toSortedMap()
            .values
            .forEach(transaction::createRelation)
    }

    private fun createResource(
        transaction: Transaction,
        value: DecomposedResourceValue,
    ) {
        transaction
            .query(
                "CREATE ONLY \$resource CONTENT { definition: \$definition, type_id: \$type_id, " +
                    "type_revision: \$type_revision, value: \$value };",
                value.resource.bindings(),
            ).consumeAll()
    }

    private fun updateResource(
        transaction: Transaction,
        value: DecomposedResourceValue,
    ) {
        transaction
            .query(
                "UPDATE ONLY \$resource MERGE { definition: \$definition, type_id: \$type_id, " +
                    "type_revision: \$type_revision, value: \$value };",
                value.resource.bindings(),
            ).consumeAll()
    }
}

private fun StoredTypedResource.bindings(): Map<String, Any?> {
    val declared = root.id as? TypeId.Declared ?: error("Stored resources require declared root identities.")
    return mapOf(
        "resource" to id.unifiedSurrealId(),
        "definition" to definition.value,
        "type_id" to declared.id.toString(),
        "type_revision" to root.revision,
        "value" to
            StructuredDatabaseCodec.encode(
                com.typewritermc.types.DataValue
                    .serializer(),
                valueWithSlots,
            ),
    )
}

private fun Transaction.createRelation(relation: StoredResourceRelation) {
    val origin =
        when (val value = relation.origin) {
            is ResourceRelationOrigin.Reference -> {
                mapOf(
                    "kind" to "reference",
                    "reference_slot" to value.slot.value,
                    "source_path" to StructuredDatabaseCodec.encode(DataPath.serializer(), value.sourcePath),
                    "expected_target" to
                        StructuredDatabaseCodec.encode(TypeExpression.serializer(), value.expectedTarget),
                )
            }

            is ResourceRelationOrigin.Declared -> {
                mapOf(
                    "kind" to "declared",
                    "relation_id" to value.relationId.value,
                )
            }
        }
    val scalarOrigin =
        when (val value = relation.origin) {
            is ResourceRelationOrigin.Reference -> {
                mapOf(
                    "origin_kind" to "reference",
                    "source_path_key" to value.sourcePath.toString(),
                    "expected_target_key" to value.expectedTarget.toString(),
                )
            }

            is ResourceRelationOrigin.Declared -> {
                mapOf(
                    "origin_kind" to "declared",
                    "relation_id" to value.relationId.value,
                )
            }
        }
    query(
        "RELATE ONLY \$source->\$edge->\$target CONTENT \$content;",
        mapOf(
            "source" to relation.source.unifiedSurrealId(),
            "edge" to RecordId("resource_relation", relation.id),
            "target" to relation.target.unifiedSurrealId(),
            "content" to mapOf("origin" to origin) + scalarOrigin,
        ),
    ).consumeAll()
}

private fun com.surrealdb.Response.consumeAll() {
    for (index in 0 until size()) {
        take(index)
    }
}
