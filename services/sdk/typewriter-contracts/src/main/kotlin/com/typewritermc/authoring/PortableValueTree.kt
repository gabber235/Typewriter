package com.typewritermc.authoring

import com.typewritermc.types.actualType
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.rows
import com.typewritermc.types.setValue
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.with
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ValuePath

sealed interface LocatedPortableValue {
    data class Value(
        val value: DataValue,
    ) : LocatedPortableValue

    data class Row(
        val row: MapRow,
    ) : LocatedPortableValue

    data class Missing(
        val traversed: ValuePath,
    ) : LocatedPortableValue

    data class Invalid(
        val traversed: ValuePath,
        val code: String,
    ) : LocatedPortableValue
}

sealed interface StructuralStep {
    val at: ValuePath

    data class Form(
        override val at: ValuePath,
    ) : StructuralStep

    data class Membership(
        override val at: ValuePath,
    ) : StructuralStep
}

data class LocatedValueNode(
    val path: ValuePath,
    val value: DataValue,
)

sealed interface ValueReplacement {
    data class Replaced(
        val value: DataValue,
    ) : ValueReplacement

    data class Unavailable(
        val at: ValuePath,
    ) : ValueReplacement
}

private const val MAXIMUM_VALUE_DEPTH = 512

private data class ValueVisit(
    val path: ValuePath,
    val value: DataValue,
    val depth: Int,
)

/**
 * Reads an identity based path through nominal wrappers, reporting structural observations for dependency tracking.
 * A map item selects a row; a following key or value segment selects that row's content. Missing content remains
 * distinct from traversing a value of the wrong form.
 */
fun DataValue.locate(
    path: ValuePath,
    onStep: (StructuralStep) -> Unit = {},
): LocatedPortableValue {
    var at = ValuePath.root
    var node: LocatedPortableValue = LocatedPortableValue.Value(this)
    for (segment in path.segments) {
        onStep(StructuralStep.Form(at))
        if (segment is PathSegment.ItemWrapper) onStep(StructuralStep.Membership(at))
        node = node.unwrap(at)
        if (node is LocatedPortableValue.Invalid) return node
        node = node.readChild(segment, at)
        if (node is LocatedPortableValue.Missing || node is LocatedPortableValue.Invalid) return node
        at = at.append(segment)
    }
    return node
}

/** Visits the root and its contents, preserving nominal wrappers at the same path and map key and value branches. */
fun DataValue.descendants(): Sequence<LocatedValueNode> =
    sequence {
        val pending = ArrayDeque<ValueVisit>()
        pending.addLast(ValueVisit(ValuePath.root, this@descendants, 0))
        while (pending.isNotEmpty()) {
            val visit = pending.removeLast()
            require(visit.depth <= MAXIMUM_VALUE_DEPTH) { "Portable value depth limit exceeded." }
            yield(LocatedValueNode(visit.path, visit.value))
            val children =
                when (val value = visit.value) {
                    is DataValue.NamedWrapper -> {
                        listOf(LocatedValueNode(visit.path, value.payload))
                    }

                    is DataValue.RecordWrapper -> {
                        value.fields.map { field ->
                            LocatedValueNode(visit.path.append(PathSegment.createField(name = field.name)), field.value)
                        }
                    }

                    is DataValue.ListValueWrapper -> {
                        value.items.map { item ->
                            LocatedValueNode(visit.path.append(PathSegment.createItem(id = item.id)), item.value)
                        }
                    }

                    is DataValue.SetValueWrapper -> {
                        value.items.map { item ->
                            LocatedValueNode(visit.path.append(PathSegment.createItem(id = item.id)), item.value)
                        }
                    }

                    is DataValue.MapValueWrapper -> {
                        value.rows.flatMap { row ->
                            val item = visit.path.append(PathSegment.createItem(id = row.id))
                            listOf(
                                LocatedValueNode(item.append(PathSegment.MAP_KEY), row.key),
                                LocatedValueNode(item.append(PathSegment.MAP_VALUE), row.value),
                            )
                        }
                    }

                    else -> {
                        emptyList()
                    }
                }
            children.asReversed().forEach { child ->
                pending.addLast(ValueVisit(child.path, child.value, visit.depth + 1))
            }
        }
    }

/** Replaces an existing value while preserving enclosing wrappers and collection identities. */
fun DataValue.replace(
    path: ValuePath,
    value: DataValue,
): ValueReplacement =
    rewrite(path.segments, 0) { existing -> existing?.let { value } }
        ?.let(ValueReplacement::Replaced)
        ?: ValueReplacement.Unavailable(path)

/** Allows insertion of a terminal record field, but requires every parent and collection item to already exist. */
fun DataValue.writeField(
    path: ValuePath,
    value: DataValue,
): ValueReplacement =
    rewrite(path.segments, 0) { value }
        ?.let(ValueReplacement::Replaced)
        ?: ValueReplacement.Unavailable(path)

