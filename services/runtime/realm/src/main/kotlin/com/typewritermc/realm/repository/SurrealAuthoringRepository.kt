package com.typewritermc.realm.repository

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.typewritermc.realm.RealmResourceKindDefinition
import com.typewritermc.realm.repository.utils.inPreviewTransaction
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypePrototypeRegistry
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.security.MessageDigest

/** Applies generic resource operations to the canonical resource graph in one Surreal transaction. */
internal class SurrealAuthoringRepository(
    private val database: Surreal,
    private val prototypes: TypePrototypeRegistry,
    private val catalogGeneration: () -> String,
    private val resourceKinds: () -> List<RealmResourceKindDefinition>,
    private val relations: () -> List<RelationDefinition>,
    private val typeCatalog: () -> TypeCatalog,
) : AuthoringRepository {
    override suspend fun apply(batch: AuthoringBatch): AuthoringBatchResult {
        val initialGeneration = catalogGeneration()
        if (batch.generation != initialGeneration) return AuthoringBatchResult.CatalogChanged(initialGeneration)
        return try {
            database.inTransaction { transaction ->
                val requestHash = canonicalJson.encodeToString(batch).sha256()
                transaction.replay(batch.id, requestHash)?.let { return@inTransaction it }
                val mutation = transaction.mutate(batch.operations)
                val finalGeneration = catalogGeneration()
                if (finalGeneration != initialGeneration) {
                    throw AuthoringRejected(AuthoringBatchResult.CatalogChanged(finalGeneration))
                }
                val sequence = transaction.advanceCollaborationRevision()
                transaction.query("UPDATE ONLY authoring_head:current SET revision += 1;").take(0)
                val result =
                    AuthoringBatchResult.Applied(
                        change =
                            AuthoringChanged(
                                generation = initialGeneration,
                                sequence = sequence,
                                batchId = batch.id,
                                resources = mutation.resourceChanges,
                                edges = mutation.edgeChanges,
                            ),
                        affectsCompilation = true,
                    )
                transaction.store(batch.id, requestHash, result)
                result
            }
        } catch (rejected: AuthoringRejected) {
            rejected.result
        }
    }

    override suspend fun preview(
        generation: String,
        operations: List<AuthoringOperation>,
    ): AuthoringPreviewResult {
        val initialGeneration = catalogGeneration()
        if (generation != initialGeneration) return AuthoringPreviewResult.CatalogChanged(initialGeneration)
        require(operations.isNotEmpty()) { "Authoring previews must not be empty." }
        require(operations.map(AuthoringOperation::resourceId).distinct().size == operations.size) {
            "Authoring previews must contain at most one operation per resource."
        }
        return try {
            database.inPreviewTransaction { transaction ->
                val mutation = transaction.mutate(operations)
                val finalGeneration = catalogGeneration()
                if (finalGeneration != initialGeneration) {
                    AuthoringPreviewResult.CatalogChanged(finalGeneration)
                } else {
                    AuthoringPreviewResult.Valid(
                        affectedResources = mutation.resourceChanges.mapTo(linkedSetOf()) { it.resourceId },
                        affectedEdges = mutation.edgeChanges.mapTo(linkedSetOf()) { it.edgeId },
                    )
                }
            }
        } catch (rejected: AuthoringRejected) {
            when (val result = rejected.result) {
                is AuthoringBatchResult.Conflict -> AuthoringPreviewResult.Conflict(result.conflicts)
                is AuthoringBatchResult.Invalid -> AuthoringPreviewResult.Invalid(result.diagnostics)
                is AuthoringBatchResult.CatalogChanged -> AuthoringPreviewResult.CatalogChanged(result.actualGeneration)
                is AuthoringBatchResult.Applied -> error("Applied results cannot reject an authoring preview.")
            }
        }
    }

    private fun Transaction.mutate(operations: List<AuthoringOperation>): MutationResult {
        val mapper = ResourceValueMapper(prototypes, relations())
        val mutation =
            GenericResourceMutation(
                transaction = this,
                mapper = mapper,
                store = SurrealResourceGraphStore(mapper),
                resourceKinds = resourceKinds(),
                relations = relations(),
                catalog = typeCatalog(),
            )
        operations.forEach { operation ->
            when (operation) {
                is AuthoringOperation.CreateResource -> mutation.create(operation)
                is AuthoringOperation.CommitResource -> mutation.commit(operation)
                is AuthoringOperation.DeleteResource -> mutation.delete(operation)
            }
        }
        val storedRelations = loadStoredRelations()
        val storedResources = loadStoredResources().associateBy(StoredTypedResource::id)
        val affected =
            buildSet {
                addAll(mutation.upserts.keys)
                addAll(mutation.affectedResources)
            }
        val resourceChanges =
            buildList {
                affected.sortedBy(ResourceId::value).forEach { id ->
                    val stored = storedResources[id] ?: return@forEach
                    add(
                        GraphResourceChange.Upsert(
                            AuthoringGraphResource(
                                id = id,
                                kind = stored.kind,
                                content = mapper.hydrate(stored, storedRelations),
                            ),
                        ),
                    )
                }
                mutation.removals.sortedBy(ResourceId::value).forEach { add(GraphResourceChange.Remove(it)) }
            }
        val edgeChanges =
            mutation.edgeUpserts.values
                .sortedBy(StoredResourceRelation::id)
                .map(GraphEdgeChange::Upsert) +
                mutation.edgeRemovals.sorted().map(GraphEdgeChange::Remove)
        return MutationResult(resourceChanges, edgeChanges)
    }
}

