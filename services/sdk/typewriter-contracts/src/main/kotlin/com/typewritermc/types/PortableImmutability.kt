package com.typewritermc.types

/** Creates a declaration graph that does not retain caller supplied collections. */
fun TypeDefinition.immutableCopy(): TypeDefinition =
    copy(
        parameters = parameters.map { parameter -> parameter.copy(bounds = parameter.bounds.map(TypeTemplate::immutableCopy)) },
        representation = representation.immutableCopy(),
        parents = parents.map { parent -> parent.immutableCopy() as TypeTemplate.Named },
    )

/** Creates a type template that does not retain caller supplied argument collections. */
fun TypeTemplate.immutableCopy(): TypeTemplate =
    when (this) {
        is TypeTemplate.Parameter,
        is TypeTemplate.Scalar,
        -> this

        is TypeTemplate.Named -> copy(arguments = arguments.map(TypeTemplate::immutableCopy))

        is TypeTemplate.Nullable -> copy(value = value.immutableCopy())
    }

/** Creates a concrete type use that does not retain caller supplied argument collections. */
fun TypeUse.immutableCopy(): TypeUse =
    when (this) {
        is TypeUse.Scalar -> this
        is TypeUse.Named -> copy(arguments = arguments.map(TypeUse::immutableCopy))
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
            copy(value = value.toList())
        }

        is DataValue.Record -> {
            copy(fields = fields.mapValues { (_, value) -> value.immutableCopy() }.toMap())
        }

        is DataValue.Named -> {
            copy(
                actualType = actualType.immutableCopy() as TypeUse.Named,
                payload = payload.immutableCopy(),
            )
        }

        is DataValue.ListValue -> {
            copy(items = items.map { item -> item.copy(value = item.value.immutableCopy()) })
        }

        is DataValue.SetValue -> {
            copy(items = items.map { item -> item.copy(value = item.value.immutableCopy()) })
        }

        is DataValue.MapValue -> {
            copy(
                rows =
                    rows.map { row ->
                        row.copy(
                            key = row.key.immutableCopy(),
                            value = row.value.immutableCopy(),
                        )
                    },
            )
        }

        is DataValue.Link -> {
            copy(target = target.copy(opposite = target.opposite?.copy(segments = target.opposite.segments.toList())))
        }
    }

private fun RepresentationTemplate.immutableCopy(): RepresentationTemplate =
    when (this) {
        is RepresentationTemplate.Scalar -> {
            this
        }

        is RepresentationTemplate.Enumeration -> {
            copy(cases = cases.toList())
        }

        is RepresentationTemplate.Record -> {
            copy(
                fields =
                    fields.map { field ->
                        field.copy(
                            type = field.type.immutableCopy(),
                            overrides = field.overrides.toList(),
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
