package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.surrealdb.Value
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.compiler.GraphReadRequirement
import com.typewritermc.realm.repository.utils.StructuredDatabaseCodec
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.toUnifiedResourceId
import com.typewritermc.types.DataPath
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression

/** Loads bounded authoring graph slices and evaluates every named selection at one transaction sequence. */
internal class SurrealAuthoringGraphRepository(
    private val database: Surreal,
    private val mapper: () -> ResourceValueMapper,
    private val catalog: () -> TypeCatalog,
    private val generation: () -> String,
    private val limits: AuthoringGraphLimits = AuthoringGraphLimits(),
) : AuthoringGraphRepository {
    internal suspend fun workingGraph(
        requirement: GraphReadRequirement,
        root: ResourceId?,
    ): AuthoringWorkingGraph =
        database.inTransaction { transaction ->
            val selection = requirement.toSelection(root)
            val bounded =
                when (val loaded = SurrealBoundedAuthoringGraphLoader(
                    limits.copy(
                        maxDepth = maxOf(limits.maxDepth, requirement.maximumDepth),
                        maxResources = minOf(limits.maxResources, requirement.maximumResources),
                        maxEdges = minOf(limits.maxEdges, requirement.maximumEdges),
                    ),
                    catalog(),
                ).load(transaction, listOf(selection))) {
                    is BoundedGraphLoadResult.Invalid -> error(loaded.result.message)
                    is BoundedGraphLoadResult.Success -> loaded.slice
                }
            val resources = bounded.resources.associateBy(StoredTypedResource::id)
            val relations = bounded.relations.associateByTo(linkedMapOf(), StoredResourceRelation::id)
            if (requirement.includeIncidentEdges && resources.isNotEmpty()) {
                val incident = transaction.loadRelations(
                    frontier = resources.keys,
                    direction = RelationDirection.BOTH,
                    filter = RelationFilter.Any,
                    limit = requirement.maximumEdges - relations.size + 1,
                )
                incident.forEach { relations[it.id] = it }
                require(relations.size <= requirement.maximumEdges) {
                    "Compilation graph edge limit was exceeded."
                }
            }
            AuthoringWorkingGraph(resources = resources, relations = relations)
        }

    override suspend fun query(
        generation: String,
        selections: List<GraphSelection>,
    ): AuthoringGraphQueryResult {
        val initialGeneration = this.generation()
        if (generation != initialGeneration) return AuthoringGraphQueryResult.CatalogChanged(initialGeneration)
        return database.inTransaction { transaction ->
            val bounded =
                when (val loaded = SurrealBoundedAuthoringGraphLoader(limits, catalog()).load(transaction, selections)) {
                    is BoundedGraphLoadResult.Invalid -> {
                        return@inTransaction loaded.result
                    }

                    is BoundedGraphLoadResult.Success -> {
                        loaded.slice
                    }
                }
            val valueMapper = mapper()
            val relationsByResource =
                bounded.relations
                    .flatMap { relation -> listOf(relation.source to relation, relation.target to relation) }
                    .groupBy({ it.first }, { it.second })
            val hydrated =
                (bounded.resources + bounded.diagnosticResources).distinctBy(StoredTypedResource::id).map { resource ->
                    AuthoringGraphResource(
                        id = resource.id,
                        definition = resource.definition,
                        content = valueMapper.hydrate(resource, relationsByResource[resource.id].orEmpty()),
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
                    edges = bounded.relations,
                    selections = selections,
                )
            }
        }
    }
}

internal fun GraphReadRequirement.toSelection(root: ResourceId?): GraphSelection =
    toSelection(
        key = "authoring-compilation-${root?.value ?: "roots"}",
        seed =
            root?.let { ResourceSeed.Ids(listOf(it)) }
                ?: ResourceSeed.Scan(ResourceFilter(definitions = definitions)),
    )

internal fun GraphReadRequirement.toSelection(
    key: String,
    seed: ResourceSeed,
): GraphSelection {
    val hasDependencies = relations.isNotEmpty() || incomingReferences || outgoingReferences
    val relationSteps =
        if (!hasDependencies) {
            emptyList()
        } else {
            listOf(
                RelationStep(
                    relations =
                        RelationFilter.PolicyDependencies(
                            declaredRelationIds = relations,
                            declaredDirection = direction.toRelationDirection(),
                            incomingReferences = incomingReferences,
                            outgoingReferences = outgoingReferences,
                        ),
                    direction = RelationDirection.BOTH,
                    minDepth = minOf(1, maximumDepth),
                    maxDepth = maximumDepth,
                    target = ResourceFilter(definitions = definitions),
                ),
            )
        }
    return GraphSelection(
        key = key,
        seed = seed,
        steps = relationSteps,
    )
}

private fun GraphReadRequirement.Direction.toRelationDirection(): RelationDirection =
    when (this) {
        GraphReadRequirement.Direction.OUTGOING -> RelationDirection.OUTGOING
        GraphReadRequirement.Direction.INCOMING -> RelationDirection.INCOMING
        GraphReadRequirement.Direction.BOTH -> RelationDirection.BOTH
    }

internal fun parseStoredResource(value: Value): StoredTypedResource {
    val row = value.getObject()
    return StoredTypedResource(
        id = row.get("id").getRecordId().toUnifiedResourceId(),
        definition = ResourceDefinitionId(row.get("definition").getString()),
        root = StructuredDatabaseCodec.decode(ResolvedTypeRef.serializer(), row.get("root")),
        valueWithSlots =
            StructuredDatabaseCodec.decode(
                com.typewritermc.types.DataValue
                    .serializer(),
                row.get("value"),
            ),
    )
}

internal fun parseStoredRelation(value: Value): StoredResourceRelation {
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
                    ResourceRelationOrigin.Declared(
                        relationId = RelationId(origin.get("relation_id").getString()),
                        sourceIndex = origin.get("source_index").takeUnless(Value::isNull)?.getLong()?.toInt(),
                        targetIndex = origin.get("target_index").takeUnless(Value::isNull)?.getLong()?.toInt(),
                    )
                }

                else -> {
                    error("Unknown stored resource relation origin.")
                }
            },
    )
}

private fun Transaction.currentGraphSequence(): Long =
    query("SELECT VALUE revision FROM ONLY collaboration_head:current;").take(0).getLong()
