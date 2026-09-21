package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.surrealdb.Value
import com.typewritermc.realm.repository.utils.StructuredDatabaseCodec
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.toUnifiedResourceId
import com.typewritermc.types.DataPath
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId

/** Loads one complete canonical graph and evaluates every named selection at one transaction sequence. */
internal class SurrealAuthoringGraphRepository(
    private val database: Surreal,
    private val mapper: () -> ResourceValueMapper,
    private val catalog: () -> TypeCatalog,
    private val generation: () -> String,
    private val limits: AuthoringGraphLimits = AuthoringGraphLimits(),
) : AuthoringGraphRepository {
    override suspend fun query(
        generation: String,
        selections: List<GraphSelection>,
    ): AuthoringGraphQueryResult {
        val initialGeneration = this.generation()
        if (generation != initialGeneration) return AuthoringGraphQueryResult.CatalogChanged(initialGeneration)
        return database.inTransaction { transaction ->
            val valueMapper = mapper()
            val storedResources = transaction.loadStoredResources()
            val relations = transaction.loadStoredRelations()
            val hydrated =
                storedResources.map { resource ->
                    AuthoringGraphResource(
                        id = resource.id,
                        kind = resource.kind,
                        content = valueMapper.hydrate(resource, relations),
                    )
                }
            val finalGeneration = this.generation()
            if (finalGeneration != initialGeneration) {
                AuthoringGraphQueryResult.CatalogChanged(finalGeneration)
            } else {
                AuthoringGraphQueryEngine(catalog(), limits).evaluate(
                    generation = initialGeneration,
                    sequence = transaction.currentGraphSequence(),
                    resources = hydrated,
                    edges = relations,
                    selections = selections,
                )
            }
        }
    }
}

internal fun Transaction.loadStoredResources(): List<StoredTypedResource> =
    query("SELECT id, kind, type_id, type_revision, value FROM resource ORDER BY id;")
        .take(0)
        .getArray()
        .map { value ->
            val row = value.getObject()
            StoredTypedResource(
                id = row.get("id").getRecordId().toUnifiedResourceId(),
                kind = AuthoringResourceKind.valueOf(row.get("kind").getString().uppercase()),
                root =
                    ResolvedTypeRef(
                        TypeId.Declared(DeclaredTypeId.parse(row.get("type_id").getString())),
                        row.get("type_revision").getLong().toInt(),
                    ),
                valueWithSlots =
                    StructuredDatabaseCodec.decode(
                        com.typewritermc.types.DataValue
                            .serializer(),
                        row.get("value"),
                    ),
            )
        }

internal fun Transaction.loadStoredRelations(): List<StoredResourceRelation> =
    query("SELECT id, in, out, origin FROM resource_relation ORDER BY id;")
        .take(0)
        .getArray()
        .map(::parseStoredRelation)

private fun parseStoredRelation(value: Value): StoredResourceRelation {
    val row = value.getObject()
    val origin = row.get("origin").getObject()
    val source = row.get("in").getRecordId().toUnifiedResourceId()
    val target = row.get("out").getRecordId().toUnifiedResourceId()
    return StoredResourceRelation(
        id =
            row
                .get("id")
                .getRecordId()
                .id.string,
        source = source,
        target = target,
        origin =
            when (origin.get("kind").getString()) {
                "reference" -> {
                    ResourceRelationOrigin.Reference(
                        slot = com.typewritermc.elements.ReferenceSlotId(origin.get("reference_slot").getString()),
                        sourcePath = StructuredDatabaseCodec.decode(DataPath.serializer(), origin.get("source_path")),
                        expectedTarget =
                            StructuredDatabaseCodec.decode(
                                TypeExpression.serializer(),
                                origin.get("expected_target"),
                            ),
                    )
                }

                "declared" -> {
                    ResourceRelationOrigin.Declared(RelationId(origin.get("relation_id").getString()))
                }

                else -> {
                    error("Unknown stored resource relation origin.")
                }
            },
    )
}

private fun Transaction.currentGraphSequence(): Long =
    query("SELECT VALUE revision FROM ONLY collaboration_head:current;").take(0).getLong()
