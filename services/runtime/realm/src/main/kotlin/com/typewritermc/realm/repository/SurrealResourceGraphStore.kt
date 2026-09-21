package com.typewritermc.realm.repository

import com.surrealdb.RecordId
import com.surrealdb.Transaction
import com.typewritermc.realm.repository.utils.StructuredDatabaseCodec
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.types.DataPath
import com.typewritermc.types.RelationEndpointSide
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId

/** Writes canonical resource and relation rows inside the caller owned transaction. */
internal class SurrealResourceGraphStore(
    private val mapper: ResourceValueMapper,
) {
    fun create(
        transaction: Transaction,
        value: DecomposedResourceValue,
    ) {
        transaction
            .query(
                "CREATE ONLY \$resource CONTENT { kind: \$kind, type_id: \$type_id, " +
                    "type_revision: \$type_revision, value: \$value };",
                value.resource.bindings(),
            ).consumeAll()
        value.relations.forEach { transaction.createRelation(it) }
    }

    fun replace(
        transaction: Transaction,
        value: DecomposedResourceValue,
    ) {
        val resourceId = value.resource.id.unifiedSurrealId()
        transaction
            .query(
                "UPDATE ONLY \$resource CONTENT { kind: \$kind, type_id: \$type_id, " +
                    "type_revision: \$type_revision, value: \$value };",
                value.resource.bindings(),
            ).consumeAll()
        transaction
            .query(
                "DELETE resource_relation WHERE in = \$resource AND origin.kind = 'reference';",
                mapOf("resource" to resourceId),
            ).consumeAll()
        mapper.ownedRelationEndpoints(value.resource.root).forEach { (relationId, side) ->
            val endpoint = if (side == RelationEndpointSide.SOURCE) "in" else "out"
            transaction
                .query(
                    "DELETE resource_relation WHERE $endpoint = \$resource " +
                        "AND origin.kind = 'declared' AND origin.relation_id = \$relation_id;",
                    mapOf("resource" to resourceId, "relation_id" to relationId.value),
                ).consumeAll()
        }
        value.relations.forEach { transaction.createRelation(it) }
    }

    fun delete(
        transaction: Transaction,
        id: ResourceId,
    ) {
        transaction
            .query(
                "DELETE resource_relation WHERE in = \$resource OR out = \$resource;",
                mapOf("resource" to id.unifiedSurrealId()),
            ).consumeAll()
        transaction.query("DELETE ONLY \$resource;", mapOf("resource" to id.unifiedSurrealId())).consumeAll()
    }
}

private fun StoredTypedResource.bindings(): Map<String, Any?> {
    val declared = root.id as? TypeId.Declared ?: error("Stored resources require declared root identities.")
    return mapOf(
        "resource" to id.unifiedSurrealId(),
        "kind" to kind.name.lowercase(),
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
    query(
        "RELATE ONLY \$source->\$edge->\$target CONTENT { origin: \$origin };",
        mapOf(
            "source" to relation.source.unifiedSurrealId(),
            "edge" to RecordId("resource_relation", relation.id),
            "target" to relation.target.unifiedSurrealId(),
            "origin" to origin,
        ),
    ).consumeAll()
}

private fun com.surrealdb.Response.consumeAll() {
    for (index in 0 until size()) {
        take(index)
    }
}
