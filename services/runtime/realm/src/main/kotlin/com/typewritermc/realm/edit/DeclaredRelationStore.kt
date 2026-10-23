package com.typewritermc.realm.edit

import com.surrealdb.RecordId
import com.surrealdb.Transaction
import com.surrealdb.Value
import com.typewritermc.realm.authoring.StoredDeclaredEdge
import com.typewritermc.realm.storage.decodeSkir
import com.typewritermc.realm.storage.encodeSkir
import com.typewritermc.realm.storage.surrealRecordId
import com.typewritermc.types.requireValid
import com.typewritermc.types.toSkir
import skirout.editor.v1.authoring.RelationProjectionDelta
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.type_catalog.ValuePath
import java.util.UUID

internal data class StoredRelationDelta(
    val removed: List<StoredDeclaredEdge>,
    val created: List<StoredDeclaredEdge>,
    val metadataChanged: List<StoredDeclaredEdge>,
)

internal interface DeclaredRelationStore {
    fun prepare(
        delta: RelationProjectionDelta,
        transaction: Transaction,
    ): StoredRelationDelta

    fun apply(
        delta: StoredRelationDelta,
        transaction: Transaction,
    )
}

/** Persists canonical relation projections without making edge rows authorable state. */
internal class SurrealDeclaredRelationStore : DeclaredRelationStore {
    override fun prepare(
        delta: RelationProjectionDelta,
        transaction: Transaction,
    ): StoredRelationDelta =
        StoredRelationDelta(
            removed = delta.removals.map { transaction.requireStored(it) },
            created = delta.created.map { it.stored(UUID.randomUUID().toString()) },
            metadataChanged = delta.metadataChanged.map { transaction.requireStored(it).copyLocations(it) },
        )

    override fun apply(
        delta: StoredRelationDelta,
        transaction: Transaction,
    ) {
        delta.removed.forEach { edge ->
            transaction
                .query(
                    "DELETE ONLY \$edge RETURN BEFORE;",
                    mapOf("edge" to RecordId("resource_relation", edge.physicalId)),
                ).take(0)
        }
        delta.metadataChanged.forEach { edge ->
            transaction
                .query(
                    "UPDATE ONLY \$edge SET first_location = \$first_location ?? NONE, " +
                        "second_location = \$second_location ?? NONE;",
                    edge.bindings(),
                ).take(0)
        }
        delta.created.forEach { edge ->
            transaction
                .query(
                    "RELATE ONLY \$first->\$edge->\$second CONTENT { contract: \$contract, " +
                        "first_location: \$first_location ?? NONE, second_location: \$second_location ?? NONE };",
                    edge.bindings(),
                ).take(0)
        }
    }
}

private fun Transaction.requireStored(projection: LinkProjection): StoredDeclaredEdge {
    val rows =
        query(
            "SELECT id, contract, in, out, first_location, second_location FROM resource_relation " +
                "WHERE contract = \$contract AND in = \$first AND out = \$second;",
            mapOf(
                "contract" to projection.contract.value,
                "first" to projection.first.surrealRecordId(),
                "second" to projection.second.surrealRecordId(),
            ),
        ).take(0).getArray().map { row ->
            val value = row.getObject()
            StoredDeclaredEdge(
                physicalId =
                    value.get("id").getRecordId().let { id ->
                        require(id.table == "resource_relation" && id.id.isString)
                        id.id.string
                    },
                relation = projection.contract,
                source = projection.first,
                target = projection.second,
                sourceLocation = value.get("first_location").decodePath(),
                targetLocation = value.get("second_location").decodePath(),
            )
        }
    return requireNotNull(
        rows.singleOrNull { row ->
            row.sourceLocation == projection.firstLocation && row.targetLocation == projection.secondLocation
        },
    ) { "Stored relation projection is missing or ambiguous for $projection." }
}

private fun LinkProjection.stored(id: String): StoredDeclaredEdge =
    StoredDeclaredEdge(id, contract, first, second, firstLocation, secondLocation)

private fun StoredDeclaredEdge.copyLocations(projection: LinkProjection): StoredDeclaredEdge =
    copy(sourceLocation = projection.firstLocation, targetLocation = projection.secondLocation)

private fun StoredDeclaredEdge.bindings(): Map<String, Any?> =
    mapOf(
        "edge" to RecordId("resource_relation", physicalId),
        "first" to source.surrealRecordId(),
        "second" to target.surrealRecordId(),
        "contract" to relation.value,
        "first_location" to sourceLocation?.let { encodeSkir(ValuePath.serializer, it) },
        "second_location" to targetLocation?.let { encodeSkir(ValuePath.serializer, it) },
    )

private fun Value.decodePath(): ValuePath? = if (isNull || isNone) null else decodeSkir(ValuePath.serializer, this).requireValid()
