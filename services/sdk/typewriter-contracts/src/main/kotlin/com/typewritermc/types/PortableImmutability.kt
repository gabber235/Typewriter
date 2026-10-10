package com.typewritermc.types

import java.util.Collections

inline fun <T, R> Iterable<T>.immutableListCopy(transform: (T) -> R): List<R> = Collections.unmodifiableList(mapTo(ArrayList(), transform))

fun <T> Iterable<T>.immutableListCopy(): List<T> = immutableListCopy { it }

inline fun <K, V, R> Map<K, V>.immutableMapCopy(transform: (V) -> R): Map<K, R> =
    Collections.unmodifiableMap(entries.associateTo(LinkedHashMap()) { (key, value) -> key to transform(value) })

fun <K, V> Map<K, V>.immutableMapCopy(): Map<K, V> = immutableMapCopy { it }

fun <T> Iterable<T>.immutableSetCopy(): Set<T> = Collections.unmodifiableSet(toCollection(LinkedHashSet()))

/** Creates a declaration graph that does not retain caller supplied collections. */
fun TypeDefinition.immutableCopy(): TypeDefinition =
    copy(
        parameters =
            parameters.immutableListCopy { parameter ->
                parameter.copy(bounds = parameter.bounds.immutableListCopy(TypeTemplate::immutableCopy))
            },
        representation = representation.immutableCopy(),
        parents = parents.immutableListCopy { parent -> parent.immutableCopy() as TypeTemplate.Named },
    )

/** Creates a type template that does not retain caller supplied argument collections. */
fun TypeTemplate.immutableCopy(): TypeTemplate =
    when (this) {
        is TypeTemplate.Parameter,
        is TypeTemplate.Scalar,
        -> this

        is TypeTemplate.Named -> copy(arguments = arguments.immutableListCopy(TypeTemplate::immutableCopy))

        is TypeTemplate.Nullable -> copy(value = value.immutableCopy())
    }

/** Creates a concrete type use that does not retain caller supplied argument collections. */
fun TypeUse.immutableCopy(): TypeUse =
    when (this) {
        is TypeUse.Scalar -> this
        is TypeUse.Named -> copy(arguments = arguments.immutableListCopy(TypeUse::immutableCopy))
        is TypeUse.Nullable -> copy(value = value.immutableCopy())
    }

/** Creates a portable value that does not retain caller supplied collections. */
fun DataValue.immutableCopy(): DataValue =
    when (this) {
        DataValue.Unfilled,
        DataValue.Null,
        DataValue.Unit,
        is DataValue.Boolean,
        is DataValue.Integer,
        is DataValue.Float,
        is DataValue.Decimal,
        is DataValue.StringValue,
        is DataValue.Timestamp,
        is DataValue.Duration,
        is DataValue.EnumCase,
        -> {
            this
        }

        is DataValue.Bytes -> {
            copy(value = value.immutableListCopy())
        }

        is DataValue.Record -> {
            copy(fields = fields.immutableMapCopy(DataValue::immutableCopy))
        }

        is DataValue.Named -> {
            copy(
                actualType = actualType.immutableCopy() as TypeUse.Named,
                payload = payload.immutableCopy(),
            )
        }

        is DataValue.ListValue -> {
            copy(items = items.immutableListCopy { item -> item.copy(value = item.value.immutableCopy()) })
        }

        is DataValue.SetValue -> {
            copy(items = items.immutableListCopy { item -> item.copy(value = item.value.immutableCopy()) })
        }

        is DataValue.MapValue -> {
            copy(
                rows =
                    rows.immutableListCopy { row ->
                        row.copy(
                            key = row.key.immutableCopy(),
                            value = row.value.immutableCopy(),
                        )
                    },
            )
        }

        is DataValue.Link -> {
            copy(target = target.copy(opposite = target.opposite?.copy(segments = target.opposite.segments.immutableListCopy())))
        }
    }

private fun RepresentationTemplate.immutableCopy(): RepresentationTemplate =
    when (this) {
        is RepresentationTemplate.Scalar -> {
            this
        }

        is RepresentationTemplate.Enumeration -> {
            copy(cases = cases.immutableListCopy())
        }

        is RepresentationTemplate.Record -> {
            copy(
                fields =
                    fields.immutableListCopy { field ->
                        field.copy(
                            type = field.type.immutableCopy(),
                            overrides = field.overrides.immutableListCopy(),
                        )
                    },
            )
        }

        is RepresentationTemplate.Sequence -> {
            copy(item = item.immutableCopy())
        }

        is RepresentationTemplate.Mapping -> {
            copy(key = key.immutableCopy(), value = value.immutableCopy())
        }

        is RepresentationTemplate.Link -> {
            copy(target = target.immutableCopy())
        }
    }
