package com.typewritermc.realm.repository

import com.typewritermc.realm.AuthoringResourceDefinition
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.compiler.GraphReadRequirement
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataPathSegment
import com.typewritermc.types.DataValue
import com.typewritermc.types.FieldMergeStrategy
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationEndpointSide
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.effectiveRelationField
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.TypedValueEnvelope

/** Supplies one registered graph invariant to the common mutation planner. */
internal interface AuthoringGraphRule {
    val id: String
    val graphRequirement: GraphReadRequirement

    fun validate(context: AuthoringGraphValidationContext): List<AuthoringDiagnostic>
}

/** Gives a graph rule the captured graph before and after the proposed mutation. */
internal data class AuthoringGraphValidationContext(
    val before: AuthoringWorkingGraph,
    val proposed: AuthoringWorkingGraph,
    val changedResources: Set<ResourceId>,
    val changedEdges: Set<String>,
    val deletedResources: Set<ResourceId>,
)

/** The bounded graph snapshot used to plan one mutation batch. */
internal data class AuthoringWorkingGraph(
    val resources: Map<ResourceId, StoredTypedResource>,
    val relations: Map<String, StoredResourceRelation>,
)

/** Explicit persistence work. The store applies this delta without interpreting authoring policy. */
internal data class AuthoringGraphDelta(
    val resourceUpserts: Map<ResourceId, DecomposedResourceValue>,
    val resourceCreates: Set<ResourceId>,
    val resourceRemovals: Set<ResourceId>,
    val relationUpserts: Map<String, StoredResourceRelation>,
    val relationRemovals: Set<String>,
    val relationUpdates: Set<String> = emptySet(),
)

/** A validated mutation and the exact graph delta it produces. */
internal data class AuthoringMutationPlan(
    val before: AuthoringWorkingGraph,
    val proposed: AuthoringWorkingGraph,
    val delta: AuthoringGraphDelta,
    val changedResources: Set<ResourceId>,
    val changedEdges: Set<String>,
)

internal sealed interface AuthoringMutationPlanResult {
    data class Valid(
        val plan: AuthoringMutationPlan,
    ) : AuthoringMutationPlanResult

    data class Conflict(
        val conflicts: List<PropertyConflict>,
    ) : AuthoringMutationPlanResult

    data class Invalid(
        val diagnostics: List<AuthoringDiagnostic>,
    ) : AuthoringMutationPlanResult
}

