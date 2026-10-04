package com.typewritermc.realm.repository

import com.surrealdb.RecordId
import com.surrealdb.Transaction
import com.typewritermc.authoring.LinkProjection
import com.typewritermc.authoring.RelationProjectionDelta
import com.typewritermc.authoring.ValuePath
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import kotlinx.serialization.json.Json
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
        snapshot: Long,
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
            removed = delta.removed.map { transaction.requireStored(it) },
            created = delta.created.map { it.stored(UUID.randomUUID().toString()) },
            metadataChanged = delta.metadataChanged.map { transaction.requireStored(it).copyLocations(it) },
        )

    override fun apply(
        delta: StoredRelationDelta,
        snapshot: Long,
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
                        "second_location = \$second_location ?? NONE, " +
                        "first_occurrence = \$first_occurrence, second_occurrence = \$second_occurrence, snapshot = \$snapshot;",
                    edge.bindings(snapshot),
                ).take(0)
        }
        delta.created.forEach { edge ->
            transaction
                .query(
                    "RELATE ONLY \$first->\$edge->\$second CONTENT { contract: \$contract, " +
                        "first_location: \$first_location ?? NONE, second_location: \$second_location ?? NONE, " +
                        "first_occurrence: \$first_occurrence, second_occurrence: \$second_occurrence, snapshot: \$snapshot };",
                    edge.bindings(snapshot),
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
                "first" to projection.first.unifiedSurrealId(),
                "second" to projection.second.unifiedSurrealId(),
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

private fun StoredDeclaredEdge.bindings(snapshot: Long): Map<String, Any?> =
    mapOf(
        "edge" to RecordId("resource_relation", physicalId),
        "first" to source.unifiedSurrealId(),
        "second" to target.unifiedSurrealId(),
        "contract" to relation.value,
        "first_location" to sourceLocation?.let { relationJson.encodeToString(ValuePath.serializer(), it) },
        "second_location" to targetLocation?.let { relationJson.encodeToString(ValuePath.serializer(), it) },
        "first_occurrence" to occurrenceKey(sourceLocation),
        "second_occurrence" to occurrenceKey(targetLocation),
        "snapshot" to snapshot,
    )

private fun StoredDeclaredEdge.occurrenceKey(path: ValuePath?): String =
    path?.let { "location:${relationJson.encodeToString(ValuePath.serializer(), it)}" } ?: "edge:$physicalId"

private fun com.surrealdb.Value.decodePath(): ValuePath? =
    if (isNull || isNone) null else relationJson.decodeFromString(ValuePath.serializer(), getString())

private val relationJson =
    Json {
        encodeDefaults = true
        explicitNulls = true
        classDiscriminator = "kind"
    }
