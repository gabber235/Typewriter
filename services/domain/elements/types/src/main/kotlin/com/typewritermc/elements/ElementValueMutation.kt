package com.typewritermc.elements

import com.typewritermc.types.DataMapEntry
import com.typewritermc.types.DataValue
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ElementValuePath(
    val segments: List<ElementValuePathSegment> = emptyList(),
)

@Serializable
sealed interface ElementValuePathSegment {
    @Serializable
    @SerialName("field")
    data class Field(val name: String) : ElementValuePathSegment

    @Serializable
    @SerialName("index")
    data class Index(val index: Int) : ElementValuePathSegment

    @Serializable
    @SerialName("map_key")
    data class MapKey(val key: DataValue) : ElementValuePathSegment
}

@Serializable
sealed interface ElementValueMutation {
    val path: ElementValuePath

    @Serializable
    @SerialName("set_value")
    data class SetValue(
        override val path: ElementValuePath,
        val value: DataValue,
    ) : ElementValueMutation

    @Serializable
    @SerialName("insert_list_items")
    data class InsertListItems(
        override val path: ElementValuePath,
        val index: Int,
        val values: List<DataValue>,
    ) : ElementValueMutation

    @Serializable
    @SerialName("remove_list_items")
    data class RemoveListItems(
        override val path: ElementValuePath,
        val index: Int,
        val count: Int,
    ) : ElementValueMutation

    @Serializable
    @SerialName("reorder_list_items")
    data class ReorderListItems(
        override val path: ElementValuePath,
        val sourceIndex: Int,
        val count: Int,
        val destinationIndex: Int,
    ) : ElementValueMutation

    @Serializable
    @SerialName("duplicate_list_items")
    data class DuplicateListItems(
        override val path: ElementValuePath,
        val sourceIndex: Int,
        val count: Int,
        val destinationIndex: Int,
    ) : ElementValueMutation

    @Serializable
    @SerialName("put_map_entries")
    data class PutMapEntries(
        override val path: ElementValuePath,
        val entries: List<DataMapEntry>,
    ) : ElementValueMutation

    @Serializable
    @SerialName("remove_map_entries")
    data class RemoveMapEntries(
        override val path: ElementValuePath,
        val keys: List<DataValue>,
    ) : ElementValueMutation

    @Serializable
    @SerialName("replace_concrete_type")
    data class ReplaceConcreteType(
        override val path: ElementValuePath,
        val concreteType: ResolvedTypeRef,
        val value: DataValue,
    ) : ElementValueMutation
}

sealed interface ElementValueMutationResult {
    data class Success(val value: StoredElementValue) : ElementValueMutationResult

    data class Failure(val code: String) : ElementValueMutationResult
}