/** Builds a complete graph mutation before the caller performs any database write. */
internal class AuthoringMutationPlanner(
    private val mapper: ResourceValueMapper,
    private val resourceDefinitions: Collection<AuthoringResourceDefinition>,
    private val relations: Collection<RelationDefinition>,
    private val catalog: TypeCatalog,
    private val rules: Collection<AuthoringGraphRule> = emptyList(),
) {
    fun plan(
        before: AuthoringWorkingGraph,
        operations: List<AuthoringOperation>,
    ): AuthoringMutationPlanResult {
        if (operations.isEmpty()) {
            return AuthoringMutationPlanResult.Invalid(listOf(AuthoringDiagnostic("empty-authoring-batch")))
        }
        val duplicateIds =
            operations
                .mapNotNull(AuthoringOperation::directResourceId)
                .groupingBy { it }
                .eachCount()
                .filterValues { it > 1 }
                .keys
        if (duplicateIds.isNotEmpty()) {
            return AuthoringMutationPlanResult.Invalid(
                duplicateIds.map { AuthoringDiagnostic("duplicate-resource-operation", resource = it) },
            )
        }

        return try {
            val workingResources = before.resources.toMutableMap()
            val workingRelations = before.relations.toMutableMap()
            val upserts = linkedMapOf<ResourceId, DecomposedResourceValue>()
            val creates = linkedSetOf<ResourceId>()
            val plannedOperations = operations
            val resourceOperations =
                plannedOperations.filterNot {
                    it is AuthoringOperation.DeclareRelation || it is AuthoringOperation.RemoveRelation
                }
            val directWrites =
                resourceOperations
                    .filterNot { it is AuthoringOperation.DeleteResource }
                    .mapNotNullTo(linkedSetOf(), AuthoringOperation::directResourceId)

            resourceOperations
                .filterNot { it is AuthoringOperation.DeleteResource }
                .sortedBy { requireNotNull(it.directResourceId).value }
                .forEach { operation ->
                    when (operation) {
                        is AuthoringOperation.CreateResource -> {
                            create(operation, workingResources, workingRelations, upserts, creates)
                        }

                        is AuthoringOperation.CommitResource -> {
                            commit(operation, before, workingResources, workingRelations, upserts)
                        }

                        is AuthoringOperation.DeleteResource -> {
                            error("Delete operations are planned in the closure phase.")
                        }

                        is AuthoringOperation.DeclareRelation -> {
                            error("Relation operations are planned after resource writes.")
                        }

                        is AuthoringOperation.RemoveRelation -> {
                            error("Relation operations are planned after resource writes.")
                        }
                    }
                }
            plannedOperations
                .filterIsInstance<AuthoringOperation.CreateResource>()
                .sortedBy { it.id.value }
                .forEach { operation -> attachCreation(operation, workingResources, workingRelations) }
            plannedOperations
                .filterIsInstance<AuthoringOperation.DeclareRelation>()
                .forEach { operation ->
                    declareRelation(operation, workingResources, workingRelations)
                }
            plannedOperations
                .filterIsInstance<AuthoringOperation.RemoveRelation>()
                .sortedWith(compareBy({ it.relation.value }, { it.source.value }, { it.target.value }))
                .forEach { operation -> removeRelation(operation, workingRelations) }

            plannedOperations
                .filterIsInstance<AuthoringOperation.DeleteResource>()
                .forEach { operation -> validateDeleteBase(operation, before) }

            val deletion =
                resolveDeleteClosure(
                    resources = workingResources,
                    relationsById = workingRelations,
                    requested =
                        plannedOperations
                            .filterIsInstance<AuthoringOperation.DeleteResource>()
                            .mapTo(linkedSetOf()) { it.id },
                )
            val overlap = deletion intersect directWrites
            if (overlap.isNotEmpty()) return invalid("delete-overlaps-direct-write", overlap)
            deletion.forEach { id ->
                workingResources.remove(id)
                upserts.remove(id)
            }
            workingRelations.entries.removeIf { (_, relation) -> relation.source in deletion || relation.target in deletion }

            validateGraph(workingResources, workingRelations)
            val proposed = AuthoringWorkingGraph(workingResources.toMap(), workingRelations.toMap())
            val changedResources = changedResources(before, proposed, directWrites, deletion)
            val changedEdges = changedEdges(before, proposed)
            val ruleRoots =
                buildSet {
                    addAll(changedResources)
                    changedEdges.forEach { edgeId ->
                        listOfNotNull(before.relations[edgeId], proposed.relations[edgeId]).forEach { relation ->
                            add(relation.source)
                            add(relation.target)
                        }
                    }
                }
            val ruleDiagnostics =
                rules.flatMap { rule ->
                    rule.validate(
                        AuthoringGraphValidationContext(
                            before = before.policySlice(ruleRoots, rule.graphRequirement, rule.id),
                            proposed = proposed.policySlice(ruleRoots, rule.graphRequirement, rule.id),
                            changedResources = changedResources,
                            changedEdges = changedEdges,
                            deletedResources = deletion,
                        ),
                    )
                }
            if (ruleDiagnostics.isNotEmpty()) return AuthoringMutationPlanResult.Invalid(ruleDiagnostics)

            val delta =
                AuthoringGraphDelta(
                    resourceUpserts = upserts.filterKeys { it in proposed.resources },
                    resourceCreates = creates,
                    resourceRemovals = deletion,
                    relationUpserts = proposed.relations.filter { (id, relation) -> before.relations[id] != relation },
                    relationRemovals = before.relations.keys - proposed.relations.keys,
                    relationUpdates = before.relations.keys intersect proposed.relations.keys,
                )
            AuthoringMutationPlanResult.Valid(
                AuthoringMutationPlan(before, proposed, delta, changedResources, changedEdges),
            )
        } catch (failure: AuthoringPlanFailure) {
            failure.result
        } catch (failure: IllegalArgumentException) {
            AuthoringMutationPlanResult.Invalid(
                listOf(
                    AuthoringDiagnostic(
                        code = "invalid-authored-value",
                        message = failure.message ?: "The authored value is invalid.",
                    ),
                ),
            )
        }
    }

    private fun create(
        operation: AuthoringOperation.CreateResource,
        resources: MutableMap<ResourceId, StoredTypedResource>,
        relationsById: MutableMap<String, StoredResourceRelation>,
        upserts: MutableMap<ResourceId, DecomposedResourceValue>,
        creates: MutableSet<ResourceId>,
    ) {
        val root =
            (operation.content.rootType as? TypeExpression.Named)?.reference
                ?: invalid("authored-root-must-be-named", operation.id)
        requireDefinition(operation.definition, operation.content.rootType, operation.id)
        if (catalog.definitions.singleOrNull { it.id == root }?.kind != NominalTypeKind.CONCRETE) {
            invalid("resource-root-not-concrete", operation.id)
        }
        if (resources.containsKey(operation.id)) invalid("resource-already-exists", operation.id)
        val content = bindCreationInverse(operation, root)
        mapper.validate(content)
        val value = mapper.decompose(operation.id, operation.definition, content)
        resources[operation.id] = value.resource
        replaceOwnedRelations(operation.id, null, value, relationsById)
        upserts[operation.id] = value
        creates += operation.id
    }

    private fun bindCreationInverse(
        operation: AuthoringOperation.CreateResource,
        root: com.typewritermc.types.ResolvedTypeRef,
    ): TypedValueEnvelope {
        val attachment = operation.attachment ?: return operation.content
        val definition = relations.singleOrNull { it.id == attachment.relation }
            ?: invalid("relation-definition-unsupported", operation.id)
        val childSide = if (attachment.hostSide == RelationEndpointSide.SOURCE)
            RelationEndpointSide.TARGET else RelationEndpointSide.SOURCE
        val inverse = catalog.effectiveRelationField(root, definition, childSide) ?: return operation.content
        val current = operation.content.rootValue.at(inverse.path)
        val bound = when (inverse.cardinality) {
            com.typewritermc.types.RelationCardinality.ONE -> when (current) {
                DataValue.Unit -> DataValue.Reference(attachment.host)
                is DataValue.Reference -> {
                    if (current.id != attachment.host) invalid("creation-inverse-mismatch", operation.id)
                    current
                }
                else -> invalid("creation-inverse-invalid", operation.id)
            }
            com.typewritermc.types.RelationCardinality.MANY -> {
                val values = (current as? DataValue.ListValue)?.values.orEmpty()
                if (values.any { (it as? DataValue.Reference)?.id == attachment.host }) current
                else DataValue.ListValue(values + DataValue.Reference(attachment.host))
            }
        }
        return operation.content.copy(rootValue = operation.content.rootValue.set(inverse.path, bound))
    }

    private fun attachCreation(
        operation: AuthoringOperation.CreateResource,
        resources: Map<ResourceId, StoredTypedResource>,
        relationsById: MutableMap<String, StoredResourceRelation>,
    ) {
        val attachment = operation.attachment ?: return
        val host = resources[attachment.host] ?: invalid("creation-host-not-found", attachment.host)
        val created = resources.getValue(operation.id)
        val definition = relations.singleOrNull { it.id == attachment.relation }
            ?: invalid("relation-definition-unsupported", operation.id)
        val field = catalog.effectiveRelationField(host.root, definition, attachment.hostSide)
            ?: invalid("creation-host-field-missing", host.id)
        if (!catalog.isAssignable(TypeExpression.Named(created.root), TypeExpression.Named(field.oppositeType))) {
            invalid("creation-target-type-mismatch", operation.id)
        }
        val source = if (attachment.hostSide == RelationEndpointSide.SOURCE) host.id else operation.id
        val target = if (attachment.hostSide == RelationEndpointSide.SOURCE) operation.id else host.id
        val relation = mapper.declaredRelation(attachment.relation, source, target)
        val existing = relationsById[relation.id]
        val origin = existing?.origin as? ResourceRelationOrigin.Declared
        val hasHostPosition = if (attachment.hostSide == RelationEndpointSide.SOURCE)
            origin?.sourceIndex != null else origin?.targetIndex != null
        if (!hasHostPosition) relationsById.remove(relation.id)
        val hostPosition = if (hasHostPosition) null else insertPosition(
            relationsById, definition, attachment.hostSide, host.id, null,
        )
        val updatedOrigin = (origin ?: ResourceRelationOrigin.Declared(attachment.relation)).let {
            if (attachment.hostSide == RelationEndpointSide.SOURCE) it.copy(sourceIndex = hostPosition ?: it.sourceIndex)
            else it.copy(targetIndex = hostPosition ?: it.targetIndex)
        }
        relationsById[relation.id] = relation.copy(origin = updatedOrigin)
    }

    private fun commit(
        operation: AuthoringOperation.CommitResource,
        before: AuthoringWorkingGraph,
        resources: MutableMap<ResourceId, StoredTypedResource>,
        relationsById: MutableMap<String, StoredResourceRelation>,
        upserts: MutableMap<ResourceId, DecomposedResourceValue>,
    ) {
        if (operation.changedPaths.distinct().size != operation.changedPaths.size) {
            invalid("duplicate-changed-path", operation.id)
        }
        val stored = before.resources[operation.id] ?: invalid("resource-not-found", operation.id)
        requireDefinition(stored.definition, operation.proposed.rootType, operation.id)
        val current = mapper.hydrate(stored, before.relations.values)
        if (current.rootType != operation.base.rootType) invalid("resource-type-changed", operation.id)
        val merged = merge(operation, current)
        mapper.validate(merged)
        val value = mapper.decompose(operation.id, stored.definition, merged)
        resources[operation.id] = value.resource
        replaceOwnedRelations(operation.id, stored, value, relationsById)
        upserts[operation.id] = value
    }

    private fun requireDefinition(
        id: ResourceDefinitionId,
        root: TypeExpression,
        resource: ResourceId,
    ) {
        val definition = resourceDefinitions.singleOrNull { it.id == id } ?: invalid("resource-definition-unsupported", resource)
        if (!catalog.isAssignable(root, definition.acceptedRoot)) invalid("resource-definition-mismatch", resource)
    }

    private fun validateDeleteBase(
        operation: AuthoringOperation.DeleteResource,
        before: AuthoringWorkingGraph,
    ) {
        val stored = before.resources[operation.id] ?: invalid("resource-not-found", operation.id)
        val current = mapper.hydrate(stored, before.relations.values)
        if (current != operation.base) invalid("resource-changed", operation.id)
    }

    private fun declareRelation(
        operation: AuthoringOperation.DeclareRelation,
        resources: Map<ResourceId, StoredTypedResource>,
        relationsById: MutableMap<String, StoredResourceRelation>,
    ) {
        if (operation.source !in resources) invalid("relation-source-not-found", operation.source)
        if (operation.target !in resources) invalid("relation-target-not-found", operation.target)
        val definition = relations.singleOrNull { it.id == operation.relation }
            ?: invalid("relation-definition-unsupported", operation.source)
        val relation = mapper.declaredRelation(operation.relation, operation.source, operation.target)
        if (relation.id in relationsById) invalid("relation-already-exists", operation.source)
        val sourceIndex =
            insertPosition(
                relationsById,
                definition,
                RelationEndpointSide.SOURCE,
                operation.source,
                operation.sourceBefore,
            )
        val targetIndex =
            insertPosition(
                relationsById,
                definition,
                RelationEndpointSide.TARGET,
                operation.target,
                operation.targetBefore,
            )
        relationsById[relation.id] = relation.copy(
            origin = ResourceRelationOrigin.Declared(operation.relation, sourceIndex, targetIndex),
        )
    }

    private fun removeRelation(
        operation: AuthoringOperation.RemoveRelation,
        relationsById: MutableMap<String, StoredResourceRelation>,
    ) {
        val definition = relations.singleOrNull { it.id == operation.relation }
            ?: invalid("relation-definition-unsupported", operation.source)
        val relation = mapper.declaredRelation(operation.relation, operation.source, operation.target)
        val current = relationsById[relation.id] ?: invalid("relation-not-found", operation.source)
        if (current.source != relation.source || current.target != relation.target ||
            (current.origin as? ResourceRelationOrigin.Declared)?.relationId != operation.relation
        ) invalid("relation-mismatch", operation.source)
        relationsById.remove(relation.id)
        closePosition(relationsById, definition, RelationEndpointSide.SOURCE, operation.source,
            (current.origin as ResourceRelationOrigin.Declared).sourceIndex)
        closePosition(relationsById, definition, RelationEndpointSide.TARGET, operation.target,
            (current.origin as ResourceRelationOrigin.Declared).targetIndex)
    }

    private fun insertPosition(
        relationsById: MutableMap<String, StoredResourceRelation>,
        definition: RelationDefinition,
        side: RelationEndpointSide,
        owner: ResourceId,
        before: ResourceId?,
    ): Int? {
        val endpoint = if (side == RelationEndpointSide.SOURCE) definition.sourceEndpoint else definition.targetEndpoint
        if (endpoint?.cardinality != com.typewritermc.types.RelationCardinality.MANY) {
            if (before != null) invalid("relation-insertion-anchor-unsupported", owner)
            return null
        }
        val existing = relationsById.values.filter { edge ->
            (edge.origin as? ResourceRelationOrigin.Declared)?.relationId == definition.id &&
                if (side == RelationEndpointSide.SOURCE) edge.source == owner else edge.target == owner
        }
        val position =
            if (before == null) existing.size
            else existing.singleOrNull { edge ->
                if (side == RelationEndpointSide.SOURCE) edge.target == before else edge.source == before
            }?.let { edge ->
                val origin = edge.origin as ResourceRelationOrigin.Declared
                if (side == RelationEndpointSide.SOURCE) origin.sourceIndex else origin.targetIndex
            } ?: invalid("relation-insertion-anchor-not-found", owner)
        existing.toList().forEach { edge ->
            val origin = edge.origin as ResourceRelationOrigin.Declared
            val current = (if (side == RelationEndpointSide.SOURCE) origin.sourceIndex else origin.targetIndex)
                ?: invalid("relation-order-missing", owner)
            if (current >= position) {
                relationsById[edge.id] = edge.copy(origin = if (side == RelationEndpointSide.SOURCE)
                    origin.copy(sourceIndex = current + 1) else origin.copy(targetIndex = current + 1))
            }
        }
        return position
    }

    private fun closePosition(
        relationsById: MutableMap<String, StoredResourceRelation>,
        definition: RelationDefinition,
        side: RelationEndpointSide,
        owner: ResourceId,
        removed: Int?,
    ) {
        val endpoint = if (side == RelationEndpointSide.SOURCE) definition.sourceEndpoint else definition.targetEndpoint
        if (endpoint?.cardinality != com.typewritermc.types.RelationCardinality.MANY) return
        val position = removed ?: invalid("relation-order-missing", owner)
        relationsById.values.filter { edge ->
            (edge.origin as? ResourceRelationOrigin.Declared)?.relationId == definition.id &&
                if (side == RelationEndpointSide.SOURCE) edge.source == owner else edge.target == owner
        }.toList().forEach { edge ->
            val origin = edge.origin as ResourceRelationOrigin.Declared
            val current = (if (side == RelationEndpointSide.SOURCE) origin.sourceIndex else origin.targetIndex)
                ?: invalid("relation-order-missing", owner)
            if (current > position) {
                relationsById[edge.id] = edge.copy(origin = if (side == RelationEndpointSide.SOURCE)
                    origin.copy(sourceIndex = current - 1) else origin.copy(targetIndex = current - 1))
            }
        }
    }

    private fun replaceOwnedRelations(
        id: ResourceId,
        old: StoredTypedResource?,
        value: DecomposedResourceValue,
        relationsById: MutableMap<String, StoredResourceRelation>,
    ) {
        val owned =
            buildSet {
                addAll(old?.let { mapper.ownedRelationEndpoints(it.root) }.orEmpty())
                addAll(mapper.ownedRelationEndpoints(value.resource.root))
            }
        val existing = relationsById.toMap()
        relationsById.entries.removeIf { (_, relation) ->
            when (val origin = relation.origin) {
                is ResourceRelationOrigin.Reference -> {
                    relation.source == id
                }

                is ResourceRelationOrigin.Declared -> {
                    when {
                        relation.source == id -> (origin.relationId to RelationEndpointSide.SOURCE) in owned
                        relation.target == id -> (origin.relationId to RelationEndpointSide.TARGET) in owned
                        else -> false
                    }
                }
            }
        }
        value.relations.forEach { relation ->
            val previous = existing[relation.id]
            val newOrigin = relation.origin as? ResourceRelationOrigin.Declared
            val oldOrigin = previous?.origin as? ResourceRelationOrigin.Declared
            val merged =
                if (newOrigin != null && oldOrigin != null) {
                    relation.copy(
                        origin =
                            newOrigin.copy(
                                sourceIndex =
                                    if (relation.source == id && (newOrigin.relationId to RelationEndpointSide.SOURCE) in owned) {
                                        newOrigin.sourceIndex
                                    } else {
                                        oldOrigin.sourceIndex
                                    },
                                targetIndex =
                                    if (relation.target == id && (newOrigin.relationId to RelationEndpointSide.TARGET) in owned) {
                                        newOrigin.targetIndex
                                    } else {
                                        oldOrigin.targetIndex
                                    },
                            ),
                    )
                } else {
                    relation
                }
            relationsById[relation.id] = merged
        }
    }

    private fun resolveDeleteClosure(
        resources: Map<ResourceId, StoredTypedResource>,
        relationsById: Map<String, StoredResourceRelation>,
        requested: Set<ResourceId>,
    ): Set<ResourceId> {
        if (requested.any { it !in resources }) invalid("resource-not-found", requested.first { it !in resources })
        val deleting = requested.toMutableSet()
        val pending = ArrayDeque(requested.sortedBy(ResourceId::value))
        while (pending.isNotEmpty()) {
            val id = pending.removeFirst()
            relationsById.values.filter { it.source == id || it.target == id }.forEach { relation ->
                val origin = relation.origin as? ResourceRelationOrigin.Declared ?: return@forEach
                val definition =
                    relations.singleOrNull { it.id == origin.relationId }
                        ?: invalid("relation-definition-unsupported", id)
                val sourceDeleted = relation.source == id
                val policy = if (sourceDeleted) definition.onSourceDelete else definition.onTargetDelete
                if (policy == RelationDeletePolicy.CASCADE) {
                    val opposite = if (sourceDeleted) relation.target else relation.source
                    if (opposite !in resources) invalid("relation-endpoint-not-found", id)
                    if (deleting.add(opposite)) pending.addLast(opposite)
                }
            }
        }
        relationsById.values.forEach { relation ->
            if (relation.source !in deleting && relation.target !in deleting) return@forEach
            when (val origin = relation.origin) {
                is ResourceRelationOrigin.Reference -> {
                    if (relation.target in deleting && relation.source !in deleting) invalid("resource-referenced", relation.target)
                }

                is ResourceRelationOrigin.Declared -> {
                    val definition =
                        relations.singleOrNull { it.id == origin.relationId }
                            ?: invalid("relation-definition-unsupported", relation.source)
                    val sourceDeleted = relation.source in deleting
                    val opposite = if (sourceDeleted) relation.target else relation.source
                    val policy = if (sourceDeleted) definition.onSourceDelete else definition.onTargetDelete
                    if (policy == RelationDeletePolicy.RESTRICT && opposite !in deleting) {
                        invalid("relation-restricts-delete", if (sourceDeleted) relation.source else relation.target)
                    }
                }
            }
        }
        return deleting
    }

    private fun validateGraph(
        resources: Map<ResourceId, StoredTypedResource>,
        relationsById: Map<String, StoredResourceRelation>,
    ) {
        relationsById.values.forEach { relation ->
            val source = resources[relation.source] ?: invalid("relation-source-not-found", relation.source)
            val target = resources[relation.target] ?: invalid("relation-target-not-found", relation.target)
            when (val origin = relation.origin) {
                is ResourceRelationOrigin.Reference -> {
                    if (!catalog.isAssignable(TypeExpression.Named(target.root), origin.expectedTarget)) {
                        invalid("reference-target-type-mismatch", relation.source)
                    }
                }

                is ResourceRelationOrigin.Declared -> {
                    val definition =
                        relations.singleOrNull { it.id == origin.relationId }
                            ?: invalid("relation-definition-unsupported", relation.source)
                    if (!catalog.isAssignable(TypeExpression.Named(source.root), TypeExpression.Named(definition.source))) {
                        invalid("relation-source-mismatch", source.id)
                    }
                    if (!catalog.isAssignable(TypeExpression.Named(target.root), TypeExpression.Named(definition.target))) {
                        invalid("relation-target-mismatch", target.id)
                    }
                    definition.sourceEndpoint?.let {
                        val field = catalog.effectiveRelationField(source.root, definition, RelationEndpointSide.SOURCE)
                            ?: invalid("relation-source-field-missing", source.id)
                        if (!catalog.isAssignable(TypeExpression.Named(target.root), TypeExpression.Named(field.oppositeType))) {
                            invalid("relation-field-type-mismatch", target.id)
                        }
                    }
                    definition.targetEndpoint?.let {
                        val field = catalog.effectiveRelationField(target.root, definition, RelationEndpointSide.TARGET)
                            ?: invalid("relation-target-field-missing", target.id)
                        if (!catalog.isAssignable(TypeExpression.Named(source.root), TypeExpression.Named(field.oppositeType))) {
                            invalid("relation-field-type-mismatch", source.id)
                        }
                    }
                }
            }
        }
        relations.forEach { definition ->
            validateEndpointCardinality(definition, RelationEndpointSide.SOURCE, resources, relationsById)
            validateEndpointCardinality(definition, RelationEndpointSide.TARGET, resources, relationsById)
            validateEndpointOrder(definition, RelationEndpointSide.SOURCE, resources, relationsById)
            validateEndpointOrder(definition, RelationEndpointSide.TARGET, resources, relationsById)
        }
        validateOwnership(resources, relationsById)
    }

    private fun validateEndpointOrder(
        definition: RelationDefinition,
        side: RelationEndpointSide,
        resources: Map<ResourceId, StoredTypedResource>,
        relationsById: Map<String, StoredResourceRelation>,
    ) {
        val endpoint = if (side == RelationEndpointSide.SOURCE) definition.sourceEndpoint else definition.targetEndpoint
        val grouped = relationsById.values
            .filter { (it.origin as? ResourceRelationOrigin.Declared)?.relationId == definition.id }
            .groupBy { if (side == RelationEndpointSide.SOURCE) it.source else it.target }
        grouped.forEach { (ownerId, edges) ->
            val owner = resources[ownerId] ?: invalid("relation-endpoint-not-found", ownerId)
            val applies = endpoint != null && catalog.isAssignable(
                TypeExpression.Named(owner.root), TypeExpression.Named(endpoint.owner),
            )
            val positions = edges.map { edge ->
                val origin = edge.origin as ResourceRelationOrigin.Declared
                if (side == RelationEndpointSide.SOURCE) origin.sourceIndex else origin.targetIndex
            }
            if (applies && endpoint!!.cardinality == com.typewritermc.types.RelationCardinality.MANY) {
                if (positions.sortedBy { it } != (0 until edges.size).toList()) {
                    invalid("relation-order-invalid", ownerId)
                }
            } else if (positions.any { it != null }) {
                invalid("relation-order-unexpected", ownerId)
            }
        }
    }

    private fun validateOwnership(
        resources: Map<ResourceId, StoredTypedResource>,
        relationsById: Map<String, StoredResourceRelation>,
    ) {
        val ownership = relations.filter { RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID) in it.families }
        if (ownership.isEmpty()) return
        val relationIds = ownership.mapTo(hashSetOf(), RelationDefinition::id)
        val owners =
            relationsById.values
                .filter { (it.origin as? ResourceRelationOrigin.Declared)?.relationId in relationIds }
                .groupBy(StoredResourceRelation::target)
        resources.values.forEach { resource ->
            val needsOwner = ownership.any { definition ->
                catalog.isAssignable(TypeExpression.Named(resource.root), TypeExpression.Named(definition.target))
            }
            if (!needsOwner) return@forEach
            if (owners[resource.id].orEmpty().size != 1) invalid("resource-owner-count", resource.id)
        }
        resources.keys.forEach { resource ->
            val visited = hashSetOf<ResourceId>()
            var current: ResourceId? = resource
            while (current != null) {
                if (!visited.add(current)) invalid("resource-ownership-cycle", resource)
                current = owners[current]?.singleOrNull()?.source
            }
        }
    }

    private fun validateEndpointCardinality(
        definition: RelationDefinition,
        side: RelationEndpointSide,
        resources: Map<ResourceId, StoredTypedResource>,
        relationsById: Map<String, StoredResourceRelation>,
    ) {
        val endpoint =
            when (side) {
                RelationEndpointSide.SOURCE -> definition.sourceEndpoint
                RelationEndpointSide.TARGET -> definition.targetEndpoint
            } ?: return
        if (endpoint.cardinality != com.typewritermc.types.RelationCardinality.ONE) return
        val counts = resources.values
            .filter { resource ->
                catalog.isAssignable(
                    TypeExpression.Named(resource.root),
                    TypeExpression.Named(endpoint.owner),
                )
            }.associate { owner ->
                owner.id to
                    relationsById.values.count { relation ->
                        (relation.origin as? ResourceRelationOrigin.Declared)?.relationId == definition.id &&
                            when (side) {
                                RelationEndpointSide.SOURCE -> relation.source == owner.id
                                RelationEndpointSide.TARGET -> relation.target == owner.id
                            }
                    }
            }
        counts.entries.firstOrNull { it.value > 1 }?.let { invalid("relation-endpoint-cardinality-exceeded", it.key) }
        counts.entries.firstOrNull { it.value == 0 }?.let { invalid("relation-endpoint-required", it.key) }
    }

    private fun merge(
        operation: AuthoringOperation.CommitResource,
        current: TypedValueEnvelope,
    ): TypedValueEnvelope {
        if (current.rootType != operation.proposed.rootType) {
            if (operation.changedPaths != listOf(DataPath())) invalid("resource-type-change-requires-root-path", operation.id)
            if (current.rootValue !=
                operation.base.rootValue
            ) {
                conflict(operation.id, DataPath(), operation.base.rootValue, current.rootValue)
            }
            return operation.proposed
        }
        val root = current.rootType as? TypeExpression.Named ?: invalid("authored-root-must-be-named", operation.id)
        val graph = mapper.graph(root)
        val definition = graph.definitions.single { it.id == root.reference }
        val setPaths =
            definition.fieldMergePolicies.filter { it.strategy == FieldMergeStrategy.SET_MEMBERSHIP }.mapTo(
                linkedSetOf(),
            ) { it.path }
        var merged = current.rootValue
        operation.changedPaths.forEach { path ->
            val expected = operation.base.rootValue.at(path)
            val actual = merged.at(path)
            val proposed = operation.proposed.rootValue.at(path)
            val replacement =
                if (path in setPaths) {
                    mergeSet(expected, actual, proposed)
                } else {
                    when {
                        actual == expected -> proposed
                        actual == proposed -> actual
                        else -> conflict(operation.id, path, expected, actual)
                    }
                }
            merged = merged.set(path, replacement)
        }
        return TypedValueEnvelope(current.rootType, merged)
    }

    private fun changedResources(
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
        directWrites: Set<ResourceId>,
        deleted: Set<ResourceId>,
    ): Set<ResourceId> =
        buildSet {
            addAll(directWrites)
            addAll(deleted)
            before.relations.values.filter { it.id !in proposed.relations }.forEach {
                add(it.source)
                add(it.target)
            }
            proposed.relations.values.filter { before.relations[it.id] != it }.forEach {
                add(it.source)
                add(it.target)
            }
        }

    private fun changedEdges(
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
    ): Set<String> =
        buildSet {
            addAll(before.relations.keys - proposed.relations.keys)
            addAll(proposed.relations.filter { (id, relation) -> before.relations[id] != relation }.keys)
        }

    private fun AuthoringWorkingGraph.policySlice(
        roots: Set<ResourceId>,
        requirement: GraphReadRequirement,
        policyId: String,
    ): AuthoringWorkingGraph =
        when (val result = sliceForPolicy(roots, requirement)) {
            is PolicyGraphSliceResult.Success -> {
                result.graph
            }

            is PolicyGraphSliceResult.LimitExceeded -> {
                invalid(
                    "policy-graph-${result.dimension}-limit-exceeded",
                    message = "Policy $policyId exceeded its ${result.dimension} limit ${result.limit}.",
                )
            }
        }

    private fun invalid(
        code: String,
        resources: Collection<ResourceId> = emptyList(),
        message: String = code,
    ): Nothing =
        throw AuthoringPlanFailure(
            AuthoringMutationPlanResult.Invalid(
                resources
                    .map {
                        AuthoringDiagnostic(code, message, it)
                    }.ifEmpty { listOf(AuthoringDiagnostic(code, message)) },
            ),
        )

    private fun invalid(
        code: String,
        resource: ResourceId,
    ): Nothing = invalid(code, resources = listOf(resource))

    private fun conflict(
        resource: ResourceId,
        path: DataPath,
        expected: DataValue?,
        actual: DataValue?,
    ): Nothing =
        throw AuthoringPlanFailure(AuthoringMutationPlanResult.Conflict(listOf(PropertyConflict(resource, path, expected, actual))))
}

