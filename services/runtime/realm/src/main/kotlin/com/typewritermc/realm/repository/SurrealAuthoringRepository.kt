package com.typewritermc.realm.repository

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.typewritermc.authoring.AuthoringChangeSummary
import com.typewritermc.realm.AuthoringResourceDefinition
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.compiler.AuthoringCompilationProjectionRegistry
import com.typewritermc.realm.compiler.GraphReadRequirement
import com.typewritermc.realm.repository.utils.inPreviewTransaction
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.search.AuthoringSearchIndexer
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
    private val resourceDefinitions: () -> List<AuthoringResourceDefinition>,
    private val relations: () -> List<RelationDefinition>,
    private val typeCatalog: () -> TypeCatalog,
    private val validationRules: () -> List<AuthoringGraphRule>,
    private val policyGraphRequirements: () -> List<GraphReadRequirement>,
    private val compilationProjections: () -> AuthoringCompilationProjectionRegistry,
    private val searchIndexer: () -> AuthoringSearchIndexer,
    private val presentationMaterializer: () -> AuthoringPresentationMaterializer,
) : AuthoringRepository {
    override suspend fun apply(batch: AuthoringBatch): AuthoringBatchResult {
        val initialGeneration = catalogGeneration()
        if (batch.generation != initialGeneration) return AuthoringBatchResult.CatalogChanged(initialGeneration)
        return try {
            database.inTransaction { transaction ->
                val requestHash = canonicalJson.encodeToString(batch).sha256()
                transaction.replay(batch.id, requestHash)?.let { return@inTransaction it }
                val plan = transaction.plan(batch.operations)
                val finalGeneration = catalogGeneration()
                if (finalGeneration != initialGeneration) {
                    throw AuthoringRejected(AuthoringBatchResult.CatalogChanged(finalGeneration))
                }
                SurrealResourceGraphStore().apply(transaction, plan.delta)
                searchIndexer().apply(transaction, plan)
                val sequence = transaction.advanceCollaborationRevision()
                transaction.query("UPDATE ONLY authoring_head:current SET revision += 1;").take(0)
                val mutation = plan.toMutationResult()
                val compilationImpact =
                    compilationProjections()
                        .impact(plan.delta, plan.before, plan.proposed)
                        .roots
                        .flatMap { (projection, roots) ->
                            roots.map { root -> com.typewritermc.engine.CompilationRoot(projection, root) }
                        }
                val presentations =
                    presentationMaterializer()
                        .materialize(
                            plan.before,
                            plan.proposed,
                            AuthoringChangeSummary(
                                changedResources = plan.changedResources,
                                changedEdges = plan.changedEdges,
                                deletedResources = plan.before.resources.keys - plan.proposed.resources.keys,
                            ),
                        )
                val result =
                    AuthoringBatchResult.Applied(
                        change =
                            AuthoringChanged(
                                generation = initialGeneration,
                                sequence = sequence,
                                batchId = batch.id,
                                resources = mutation.resourceChanges,
                                edges = mutation.edgeChanges,
                                presentations = presentations,
                                compilationImpact = compilationImpact,
                            ),
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
        val direct = operations.mapNotNull(AuthoringOperation::directResourceId)
        require(direct.distinct().size == direct.size) {
            "Authoring previews must contain at most one operation per resource."
        }
        return try {
            database.inPreviewTransaction { transaction ->
                val plan = transaction.plan(operations)
                val finalGeneration = catalogGeneration()
                if (finalGeneration != initialGeneration) {
                    AuthoringPreviewResult.CatalogChanged(finalGeneration)
                } else {
                    AuthoringPreviewResult.Valid(
                        affectedResources = plan.changedResources,
                        affectedEdges = plan.changedEdges,
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

    private fun Transaction.plan(operations: List<AuthoringOperation>): AuthoringMutationPlan {
        val mapper = ResourceValueMapper(prototypes, relations())
        val rules = validationRules()
        val planner =
            AuthoringMutationPlanner(
                mapper = mapper,
                resourceDefinitions = resourceDefinitions(),
                relations = relations(),
                catalog = typeCatalog(),
                rules = rules,
            )
        val roots =
            operations.flatMapTo(linkedSetOf()) { operation ->
                when (operation) {
                    is AuthoringOperation.CreateResource -> listOf(operation.id)
                    is AuthoringOperation.CommitResource -> listOf(operation.id)
                    is AuthoringOperation.DeleteResource -> listOf(operation.id)
                    is AuthoringOperation.DeclareRelation -> listOf(operation.source, operation.target)
                }
            }
        operations
            .asSequence()
            .mapNotNull { operation ->
                val content =
                    when (operation) {
                        is AuthoringOperation.CreateResource -> operation.content
                        is AuthoringOperation.CommitResource -> operation.proposed
                        else -> null
                    } ?: return@mapNotNull null
                runCatching {
                    mapper.decompose(operation.directResourceId ?: return@runCatching null, ResourceDefinitionId("mutation.probe"), content)
                }.getOrNull()
            }.flatMap { value -> value.relations.asSequence() }
            .flatMapTo(roots) { relation -> sequenceOf(relation.source, relation.target) }
        val requirement =
            (rules.map(AuthoringGraphRule::graphRequirement) + policyGraphRequirements())
                .fold(
                    mutationGraphRequirement(
                        definitions = resourceDefinitions().mapTo(linkedSetOf(), AuthoringResourceDefinition::id),
                        relations = relations().mapTo(linkedSetOf(), RelationDefinition::id),
                    ),
                    GraphReadRequirement::plus,
                )
        val before =
            when (val loaded = SurrealMutationGraphLoader().load(this, roots, requirement)) {
                is MutationGraphLoadResult.Success -> {
                    loaded.graph
                }

                is MutationGraphLoadResult.Invalid -> {
                    throw AuthoringRejected(AuthoringBatchResult.Invalid(listOf(loaded.diagnostic)))
                }
            }
        return when (val result = planner.plan(before, operations)) {
            is AuthoringMutationPlanResult.Valid -> result.plan
            is AuthoringMutationPlanResult.Conflict -> throw AuthoringRejected(AuthoringBatchResult.Conflict(result.conflicts))
            is AuthoringMutationPlanResult.Invalid -> throw AuthoringRejected(AuthoringBatchResult.Invalid(result.diagnostics))
        }
    }

    private fun AuthoringMutationPlan.toMutationResult(): MutationResult {
        val mapper = ResourceValueMapper(prototypes, relations())
        val resources =
            changedResources
                .sortedBy(ResourceId::value)
                .mapNotNull { id ->
                    val stored = proposed.resources[id] ?: return@mapNotNull null
                    GraphResourceChange.Upsert(
                        AuthoringGraphResource(
                            id = id,
                            definition = stored.definition,
                            content = mapper.hydrate(stored, proposed.relations.values),
                        ),
                    )
                } + delta.resourceRemovals.sortedBy(ResourceId::value).map(GraphResourceChange::Remove)
        val edges =
            delta.relationUpserts.values
                .sortedBy(StoredResourceRelation::id)
                .map(GraphEdgeChange::Upsert) +
                delta.relationRemovals.sorted().map(GraphEdgeChange::Remove)
        return MutationResult(resources, edges)
    }
}

private fun mutationGraphRequirement(
    definitions: Set<ResourceDefinitionId>,
    relations: Set<com.typewritermc.types.RelationId>,
) = GraphReadRequirement(
    definitions = definitions,
    relations = relations,
    incomingReferences = true,
    outgoingReferences = true,
    direction = GraphReadRequirement.Direction.BOTH,
    maximumDepth = 16,
    maximumResources = 100_000,
    maximumEdges = 250_000,
)

private data class MutationResult(
    val resourceChanges: List<GraphResourceChange>,
    val edgeChanges: List<GraphEdgeChange>,
)

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