class ElementValueMutator(
    private val decomposer: ReferenceDecomposer = ReferenceDecomposer(),
) {
    fun apply(
        graph: TypeGraph,
        stored: StoredElementValue,
        mutations: List<ElementValueMutation>,
    ): ElementValueMutationResult {
        var current = stored
        for (mutation in mutations) {
            current = applyOne(graph, current, mutation) ?: return ElementValueMutationResult.Failure("invalid-value-mutation")
        }
        return ElementValueMutationResult.Success(current)
    }

    private fun applyOne(
        graph: TypeGraph,
        stored: StoredElementValue,
        mutation: ElementValueMutation,
    ): StoredElementValue? =
        runCatching {
            val logical = ReferenceAssembler().assemble(graph, stored).value
            val target = ValueTarget.resolve(graph, logical, stored.valueWithSlots, mutation.path)
            when (mutation) {
                is ElementValueMutation.SetValue -> replace(graph, stored, target, mutation.value)
                is ElementValueMutation.ReplaceConcreteType ->
                    replace(graph, stored, target, DataValue.Polymorphic(mutation.concreteType, mutation.value))
                is ElementValueMutation.InsertListItems -> insertList(graph, stored, target, mutation.index, mutation.values)
                is ElementValueMutation.RemoveListItems -> removeList(stored, target, mutation.index, mutation.count)
                is ElementValueMutation.ReorderListItems ->
                    reorderList(stored, target, mutation.sourceIndex, mutation.count, mutation.destinationIndex)
                is ElementValueMutation.DuplicateListItems ->
                    duplicateList(graph, stored, target, mutation.sourceIndex, mutation.count, mutation.destinationIndex)
                is ElementValueMutation.PutMapEntries -> putMap(graph, stored, target, mutation.entries)
                is ElementValueMutation.RemoveMapEntries -> removeMap(stored, target, mutation.keys)
            }
        }.getOrNull()

    private fun replace(
        graph: TypeGraph,
        stored: StoredElementValue,
        target: ValueTarget,
        logicalValue: DataValue,
    ): StoredElementValue {
        val projected = decomposer.decompose(graph, target.expression, logicalValue)
        return stored.replaceTarget(target, projected.valueWithSlots, projected.references)
    }

    private fun insertList(
        graph: TypeGraph,
        stored: StoredElementValue,
        target: ValueTarget,
        index: Int,
        values: List<DataValue>,
    ): StoredElementValue {
        val listType = target.expression.requireListType(graph, target.logical)
        val list = target.stored as DataValue.ListValue
        require(index in 0..list.values.size)
        val additions = values.map { decomposer.decompose(graph, listType.element, it) }
        val replacement = DataValue.ListValue(list.values.toMutableList().apply { addAll(index, additions.map { it.valueWithSlots }) })
        return stored.replaceTarget(target, replacement, target.references(stored) + additions.flatMap { it.references })
    }

    private fun removeList(
        stored: StoredElementValue,
        target: ValueTarget,
        index: Int,
        count: Int,
    ): StoredElementValue {
        val list = target.stored as DataValue.ListValue
        require(count > 0 && index >= 0 && index + count <= list.values.size)
        val replacement = DataValue.ListValue(list.values.toMutableList().apply { repeat(count) { removeAt(index) } })
        return stored.replaceTarget(target, replacement, target.references(stored, replacement))
    }

    private fun reorderList(
        stored: StoredElementValue,
        target: ValueTarget,
        sourceIndex: Int,
        count: Int,
        destinationIndex: Int,
    ): StoredElementValue {
        val list = target.stored as DataValue.ListValue
        require(count > 0 && sourceIndex >= 0 && sourceIndex + count <= list.values.size)
        require(destinationIndex >= 0)
        val values = list.values.toMutableList()
        val moved = values.subList(sourceIndex, sourceIndex + count).toList()
        repeat(count) { values.removeAt(sourceIndex) }
        require(destinationIndex in 0..values.size)
        values.addAll(destinationIndex, moved)
        val replacement = DataValue.ListValue(values)
        return stored.replaceTarget(target, replacement, target.references(stored))
    }

    private fun duplicateList(
        graph: TypeGraph,
        stored: StoredElementValue,
        target: ValueTarget,
        sourceIndex: Int,
        count: Int,
        destinationIndex: Int,
    ): StoredElementValue {
        val listType = target.expression.requireListType(graph, target.logical)
        val logical = target.logical as DataValue.ListValue
        require(count > 0 && sourceIndex >= 0 && sourceIndex + count <= logical.values.size)
        require(destinationIndex in 0..logical.values.size)
        return insertList(graph, stored, target, destinationIndex, logical.values.subList(sourceIndex, sourceIndex + count))
    }

    private fun putMap(
        graph: TypeGraph,
        stored: StoredElementValue,
        target: ValueTarget,
        entries: List<DataMapEntry>,
    ): StoredElementValue {
        val mapType = target.expression.requireMapType(graph, target.logical)
        val logical = target.logical as DataValue.MapValue
        val storedMap = target.stored as DataValue.MapValue
        val next = storedMap.entries.toMutableList()
        val logicalKeys = logical.entries.mapTo(mutableListOf()) { it.key }
        val retainedReferences = target.references(stored).toMutableList()
        entries.forEach { entry ->
            val existing = logicalKeys.indexOf(entry.key)
            if (existing >= 0) {
                val removedSlots = next[existing].slots()
                retainedReferences.removeAll { it.slot in removedSlots }
                next.removeAt(existing)
                logicalKeys.removeAt(existing)
            }
            val key = decomposer.decompose(graph, mapType.key, entry.key)
            val value = decomposer.decompose(graph, mapType.value, entry.value)
            next += DataMapEntry(key.valueWithSlots, value.valueWithSlots)
            logicalKeys += entry.key
            retainedReferences += key.references + value.references
        }
        return stored.replaceTarget(target, DataValue.MapValue(next), retainedReferences)
    }

    private fun removeMap(
        stored: StoredElementValue,
        target: ValueTarget,
        keys: List<DataValue>,
    ): StoredElementValue {
        val logical = target.logical as DataValue.MapValue
        val storedMap = target.stored as DataValue.MapValue
        val removed = logical.entries.mapIndexedNotNull { index, entry -> index.takeIf { entry.key in keys } }.toSet()
        require(removed.isNotEmpty())
        val replacement = DataValue.MapValue(storedMap.entries.filterIndexed { index, _ -> index !in removed })
        return stored.replaceTarget(target, replacement, target.references(stored, replacement))
    }
}