private class AuthoringPlanFailure(
    val result: AuthoringMutationPlanResult,
) : RuntimeException(null, null, false, false)

private fun mergeSet(
    base: DataValue,
    current: DataValue,
    proposed: DataValue,
): DataValue {
    val baseValues = (base as DataValue.ListValue).values.toSet()
    val currentValues = (current as DataValue.ListValue).values.toSet()
    val proposedValues = (proposed as DataValue.ListValue).values.toSet()
    val removed = baseValues - proposedValues
    val added = proposedValues - baseValues
    return DataValue.ListValue(((currentValues - removed) + added).sortedBy(DataValue::toString))
}

private fun DataValue.at(path: DataPath): DataValue =
    path.segments.fold(this) { value, segment ->
        when (segment) {
            is DataPathSegment.Field -> (value as DataValue.Record).fields.getValue(segment.name)
            is DataPathSegment.Index -> (value as DataValue.ListValue).values[segment.index]
            is DataPathSegment.MapKey -> (value as DataValue.MapValue).entries.single { it.key == segment.key }.value
        }
    }

private fun DataValue.set(
    path: DataPath,
    replacement: DataValue,
): DataValue {
    if (path.segments.isEmpty()) return replacement
    val head = path.segments.first()
    val tail = DataPath(path.segments.drop(1))
    return when (head) {
        is DataPathSegment.Field -> {
            val record = this as DataValue.Record
            record.copy(fields = record.fields + (head.name to record.fields.getValue(head.name).set(tail, replacement)))
        }

        is DataPathSegment.Index -> {
            val list = this as DataValue.ListValue
            list.copy(values = list.values.mapIndexed { index, value -> if (index == head.index) value.set(tail, replacement) else value })
        }

        is DataPathSegment.MapKey -> {
            val map = this as DataValue.MapValue
            map.copy(
                entries =
                    map.entries.map { entry ->
                        if (entry.key ==
                            head.key
                        ) {
                            entry.copy(value = entry.value.set(tail, replacement))
                        } else {
                            entry
                        }
                    },
            )
        }
    }
}
