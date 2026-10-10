package com.typewritermc.authoring

import com.typewritermc.types.DataValue
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow

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

private fun ValuePath.append(segment: PathSegment): ValuePath = copy(segments = segments + segment)

fun DataValue.locate(
    path: ValuePath,
    onStep: (StructuralStep) -> Unit = {},
): LocatedPortableValue {
    var at = ValuePath()
    var node: LocatedPortableValue = LocatedPortableValue.Value(this)
    for (segment in path.segments) {
        onStep(StructuralStep.Form(at))
        if (segment is PathSegment.Item) onStep(StructuralStep.Membership(at))
        node = node.unwrap(at)
        if (node is LocatedPortableValue.Invalid) return node
        node = node.readChild(segment, at)
        if (node is LocatedPortableValue.Missing || node is LocatedPortableValue.Invalid) return node
        at = at.append(segment)
    }
    return node
}

fun DataValue.descendants(): Sequence<LocatedValueNode> =
    sequence {
        val pending = ArrayDeque<ValueVisit>()
        pending.addLast(ValueVisit(ValuePath(), this@descendants, 0))
        while (pending.isNotEmpty()) {
            val visit = pending.removeLast()
            require(visit.depth <= MAXIMUM_VALUE_DEPTH) { "Portable value depth limit exceeded." }
            yield(LocatedValueNode(visit.path, visit.value))
            val children =
                when (val value = visit.value) {
                    is DataValue.Named -> {
                        listOf(LocatedValueNode(visit.path, value.payload))
                    }

                    is DataValue.Record -> {
                        value.fields.map { (name, child) ->
                            LocatedValueNode(visit.path.append(PathSegment.Field(name)), child)
                        }
                    }

                    is DataValue.ListValue -> {
                        value.items.map { item ->
                            LocatedValueNode(visit.path.append(PathSegment.Item(item.id)), item.value)
                        }
                    }

                    is DataValue.SetValue -> {
                        value.items.map { item ->
                            LocatedValueNode(visit.path.append(PathSegment.Item(item.id)), item.value)
                        }
                    }

                    is DataValue.MapValue -> {
                        value.rows.flatMap { row ->
                            val item = visit.path.append(PathSegment.Item(row.id))
                            listOf(
                                LocatedValueNode(item.append(PathSegment.MapKey), row.key),
                                LocatedValueNode(item.append(PathSegment.MapValue), row.value),
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

fun DataValue.replace(
    path: ValuePath,
    value: DataValue,
): ValueReplacement =
    rewrite(path.segments, 0) { existing -> existing?.let { value } }
        ?.let(ValueReplacement::Replaced)
        ?: ValueReplacement.Unavailable(path)

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
    while (node is LocatedPortableValue.Value && node.value is DataValue.Named) {
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
        is PathSegment.Field -> {
            when (value) {
                DataValue.Unfilled,
                DataValue.Null,
                -> {
                    LocatedPortableValue.Missing(next)
                }

                is DataValue.Record -> {
                    value.fields[segment.name]
                        ?.let(LocatedPortableValue::Value)
                        ?: LocatedPortableValue.Missing(next)
                }

                else -> {
                    LocatedPortableValue.Invalid(at, "expected_record")
                }
            }
        }

        is PathSegment.Item -> {
            when (value) {
                is DataValue.ListValue -> {
                    value.items
                        .singleOrNull { it.id == segment.id }
                        ?.let { LocatedPortableValue.Value(it.value) }
                        ?: LocatedPortableValue.Missing(next)
                }

                is DataValue.SetValue -> {
                    value.items
                        .singleOrNull { it.id == segment.id }
                        ?.let { LocatedPortableValue.Value(it.value) }
                        ?: LocatedPortableValue.Missing(next)
                }

                is DataValue.MapValue -> {
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

        PathSegment.MapKey -> {
            if (this is LocatedPortableValue.Row) {
                LocatedPortableValue.Value(row.key)
            } else {
                LocatedPortableValue.Invalid(at, "expected_map_row")
            }
        }

        PathSegment.MapValue -> {
            if (this is LocatedPortableValue.Row) {
                LocatedPortableValue.Value(row.value)
            } else {
                LocatedPortableValue.Invalid(at, "expected_map_row")
            }
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
    if (this is DataValue.Named) return copy(payload = payload.rewrite(path, depth + 1, leaf) ?: return null)
    val tail = path.drop(1)
    return when (val segment = path.first()) {
        is PathSegment.Field -> {
            val record = this as? DataValue.Record ?: return null
            val previous = record.fields[segment.name]
            val changed =
                if (tail.isEmpty()) {
                    leaf(previous)
                } else {
                    previous?.rewrite(tail, depth + 1, leaf)
                }
            record.copy(fields = record.fields + (segment.name to (changed ?: return null)))
        }

        is PathSegment.Item -> {
            when (this) {
                is DataValue.ListValue -> {
                    copy(items = items.rewriteItem(segment.id, tail, depth + 1, leaf) ?: return null)
                }

                is DataValue.SetValue -> {
                    copy(items = items.rewriteItem(segment.id, tail, depth + 1, leaf) ?: return null)
                }

                is DataValue.MapValue -> {
                    val index = rows.indexOfFirst { it.id == segment.id }
                    if (index < 0) return null
                    val row = rows[index]
                    val changed =
                        when (tail.firstOrNull()) {
                            PathSegment.MapKey -> row.copy(key = row.key.rewrite(tail.drop(1), depth + 1, leaf) ?: return null)
                            PathSegment.MapValue -> row.copy(value = row.value.rewrite(tail.drop(1), depth + 1, leaf) ?: return null)
                            else -> return null
                        }
                    copy(rows = rows.toMutableList().also { it[index] = changed })
                }

                else -> {
                    null
                }
            }
        }

        PathSegment.MapKey,
        PathSegment.MapValue,
        -> {
            null
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