private data class MutationResult(
    val resourceChanges: List<GraphResourceChange>,
    val edgeChanges: List<GraphEdgeChange>,
)

private val GraphResourceChange.resourceId: ResourceId
    get() =
        when (this) {
            is GraphResourceChange.Upsert -> resource.id
            is GraphResourceChange.Remove -> id
        }

private val GraphEdgeChange.edgeId: String
    get() =
        when (this) {
            is GraphEdgeChange.Upsert -> edge.id
            is GraphEdgeChange.Remove -> id
        }

private fun Transaction.advanceCollaborationRevision(): Long =
    query("UPDATE ONLY collaboration_head:current SET revision += 1 RETURN VALUE revision;").take(0).getLong()

private fun Transaction.replay(
    batchId: BatchId,
    requestHash: String,
): AuthoringBatchResult? {
    val value =
        query(
            "SELECT operation, request_hash, result FROM ONLY \$batch;",
            mapOf("batch" to RecordId("authoring_batch", batchId.value)),
        ).take(0)
    if (value.isNone || value.isNull) return null
    val stored = value.getObject()
    if (stored.get("operation").getString() != AUTHORING_OPERATION || stored.get("request_hash").getString() != requestHash) {
        return AuthoringBatchResult.Invalid(
            listOf(AuthoringDiagnostic("batch-id-reused", "Batch id was already used for another request.")),
        )
    }
    return canonicalJson.decodeFromString(AuthoringBatchResult.serializer(), stored.get("result").getString())
}

private fun Transaction.store(
    batchId: BatchId,
    requestHash: String,
    result: AuthoringBatchResult.Applied,
) {
    query(
        "CREATE ONLY \$batch CONTENT { operation: \$operation, request_hash: \$request_hash, result: \$result };",
        mapOf(
            "batch" to RecordId("authoring_batch", batchId.value),
            "operation" to AUTHORING_OPERATION,
            "request_hash" to requestHash,
            "result" to canonicalJson.encodeToString(AuthoringBatchResult.serializer(), result),
        ),
    ).take(0)
}

internal class AuthoringRejected(
    val result: AuthoringBatchResult,
) : RuntimeException(null, null, false, false)

private fun String.sha256(): String =
    MessageDigest.getInstance("SHA-256").digest(toByteArray()).joinToString("") { "%02x".format(it.toInt() and 0xff) }

private const val AUTHORING_OPERATION = "apply_authoring_batch"

private val canonicalJson =
    Json {
        allowStructuredMapKeys = true
        encodeDefaults = true
        explicitNulls = true
        classDiscriminator = "_kind"
    }
