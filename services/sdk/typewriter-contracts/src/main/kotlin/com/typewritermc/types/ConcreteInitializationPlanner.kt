package com.typewritermc.types

/** Recursively preserves supplied structure while reporting every value the caller must choose. */
internal class ConcreteInitializationPlanner(
    private val prototypes: TypePrototypeRegistry,
) {
    fun plan(
        root: ResolvedTypeRef,
        supplied: DataValue?,
    ): TypeInitializationPlan {
        val planned = plan(TypeExpression.Named(root), supplied, DataPath())
        return if (planned.requirements.isEmpty()) {
            TypeInitializationPlan.Ready(requireNotNull(planned.value))
        } else {
            TypeInitializationPlan.NeedsInput(planned.value, planned.requirements)
        }
    }

    private fun plan(
        type: TypeExpression,
        supplied: DataValue?,
        path: DataPath,
    ): PlannedValue {
        val resolved = prototypes.dataFormat.materialize(type)
        return when (resolved) {
            TypeExpression.Unit -> PlannedValue(DataValue.Unit)

            TypeExpression.Any,
            TypeExpression.Boolean,
            is TypeExpression.StringType,
            is TypeExpression.Bytes,
            is TypeExpression.Integer,
            is TypeExpression.Float,
            is TypeExpression.Decimal,
            is TypeExpression.Timestamp,
            is TypeExpression.Duration,
            is TypeExpression.Enumeration,
            is TypeExpression.Reference,
            -> supplied.orRequirement(path, resolved)

            is TypeExpression.ListType -> planList(resolved, supplied, path)

            is TypeExpression.MapType -> planMap(resolved, supplied, path)

            is TypeExpression.Record -> planRecord(resolved, supplied, path)

            is TypeExpression.Named -> planAbstract(resolved, supplied, path)

            is TypeExpression.Parameter -> error("Unresolved type parameter ${resolved.name} cannot be initialized.")
        }
    }

    private fun planList(
        type: TypeExpression.ListType,
        supplied: DataValue?,
        path: DataPath,
    ): PlannedValue {
        if (supplied == null) return supplied.orRequirement(path, type)
        require(supplied is DataValue.ListValue) { "Expected list value at $path." }
        val cardinalityRequirement = type.cardinalityRequirement(supplied.values.size, path)
        val items = supplied.values.mapIndexed { index, value -> plan(type.element, value, path.append(DataPathSegment.Index(index))) }
        return PlannedValue(
            DataValue.ListValue(items.map { requireNotNull(it.value) }),
            listOfNotNull(cardinalityRequirement) + items.flatMap(PlannedValue::requirements),
        )
    }

    private fun planMap(
        type: TypeExpression.MapType,
        supplied: DataValue?,
        path: DataPath,
    ): PlannedValue {
        if (supplied == null) return supplied.orRequirement(path, type)
        require(supplied is DataValue.MapValue) { "Expected map value at $path." }
        val cardinalityRequirement = type.cardinalityRequirement(supplied.entries.size, path)
        val entries =
            supplied.entries.map { entry ->
                val entryPath = path.append(DataPathSegment.MapKey(entry.key))
                val key = plan(type.key, entry.key, entryPath)
                val value = plan(type.value, entry.value, entryPath)
                PlannedMapEntry(
                    DataMapEntry(requireNotNull(key.value), requireNotNull(value.value)),
                    key.requirements + value.requirements,
                )
            }
        return PlannedValue(
            DataValue.MapValue(entries.map(PlannedMapEntry::entry)),
            listOfNotNull(cardinalityRequirement) + entries.flatMap(PlannedMapEntry::requirements),
        )
    }

    private fun planRecord(
        type: TypeExpression.Record,
        supplied: DataValue?,
        path: DataPath,
    ): PlannedValue {
        require(supplied == null || supplied is DataValue.Record) { "Expected record value at $path." }
        val suppliedFields = supplied?.fields.orEmpty()
        val knownFields = type.fields.mapTo(hashSetOf(), TypeField::name)
        require(suppliedFields.keys.all { it in knownFields }) { "Supplied value contains fields outside its declared record." }

        val fields = linkedMapOf<String, DataValue>()
        val requirements = mutableListOf<TypeInitializationRequirement>()
        type.fields.forEach { field ->
            val fieldPath = path.append(DataPathSegment.Field(field.name))
            val planned =
                when {
                    field.name in suppliedFields -> plan(field.type, suppliedFields.getValue(field.name), fieldPath)
                    field.initialValue != null -> plan(field.type, field.initialValue, fieldPath)
                    field.defaulted -> null
                    else -> plan(field.type, null, fieldPath)
                }
            planned?.value?.let { fields[field.name] = it }
            planned?.requirements?.let(requirements::addAll)
        }
        return PlannedValue(DataValue.Record(fields), requirements)
    }

    private fun planAbstract(
        type: TypeExpression.Named,
        supplied: DataValue?,
        path: DataPath,
    ): PlannedValue {
        if (supplied == null) {
            return PlannedValue(
                null,
                listOf(TypeInitializationRequirement(path, type, TypeInitializationRequirementReason.CONCRETE_TYPE_REQUIRED)),
            )
        }
        require(supplied is DataValue.Polymorphic) { "Expected polymorphic value at $path." }
        require(prototypes.isConcreteSubtypeOf(supplied.concreteType, type.reference)) {
            "Concrete type ${supplied.concreteType} is not assignable to ${type.reference} at $path."
        }
        val planned = plan(TypeExpression.Named(supplied.concreteType), supplied.value, path)
        return PlannedValue(
            DataValue.Polymorphic(supplied.concreteType, planned.value ?: supplied.value),
            planned.requirements,
        )
    }

    private fun DataValue?.orRequirement(
        path: DataPath,
        expected: TypeExpression,
    ): PlannedValue =
        if (this != null) {
            PlannedValue(this)
        } else {
            PlannedValue(
                null,
                listOf(TypeInitializationRequirement(path, expected, TypeInitializationRequirementReason.MISSING_VALUE)),
            )
        }

    private fun TypeExpression.cardinalityRequirement(
        size: Int,
        path: DataPath,
    ): TypeInitializationRequirement? =
        when (this) {
            is TypeExpression.ListType -> requireCardinality(size, minimumLength, maximumLength, path)
            is TypeExpression.MapType -> requireCardinality(size, minimumLength, maximumLength, path)
            else -> null
        }

    private fun TypeExpression.requireCardinality(
        size: Int,
        minimum: Int?,
        maximum: Int?,
        path: DataPath,
    ): TypeInitializationRequirement? {
        require(maximum == null || size <= maximum) {
            "Collection at $path contains $size values, but the maximum is $maximum."
        }
        return if (minimum != null && size < minimum) {
            TypeInitializationRequirement(
                path = path,
                expected = this,
                reason = TypeInitializationRequirementReason.MISSING_VALUE,
            )
        } else {
            null
        }
    }

    private fun DataPath.append(segment: DataPathSegment): DataPath = DataPath(segments + segment)

    private data class PlannedValue(
        val value: DataValue?,
        val requirements: List<TypeInitializationRequirement> = emptyList(),
    )

    private data class PlannedMapEntry(
        val entry: DataMapEntry,
        val requirements: List<TypeInitializationRequirement>,
    )
}