private fun LocatedPortableValue.unwrap(at: ValuePath): LocatedPortableValue {
    var node = this
    var depth = 0
    while (node is LocatedPortableValue.Value && node.value is DataValue.NamedWrapper) {
        if (++depth > MAXIMUM_VALUE_DEPTH) return LocatedPortableValue.Invalid(at, "value_depth_limit")
        node = LocatedPortableValue.Value(node.value.payload)
    }
    return node
}

private fun LocatedPortableValue.readChild(
    segment: PathSegment,
    at: ValuePath,
): LocatedPortableValue {
    val next = at.append(segment)
    val value = (this as? LocatedPortableValue.Value)?.value
    return when (segment) {
        is PathSegment.FieldWrapper -> {
            when (value) {
                DataValue.UNFILLED,
                DataValue.NULL,
                -> {
                    LocatedPortableValue.Missing(next)
                }

                is DataValue.RecordWrapper -> {
                    value
                        .field(segment.name)
                        ?.let(LocatedPortableValue::Value)
                        ?: LocatedPortableValue.Missing(next)
                }

                else -> {
                    LocatedPortableValue.Invalid(at, "expected_record")
                }
            }
        }

        is PathSegment.ItemWrapper -> {
            when (value) {
                is DataValue.ListValueWrapper -> {
                    value.items
                        .singleOrNull { it.id == segment.id }
                        ?.let { LocatedPortableValue.Value(it.value) }
                        ?: LocatedPortableValue.Missing(next)
                }

                is DataValue.SetValueWrapper -> {
                    value.items
                        .singleOrNull { it.id == segment.id }
                        ?.let { LocatedPortableValue.Value(it.value) }
                        ?: LocatedPortableValue.Missing(next)
                }

                is DataValue.MapValueWrapper -> {
                    value.rows
                        .singleOrNull { it.id == segment.id }
                        ?.let(LocatedPortableValue::Row)
                        ?: LocatedPortableValue.Missing(next)
                }

                else -> {
                    LocatedPortableValue.Missing(next)
                }
            }
        }

        PathSegment.MAP_KEY -> {
            if (this is LocatedPortableValue.Row) {
                LocatedPortableValue.Value(row.key)
            } else {
                LocatedPortableValue.Invalid(at, "expected_map_row")
            }
        }

        PathSegment.MAP_VALUE -> {
            if (this is LocatedPortableValue.Row) {
                LocatedPortableValue.Value(row.value)
            } else {
                LocatedPortableValue.Invalid(at, "expected_map_row")
            }
        }

        else -> {
            unknownVariant(segment)
        }
    }
}

private fun DataValue.rewrite(
    path: List<PathSegment>,
    depth: Int,
    leaf: (DataValue?) -> DataValue?,
): DataValue? {
    if (depth > MAXIMUM_VALUE_DEPTH) return null
    if (path.isEmpty()) return leaf(this)
    if (this is DataValue.NamedWrapper) return DataValue.named(actualType, payload.rewrite(path, depth + 1, leaf) ?: return null)
    val tail = path.drop(1)
    return when (val segment = path.first()) {
        is PathSegment.FieldWrapper -> {
            val record = this as? DataValue.RecordWrapper ?: return null
            val previous = record.field(segment.name)
            val changed =
                if (tail.isEmpty()) {
                    leaf(previous)
                } else {
                    previous?.rewrite(tail, depth + 1, leaf)
                }
            DataValue.RecordWrapper(record.value.with(segment.name, changed ?: return null))
        }

        is PathSegment.ItemWrapper -> {
            when (this) {
                is DataValue.ListValueWrapper -> {
                    DataValue.listValue(items.rewriteItem(segment.id, tail, depth + 1, leaf) ?: return null)
                }

                is DataValue.SetValueWrapper -> {
                    DataValue.setValue(items.rewriteItem(segment.id, tail, depth + 1, leaf) ?: return null)
                }

                is DataValue.MapValueWrapper -> {
                    val index = rows.indexOfFirst { it.id == segment.id }
                    if (index < 0) return null
                    val row = rows[index]
                    val changed =
                        when (tail.firstOrNull()) {
                            PathSegment.MAP_KEY -> row.copy(key = row.key.rewrite(tail.drop(1), depth + 1, leaf) ?: return null)
                            PathSegment.MAP_VALUE -> row.copy(value = row.value.rewrite(tail.drop(1), depth + 1, leaf) ?: return null)
                            else -> return null
                        }
                    DataValue.mapValue(rows.toMutableList().also { it[index] = changed })
                }

                else -> {
                    null
                }
            }
        }

        PathSegment.MAP_KEY,
        PathSegment.MAP_VALUE,
        -> {
            null
        }

        else -> {
            unknownVariant(segment)
        }
    }
}

private fun List<ListItem>.rewriteItem(
    id: ItemId,
    tail: List<PathSegment>,
    depth: Int,
    leaf: (DataValue?) -> DataValue?,
): List<ListItem>? {
    val index = indexOfFirst { it.id == id }
    if (index < 0) return null
    val changed = this[index].value.rewrite(tail, depth, leaf) ?: return null
    return toMutableList().also { it[index] = this[index].copy(value = changed) }
}