private data class ValueTarget(
    val expression: TypeExpression,
    val logical: DataValue,
    val stored: DataValue,
    val replace: (DataValue, DataValue) -> DataValue,
) {
    fun references(
        value: StoredElementValue,
        subtree: DataValue = stored,
    ): List<StoredReference> {
        val slots = subtree.slots()
        return value.references.filter { it.slot in slots }
    }

    companion object {
        fun resolve(
            graph: TypeGraph,
            logicalRoot: DataValue,
            storedRoot: DataValue,
            path: ElementValuePath,
        ): ValueTarget {
            var expression = graph.root
            var logical = logicalRoot
            var stored = storedRoot
            var replace: (DataValue, DataValue) -> DataValue = { _, replacement -> replacement }
            path.segments.forEach { segment ->
                val parentLogical = logical
                val parentStored = stored
                val parentReplace = replace
                val materialized = expression.materialize(graph, logical)
                when (segment) {
                    is ElementValuePathSegment.Field -> {
                        val recordType = materialized as TypeExpression.Record
                        expression = recordType.fields.single { it.name == segment.name }.type
                        logical = (logical as DataValue.Record).fields.getValue(segment.name)
                        stored = (stored as DataValue.Record).fields.getValue(segment.name)
                        replace = { root, replacement ->
                            parentReplace(root, parentStored.copy(fields = parentStored.fields + (segment.name to replacement)))
                        }
                    }
                    is ElementValuePathSegment.Index -> {
                        expression = (materialized as TypeExpression.ListType).element
                        logical = (logical as DataValue.ListValue).values[segment.index]
                        stored = (stored as DataValue.ListValue).values[segment.index]
                        replace = { root, replacement ->
                            val values = parentStored.values.toMutableList()
                            values[segment.index] = replacement
                            parentReplace(root, DataValue.ListValue(values))
                        }
                    }
                    is ElementValuePathSegment.MapKey -> {
                        val mapType = materialized as TypeExpression.MapType
                        val index = (logical as DataValue.MapValue).entries.indexOfFirst { it.key == segment.key }
                        require(index >= 0)
                        expression = mapType.value
                        logical = logical.entries[index].value
                        stored = (stored as DataValue.MapValue).entries[index].value
                        replace = { root, replacement ->
                            val entries = parentStored.entries.toMutableList()
                            entries[index] = entries[index].copy(value = replacement)
                            parentReplace(root, DataValue.MapValue(entries))
                        }
                    }
                }
            }
            return ValueTarget(expression.materialize(graph, logical), logical, stored, replace)
        }
    }
}

private fun StoredElementValue.replaceTarget(
    target: ValueTarget,
    replacement: DataValue,
    replacementReferences: List<StoredReference>,
): StoredElementValue {
    val removedSlots = target.stored.slots()
    return StoredElementValue(
        valueWithSlots = target.replace(valueWithSlots, replacement),
        references = references.filterNot { it.slot in removedSlots } + replacementReferences,
    )
}

private fun TypeExpression.requireListType(graph: TypeGraph, logical: DataValue): TypeExpression.ListType =
    materialize(graph, logical) as TypeExpression.ListType

private fun TypeExpression.requireMapType(graph: TypeGraph, logical: DataValue): TypeExpression.MapType =
    materialize(graph, logical) as TypeExpression.MapType

private fun TypeExpression.materialize(graph: TypeGraph, logical: DataValue): TypeExpression {
    var current = this
    val definitions = (StandardTypes.definitions + graph.definitions).associateBy { it.id.withArguments(emptyList()) }
    while (current is TypeExpression.Named) {
        val definition = definitions[current.reference.withArguments(emptyList())] ?: return current
        val bindings = definition.bind(current.reference.arguments)
        if (definition.kind != NominalTypeKind.CONCRETE) {
            current = TypeExpression.Named((logical as DataValue.Polymorphic).concreteType)
        } else {
            current = ProjectionContext(graph).materialize(definition.representation, bindings)
        }
    }
    return current
}

private val ReferenceAssemblyResult.value: DataValue
    get() = when (this) {
        is ReferenceAssemblyResult.Success -> value
        is ReferenceAssemblyResult.Failure -> value
    }

private fun DataValue.slots(): Set<ReferenceSlotId> =
    buildSet {
        fun visit(value: DataValue) {
            value.referenceSlotForMutation()?.let(::add)
            when (value) {
                is DataValue.ListValue -> value.values.forEach(::visit)
                is DataValue.MapValue -> value.entries.forEach { visit(it.key); visit(it.value) }
                is DataValue.Record -> value.fields.values.forEach(::visit)
                is DataValue.Polymorphic -> visit(value.value)
                else -> Unit
            }
        }
        visit(this@slots)
    }

private fun DataMapEntry.slots(): Set<ReferenceSlotId> = key.slots() + value.slots()

private fun DataValue.referenceSlotForMutation(): ReferenceSlotId? {
    val fields = (this as? DataValue.Record)?.fields ?: return null
    val kind = fields["_kind"] as? DataValue.StringValue ?: return null
    val slot = fields["slot"] as? DataValue.StringValue ?: return null
    return if (kind.value == "ref_slot") ReferenceSlotId(slot.value) else null
}
