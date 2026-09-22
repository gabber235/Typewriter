package com.typewritermc.realm.repository

import com.typewritermc.authoring.AuthoringCreationContext
import com.typewritermc.authoring.AuthoringCreationHostCardinality
import com.typewritermc.authoring.AuthoringCreationHostFilter
import com.typewritermc.authoring.AuthoringCreationRelationDirection
import com.typewritermc.authoring.AuthoringCreationSlotDefinition
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
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
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
    private val creationSlots: Collection<AuthoringCreationSlotDefinition>,
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
            val plannedOperations = operations.map(::materializeReferenceCreationContext)
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
                .forEach { operation ->
                    attachCreationContext(operation, workingResources, workingRelations)
                }
            plannedOperations
                .filterIsInstance<AuthoringOperation.DeclareRelation>()
                .sortedWith(compareBy({ it.relation.value }, { it.source.value }, { it.target.value }))
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

            plannedOperations.filterIsInstance<AuthoringOperation.CreateResource>().forEach { operation ->
                validateCreation(operation, workingResources, workingRelations)
            }
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
        val slot =
            creationSlots.singleOrNull { it.id == operation.creationSlot }
                ?: invalid("creation-slot-unsupported", operation.id)
        if (slot.creates != operation.definition) invalid("creation-slot-definition-mismatch", operation.id)
        val root =
            (operation.content.rootType as? TypeExpression.Named)?.reference
                ?: invalid("authored-root-must-be-named", operation.id)
        if (root !in slot.concreteRoots) invalid("creation-slot-root-mismatch", operation.id)
        if (operation.hosts.distinct().size != operation.hosts.size) invalid("duplicate-creation-host", operation.id)
        requireDefinition(operation.definition, operation.content.rootType, operation.id)
        if (resources.containsKey(operation.id)) invalid("resource-already-exists", operation.id)
        mapper.validate(operation.content)
        val value = mapper.decompose(operation.id, operation.definition, operation.content)
        resources[operation.id] = value.resource
        replaceOwnedRelations(operation.id, null, value, relationsById)
        upserts[operation.id] = value
        creates += operation.id
    }

    private fun materializeReferenceCreationContext(operation: AuthoringOperation): AuthoringOperation {
        if (operation !is AuthoringOperation.CreateResource) return operation
        val slot =
            creationSlots.singleOrNull { it.id == operation.creationSlot }
                ?: invalid("creation-slot-unsupported", operation.id)
        val context = slot.context as? AuthoringCreationContext.ReferencePath ?: return operation
        val hostValue =
            when (context.cardinality) {
                AuthoringCreationHostCardinality.EXACTLY_ONE -> {
                    if (operation.hosts.size != 1) invalid("creation-host-cardinality", operation.id)
                    DataValue.Reference(operation.hosts.single())
                }

                AuthoringCreationHostCardinality.ONE_OR_MORE -> {
                    if (operation.hosts.isEmpty()) invalid("creation-host-cardinality", operation.id)
                    DataValue.ListValue(operation.hosts.map(DataValue::Reference))
                }
            }
        return operation.copy(
            content =
                operation.content.copy(
                    rootValue = operation.content.rootValue.set(context.path, hostValue),
                ),
        )
    }

    private fun validateCreation(
        operation: AuthoringOperation.CreateResource,
        resources: Map<ResourceId, StoredTypedResource>,
        relationsById: Map<String, StoredResourceRelation>,
    ) {
        val slot = creationSlots.single { it.id == operation.creationSlot }
        when (val context = slot.context) {
            AuthoringCreationContext.Standalone -> {
                if (operation.hosts.isNotEmpty()) invalid("standalone-creation-has-hosts", operation.id)
            }

            is AuthoringCreationContext.DeclaredRelation -> {
                validateCreationHosts(operation, context.hosts, context.cardinality, resources)
                val attached =
                    relationsById.values
                        .asSequence()
                        .filter { relation ->
                            (relation.origin as? ResourceRelationOrigin.Declared)?.relationId == context.relation
                        }.mapNotNull { relation ->
                            when (context.direction) {
                                AuthoringCreationRelationDirection.OUTGOING -> {
                                    relation.target
                                        .takeIf { relation.source in operation.hosts && it == operation.id }
                                        ?.let { relation.source }
                                }

                                AuthoringCreationRelationDirection.INCOMING -> {
                                    relation.source
                                        .takeIf { relation.target in operation.hosts && it == operation.id }
                                        ?.let { relation.target }
                                }

                                AuthoringCreationRelationDirection.BOTH -> {
                                    when (operation.id) {
                                        relation.source -> relation.target
                                        relation.target -> relation.source
                                        else -> null
                                    }
                                }
                            }
                        }.toSet()
                if (attached != operation.hosts.toSet()) invalid("creation-relation-mismatch", operation.id)
            }

            is AuthoringCreationContext.ReferencePath -> {
                validateCreationHosts(operation, context.hosts, context.cardinality, resources)
                val attached =
                    relationsById.values
                        .asSequence()
                        .filter { relation ->
                            relation.source == operation.id &&
                                (relation.origin as? ResourceRelationOrigin.Reference)?.sourcePath == context.path
                        }.map(StoredResourceRelation::target)
                        .toSet()
                if (attached != operation.hosts.toSet()) invalid("creation-reference-mismatch", operation.id)
            }
        }
    }

    private fun attachCreationContext(
        operation: AuthoringOperation.CreateResource,
        resources: Map<ResourceId, StoredTypedResource>,
        relationsById: MutableMap<String, StoredResourceRelation>,
    ) {
        val slot = creationSlots.single { it.id == operation.creationSlot }
        val context = slot.context as? AuthoringCreationContext.DeclaredRelation ?: return
        validateCreationHosts(operation, context.hosts, context.cardinality, resources)
        if (context.direction == AuthoringCreationRelationDirection.BOTH) {
            invalid("creation-relation-direction-ambiguous", operation.id)
        }
        operation.hosts.forEach { host ->
            val relation =
                when (context.direction) {
                    AuthoringCreationRelationDirection.OUTGOING -> {
                        mapper.declaredRelation(context.relation, host, operation.id)
                    }

                    AuthoringCreationRelationDirection.INCOMING -> {
                        mapper.declaredRelation(context.relation, operation.id, host)
                    }

                    AuthoringCreationRelationDirection.BOTH -> {
                        error("Ambiguous creation directions are rejected before relation materialization.")
                    }
                }
            if (relation.id in relationsById) invalid("relation-already-exists", operation.id)
            relationsById[relation.id] = relation
        }
    }

    private fun validateCreationHosts(
        operation: AuthoringOperation.CreateResource,
        filter: AuthoringCreationHostFilter,
        cardinality: AuthoringCreationHostCardinality,
        resources: Map<ResourceId, StoredTypedResource>,
    ) {
        when (cardinality) {
            AuthoringCreationHostCardinality.EXACTLY_ONE -> {
                if (operation.hosts.size != 1) invalid("creation-host-cardinality", operation.id)
            }

            AuthoringCreationHostCardinality.ONE_OR_MORE -> {
                if (operation.hosts.isEmpty()) invalid("creation-host-cardinality", operation.id)
            }
        }
        operation.hosts.forEach { hostId ->
            val host = resources[hostId] ?: invalid("creation-host-not-found", hostId)
            if (filter.definitions.isNotEmpty() && host.definition !in filter.definitions) {
                invalid("creation-host-definition-mismatch", hostId)
            }
            val assignableTo = filter.assignableTo
            if (assignableTo != null && !catalog.isAssignable(TypeExpression.Named(host.root), assignableTo)) {
                invalid("creation-host-type-mismatch", hostId)
            }
        }
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
        if (relations.none { it.id == operation.relation }) {
            invalid("relation-definition-unsupported", operation.source)
        }
        val relation = mapper.declaredRelation(operation.relation, operation.source, operation.target)
        if (relation.id in relationsById) invalid("relation-already-exists", operation.source)
        relationsById[relation.id] = relation
    }

    private fun removeRelation(
        operation: AuthoringOperation.RemoveRelation,
        relationsById: MutableMap<String, StoredResourceRelation>,
    ) {
        if (relations.none { it.id == operation.relation }) {
            invalid("relation-definition-unsupported", operation.source)
        }
        val relation = mapper.declaredRelation(operation.relation, operation.source, operation.target)
        val current = relationsById[relation.id] ?: invalid("relation-not-found", operation.source)
        if (current != relation) invalid("relation-mismatch", operation.source)
        relationsById.remove(relation.id)
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
        value.relations.forEach { relation -> relationsById[relation.id] = relation }
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
                }
            }
        }
        relations.forEach { definition ->
            validateEndpointCardinality(definition, RelationEndpointSide.SOURCE, resources, relationsById)
            validateEndpointCardinality(definition, RelationEndpointSide.TARGET, resources, relationsById)
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
        resources.values
            .filter { resource ->
                catalog.isAssignable(
                    TypeExpression.Named(resource.root),
                    TypeExpression.Named(endpoint.owner),
                )
            }.forEach { owner ->
                val count =
                    relationsById.values.count { relation ->
                        (relation.origin as? ResourceRelationOrigin.Declared)?.relationId == definition.id &&
                            when (side) {
                                RelationEndpointSide.SOURCE -> relation.source == owner.id
                                RelationEndpointSide.TARGET -> relation.target == owner.id
                            }
                    }
                if (count > 1) invalid("relation-endpoint-cardinality-exceeded", owner.id)
            }
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
