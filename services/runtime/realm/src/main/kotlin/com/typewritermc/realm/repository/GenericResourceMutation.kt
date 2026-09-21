package com.typewritermc.realm.repository

import com.surrealdb.Transaction
import com.typewritermc.realm.RealmResourceKindDefinition
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataPathSegment
import com.typewritermc.types.DataValue
import com.typewritermc.types.FieldMergeStrategy
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypedValueEnvelope

/** Executes generic resource mutations against the canonical resource graph. */
internal class GenericResourceMutation(
    private val transaction: Transaction,
    private val mapper: ResourceValueMapper,
    private val store: SurrealResourceGraphStore,
    private val resourceKinds: Collection<RealmResourceKindDefinition>,
    private val relations: Collection<RelationDefinition>,
    private val catalog: TypeCatalog,
) {
    val upserts = linkedMapOf<ResourceId, DecomposedResourceValue>()
    val removals = linkedSetOf<ResourceId>()
    val edgeUpserts = linkedMapOf<String, StoredResourceRelation>()
    val edgeRemovals = linkedSetOf<String>()
    val affectedResources = linkedSetOf<ResourceId>()

    fun create(operation: AuthoringOperation.CreateResource) {
        requireKind(operation.kind, operation.content.rootType)
        if (transaction.resourceExists(operation.id)) invalid("resource-already-exists", operation.id)
        val value = mapper.decompose(operation.id, operation.kind, operation.content)
        captureEdges { store.create(transaction, value) }
        upserts[operation.id] = value
    }

    fun commit(operation: AuthoringOperation.CommitResource) {
        if (operation.changedPaths.distinct().size != operation.changedPaths.size) {
            invalid("duplicate-changed-path", operation.id)
        }
        val stored =
            transaction.loadStoredResources().singleOrNull { it.id == operation.id }
                ?: invalid("resource-not-found", operation.id)
        requireKind(stored.kind, operation.proposed.rootType)
        val storedRelations = transaction.loadStoredRelations()
        val current = mapper.hydrate(stored, storedRelations)
        if (current.rootType != operation.base.rootType) invalid("resource-type-changed", operation.id)
        val merged = merge(operation, current)
        mapper.validate(merged)
        val value = mapper.decompose(operation.id, stored.kind, merged)
        captureEdges { store.replace(transaction, value) }
        upserts[operation.id] = value
    }

    fun delete(operation: AuthoringOperation.DeleteResource) {
        delete(operation.id, linkedSetOf())
    }

    private fun delete(
        id: ResourceId,
        deleting: MutableSet<ResourceId>,
    ) {
        if (!deleting.add(id)) return
        if (!transaction.resourceExists(id)) invalid("resource-not-found", id)
        val graphRelations = transaction.loadStoredRelations()
        graphRelations.filter { it.source == id || it.target == id }.forEach { edge ->
            when (val origin = edge.origin) {
                is ResourceRelationOrigin.Reference -> {
                    if (edge.target == id && edge.source !in deleting) {
                        invalid("resource-referenced", id)
                    }
                }

                is ResourceRelationOrigin.Declared -> {
                    val definition = relations.single { it.id == origin.relationId }
                    val sourceDeleted = edge.source == id
                    val policy = if (sourceDeleted) definition.onSourceDelete else definition.onTargetDelete
                    val opposite = if (sourceDeleted) edge.target else edge.source
                    when (policy) {
                        RelationDeletePolicy.RESTRICT -> if (opposite !in deleting) invalid("relation-restricts-delete", id)
                        RelationDeletePolicy.CASCADE -> delete(opposite, deleting)
                        RelationDeletePolicy.CLEAR -> Unit
                    }
                }
            }
        }
        captureEdges { store.delete(transaction, id) }
        removals += id
        upserts.remove(id)
    }

    private fun captureEdges(action: () -> Unit) {
        val before = transaction.loadStoredRelations().associateBy(StoredResourceRelation::id)
        action()
        val after = transaction.loadStoredRelations().associateBy(StoredResourceRelation::id)
        (before.keys - after.keys).forEach { id ->
            before.getValue(id).let { edge ->
                affectedResources += edge.source
                affectedResources += edge.target
            }
            edgeUpserts.remove(id)
            edgeRemovals += id
        }
        after.forEach { (id, edge) ->
            if (before[id] != edge) {
                affectedResources += edge.source
                affectedResources += edge.target
                edgeRemovals.remove(id)
                edgeUpserts[id] = edge
            }
        }
    }

    private fun merge(
        operation: AuthoringOperation.CommitResource,
        current: TypedValueEnvelope,
    ): TypedValueEnvelope {
        if (current.rootType != operation.proposed.rootType) {
            if (operation.changedPaths != listOf(DataPath())) {
                invalid("resource-type-change-requires-root-path", operation.id)
            }
            if (current.rootValue != operation.base.rootValue) {
                conflict(operation.id, DataPath(), operation.base.rootValue, current.rootValue)
            }
            return operation.proposed
        }
        val graph = mapperGraph(current.rootType)
        var merged = current.rootValue
        operation.changedPaths.forEach { path ->
            val expected = operation.base.rootValue.at(path)
            val actual = merged.at(path)
            val proposed = operation.proposed.rootValue.at(path)
            val replacement =
                if (graph.setMembershipPaths.contains(path)) {
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

    private fun mapperGraph(root: TypeExpression): MergeGraph {
        val named = root as? TypeExpression.Named ?: error("Authored resources require named roots.")
        val typeGraph = mapper.graph(root)
        val definition = typeGraph.definitions.single { it.id == named.reference }
        return MergeGraph(
            typeGraph,
            definition.fieldMergePolicies
                .filter { it.strategy == FieldMergeStrategy.SET_MEMBERSHIP }
                .mapTo(linkedSetOf()) { it.path },
        )
    }

    private fun requireKind(
        kind: AuthoringResourceKind,
        root: TypeExpression,
    ) {
        val definition =
            resourceKinds.singleOrNull { it.kind == kind }
                ?: invalid("resource-kind-unsupported")
        if (!catalog.isAssignable(root, definition.acceptedRoot)) invalid("resource-kind-mismatch")
    }

    private fun invalid(
        code: String,
        id: ResourceId? = null,
    ): Nothing =
        throw AuthoringRejected(
            AuthoringBatchResult.Invalid(
                listOf(AuthoringDiagnostic(code, code, id)),
            ),
        )

    private fun conflict(
        id: ResourceId,
        path: DataPath,
        expected: DataValue?,
        actual: DataValue?,
    ): Nothing =
        throw AuthoringRejected(
            AuthoringBatchResult.Conflict(
                listOf(
                    PropertyConflict(
                        id,
                        path,
                        expected,
                        actual,
                    ),
                ),
            ),
        )

    private fun DataValue.set(
        path: DataPath,
        value: DataValue,
    ): DataValue = replaceAt(path.segments, value)
}

private data class MergeGraph(
    val typeGraph: com.typewritermc.types.TypeGraph,
    val setMembershipPaths: Set<DataPath>,
)

private fun Transaction.resourceExists(id: ResourceId): Boolean =
    query("SELECT VALUE id FROM ONLY \$resource;", mapOf("resource" to id.unifiedSurrealId()))
        .take(0)
        .let { !it.isNone && !it.isNull }

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

private fun DataValue.replaceAt(
    segments: List<DataPathSegment>,
    replacement: DataValue,
): DataValue {
    if (segments.isEmpty()) return replacement
    val head = segments.first()
    val tail = segments.drop(1)
    return when (head) {
        is DataPathSegment.Field -> {
            val record = this as DataValue.Record
            record.copy(fields = record.fields + (head.name to record.fields.getValue(head.name).replaceAt(tail, replacement)))
        }

        is DataPathSegment.Index -> {
            val list = this as DataValue.ListValue
            list.copy(
                values = list.values.mapIndexed { index, item -> if (index == head.index) item.replaceAt(tail, replacement) else item },
            )
        }

        is DataPathSegment.MapKey -> {
            val map = this as DataValue.MapValue
            map.copy(
                entries =
                    map.entries.map { entry ->
                        if (entry.key == head.key) entry.copy(value = entry.value.replaceAt(tail, replacement)) else entry
                    },
            )
        }
    }
}
