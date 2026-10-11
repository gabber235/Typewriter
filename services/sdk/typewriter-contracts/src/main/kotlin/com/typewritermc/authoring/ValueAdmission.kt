package com.typewritermc.authoring

import com.typewritermc.types.CollectionKind
import com.typewritermc.types.DataValue
import com.typewritermc.types.FloatWidth
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import com.typewritermc.types.requireCanonicalDecimal
import java.math.BigInteger

data class ValueProblem(
    val location: ValueLocation,
    val code: String,
)

sealed interface StructuralResult {
    data object Valid : StructuralResult

    data class Invalid(
        val problems: List<ValueProblem>,
    ) : StructuralResult
}

class CompleteValue internal constructor(
    val schema: CheckedType,
    val value: DataValue,
)

sealed interface CompletenessResult {
    data class Complete(
        val value: CompleteValue,
    ) : CompletenessResult

    data class Unfinished(
        val locations: List<ValueLocation>,
    ) : CompletenessResult

    data class Invalid(
        val problems: List<ValueProblem>,
    ) : CompletenessResult
}

fun AuthoringRecord.validateStructure(catalog: CheckedCatalog): StructuralResult {
    val root = ValueLocation(AUTHORING_ROOT, ValuePath())
    return when (val configuration = configuration) {
        is TypeSelection.Complete -> {
            when (val resolved = catalog.resolve(configuration.use)) {
                is Resolution.Invalid -> {
                    StructuralResult.Invalid(resolved.diagnostics.map { it.asValueProblem(root) })
                }

                is Resolution.Ready -> {
                    val inspection = ValueInspection(catalog)
                    inspection.validatePayload(DataValue.Record(fields), resolved.value, root)
                    inspection.structuralResult()
                }
            }
        }

        is TypeSelection.Pending -> {
            validatePending(configuration, catalog, root)
        }
    }
}

fun CheckedType.complete(value: DataValue): CompletenessResult {
    val inspection = ValueInspection(resolver)
    val root = ValueLocation(AUTHORING_ROOT, ValuePath())
    inspection.validateCheckedValue(value, this, root)
    return when {
        inspection.problems.isNotEmpty() -> CompletenessResult.Invalid(inspection.problems)
        inspection.unfinished.isNotEmpty() -> CompletenessResult.Unfinished(inspection.unfinished)
        else -> CompletenessResult.Complete(CompleteValue(this, value))
    }
}

private fun AuthoringRecord.validatePending(
    selection: TypeSelection.Pending,
    catalog: CheckedCatalog,
    root: ValueLocation,
): StructuralResult {
    val partial = catalog.resolvePartial(selection)
    if (partial is Resolution.Invalid) {
        return StructuralResult.Invalid(partial.diagnostics.map { it.asValueProblem(root) })
    }
    partial as Resolution.Ready
    val known = partial.value.knownFields.associateBy { it.key }
    val dependent = partial.value.dependentFields.associateBy { it.owner.name }
    val expectedKeys = known.keys + dependent.keys
    val problems = mutableListOf<ValueProblem>()
    (fields.keys - expectedKeys).forEach { key -> problems += ValueProblem(root.field(key), "unknown_field") }
    (expectedKeys - fields.keys).forEach { key -> problems += ValueProblem(root.field(key), "missing_field") }
    val inspection = ValueInspection(catalog)
    known.forEach { (name, field) ->
        val value = fields[name] ?: return@forEach
        inspection.validateUse(value, field.type, root.field(name))
    }
    dependent.forEach { (name, _) ->
        val value = fields[name] ?: return@forEach
        if (value != DataValue.Unfilled) problems += ValueProblem(root.field(name), "dependent_field_requires_type")
    }
    problems += inspection.problems
    return if (problems.isEmpty()) StructuralResult.Valid else StructuralResult.Invalid(problems)
}

private class ValueInspection(
    private val catalog: CheckedCatalog?,
) {
    val problems = mutableListOf<ValueProblem>()
    val unfinished = mutableListOf<ValueLocation>()

    fun structuralResult(): StructuralResult = if (problems.isEmpty()) StructuralResult.Valid else StructuralResult.Invalid(problems)

    fun validateCheckedValue(
        value: DataValue,
        checked: CheckedType,
        at: ValueLocation,
    ) = validateCheckedValue(value, checked, at, 0)

    private fun validateCheckedValue(
        value: DataValue,
        checked: CheckedType,
        at: ValueLocation,
        depth: Int,
    ) {
        if (!withinDepth(at, depth)) return
        if (value == DataValue.Unfilled) {
            unfinished += at
            return
        }
        when (val use = checked.use) {
            is TypeUse.Nullable -> {
                if (value == DataValue.Null) return
                validateUseWithResolver(value, use.value, at, depth + 1)
            }

            is TypeUse.Named -> {
                val named = value as? DataValue.Named
                if (named == null) {
                    problem(at, "expected_named")
                    return
                }
                if (named.actualType != use) {
                    problem(at, "wrong_actual_type")
                    return
                }
                validatePayload(named.payload, checked, at, depth + 1)
            }

            is TypeUse.Scalar -> {
                validateScalar(value, use.kind, at)
            }
        }
    }

    fun validateUse(
        value: DataValue,
        expected: TypeUse,
        at: ValueLocation,
    ) = validateUse(value, expected, at, 0)

    private fun validateUse(
        value: DataValue,
        expected: TypeUse,
        at: ValueLocation,
        depth: Int,
    ) {
        if (!withinDepth(at, depth)) return
        if (value == DataValue.Unfilled) {
            unfinished += at
            return
        }
        when (expected) {
            is TypeUse.Nullable -> {
                if (value == DataValue.Null) return
                validateUse(value, expected.value, at, depth + 1)
            }

            is TypeUse.Scalar -> {
                validateScalar(value, expected.kind, at)
            }

            is TypeUse.Named -> {
                val named = value as? DataValue.Named
                if (named == null) {
                    problem(at, "expected_named")
                    return
                }
                val resolver = catalog
                if (resolver == null) {
                    if (named.actualType != expected) problem(at, "wrong_actual_type")
                    return
                }
                if (!resolver.isReadableAs(named.actualType, expected)) {
                    problem(at, "unreadable_actual_type")
                    return
                }
                when (val actual = resolver.resolve(named.actualType)) {
                    is Resolution.Invalid -> problems += actual.diagnostics.map { it.asValueProblem(at) }
                    is Resolution.Ready -> validatePayload(named.payload, actual.value, at, depth + 1)
                }
            }
        }
    }

    fun validatePayload(
        value: DataValue,
        checked: CheckedType,
        at: ValueLocation,
    ) = validatePayload(value, checked, at, 0)

    private fun validatePayload(
        value: DataValue,
        checked: CheckedType,
        at: ValueLocation,
        depth: Int,
    ) {
        if (!withinDepth(at, depth)) return
        if (value == DataValue.Unfilled) {
            unfinished += at
            return
        }
        when (val representation = checked.schema.representation) {
            is ResolvedRepresentation.Scalar -> validateScalar(value, representation.kind, at)
            is ResolvedRepresentation.Record -> validateRecord(value, representation, at, depth)
            is ResolvedRepresentation.Sequence -> validateSequence(value, representation, at, depth)
            is ResolvedRepresentation.Mapping -> validateMapping(value, representation, at, depth)
            is ResolvedRepresentation.Enumeration -> validateEnumeration(value, representation, at)
            is ResolvedRepresentation.Link -> validateLink(value, representation, at)
        }
    }

    private fun validateUseWithResolver(
        value: DataValue,
        use: TypeUse,
        at: ValueLocation,
        depth: Int,
    ) {
        if (!withinDepth(at, depth)) return
        val resolver = catalog
        if (resolver != null) {
            validateUse(value, use, at, depth)
        } else {
            when (use) {
                is TypeUse.Scalar -> {
                    validateScalar(value, use.kind, at)
                }

                is TypeUse.Nullable -> {
                    if (value != DataValue.Null) validateUseWithResolver(value, use.value, at, depth + 1)
                }

                is TypeUse.Named -> {
                    problem(at, "catalog_required_for_nested_named")
                }
            }
        }
    }

    private fun validateRecord(
        value: DataValue,
        representation: ResolvedRepresentation.Record,
        at: ValueLocation,
        depth: Int,
    ) {
        val record = value as? DataValue.Record
        if (record == null) {
            problem(at, "expected_record")
            return
        }
        val fields = representation.fields.associateBy { it.key }
        (record.fields.keys - fields.keys).forEach { name -> problem(at.field(name), "unknown_field") }
        (fields.keys - record.fields.keys).forEach { name -> problem(at.field(name), "missing_field") }
        fields.forEach { (name, field) ->
            record.fields[name]?.let { validateUse(it, field.type, at.field(name), depth + 1) }
        }
    }

    private fun validateSequence(
        value: DataValue,
        representation: ResolvedRepresentation.Sequence,
        at: ValueLocation,
        depth: Int,
    ) {
        val items =
            when (representation.kind) {
                CollectionKind.List -> (value as? DataValue.ListValue)?.items
                CollectionKind.Set -> (value as? DataValue.SetValue)?.items
            }
        if (items == null) {
            problem(at, if (representation.kind == CollectionKind.List) "expected_list" else "expected_set")
            return
        }
        val duplicateIds = items.groupBy { it.id }.filterValues { it.size > 1 }.keys
        duplicateIds.forEach { id -> problem(at.item(id), "duplicate_item_id") }
        items.forEach { item -> validateUse(item.value, representation.item, at.item(item.id), depth + 1) }
    }

    private fun validateMapping(
        value: DataValue,
        representation: ResolvedRepresentation.Mapping,
        at: ValueLocation,
        depth: Int,
    ) {
        val rows = (value as? DataValue.MapValue)?.rows
        if (rows == null) {
            problem(at, "expected_map")
            return
        }
        val duplicateIds = rows.groupBy { it.id }.filterValues { it.size > 1 }.keys
        duplicateIds.forEach { id -> problem(at.item(id), "duplicate_item_id") }
        rows.forEach { row ->
            validateUse(row.key, representation.key, at.item(row.id).mapKey(), depth + 1)
            validateUse(row.value, representation.value, at.item(row.id).mapValue(), depth + 1)
        }
    }

    private fun validateEnumeration(
        value: DataValue,
        representation: ResolvedRepresentation.Enumeration,
        at: ValueLocation,
    ) {
        val enum = value as? DataValue.EnumCase
        if (enum == null) {
            problem(at, "expected_enum")
            return
        }
        if (representation.cases.none { it.key == enum.key }) problem(at, "unknown_enum_case")
    }

    private fun validateLink(
        value: DataValue,
        representation: ResolvedRepresentation.Link,
        at: ValueLocation,
    ) {
        val link = value as? DataValue.Link
        if (link == null) {
            problem(at, "expected_link")
            return
        }
        if (link.endpoint != representation.endpoint) problem(at, "wrong_endpoint")
    }

    private fun validateScalar(
        value: DataValue,
        kind: ScalarKind,
        at: ValueLocation,
    ) {
        if (
            kind is ScalarKind.Float &&
            kind.width == FloatWidth.FLOAT_32 &&
            value is DataValue.Float &&
            value.value.isFinite() &&
            value.value.toFloat().toDouble() != value.value
        ) {
            problem(at, "float32_precision_loss")
            return
        }
        val valid =
            when (kind) {
                ScalarKind.Unit -> value == DataValue.Unit
                ScalarKind.Boolean -> value is DataValue.Boolean
                ScalarKind.Text -> value is DataValue.StringValue
                ScalarKind.Bytes -> value is DataValue.Bytes
                is ScalarKind.Integer -> value is DataValue.Integer && value.value.fits(kind.width)
                is ScalarKind.Float -> value is DataValue.Float && value.value.isFinite() && value.value.fits(kind.width)
                ScalarKind.Decimal -> value is DataValue.Decimal && value.value.isCanonicalDecimal()
                ScalarKind.Timestamp -> value is DataValue.Timestamp
                ScalarKind.Duration -> value is DataValue.Duration
            }
        if (!valid) problem(at, "wrong_scalar")
    }

    private fun problem(
        at: ValueLocation,
        code: String,
    ) {
        problems += ValueProblem(at, code)
    }

    private fun withinDepth(
        at: ValueLocation,
        depth: Int,
    ): Boolean {
        if (depth <= MAX_AUTHORED_VALUE_DEPTH) return true
        problem(at, "value_depth_limit")
        return false
    }
}

private fun BigInteger.fits(width: IntegerWidth): Boolean {
    val bits = width.bits
    val minimum = if (width.signed) BigInteger.ONE.shiftLeft(bits - 1).negate() else BigInteger.ZERO
    val maximum =
        if (width.signed) {
            BigInteger.ONE.shiftLeft(bits - 1).subtract(BigInteger.ONE)
        } else {
            BigInteger.ONE.shiftLeft(bits).subtract(BigInteger.ONE)
        }
    return this in minimum..maximum
}

private fun Double.fits(width: FloatWidth): Boolean =
    when (width) {
        FloatWidth.FLOAT_32 -> toFloat().isFinite() && toFloat().toDouble() == this
        FloatWidth.FLOAT_64 -> true
    }

private fun String.isCanonicalDecimal(): Boolean = runCatching { requireCanonicalDecimal("Decimal value") }.isSuccess

private fun ValueLocation.field(name: String) = copy(path = ValuePath(path.segments + PathSegment.Field(name)))

private fun ValueLocation.item(id: ItemId) = copy(path = ValuePath(path.segments + PathSegment.Item(id)))

private fun ValueLocation.mapKey() = copy(path = ValuePath(path.segments + PathSegment.MapKey))

private fun ValueLocation.mapValue() = copy(path = ValuePath(path.segments + PathSegment.MapValue))

private fun DeclarationDiagnostic.asValueProblem(at: ValueLocation) = ValueProblem(at, code)

private val AUTHORING_ROOT = ResourceId("authoring")

private const val MAX_AUTHORED_VALUE_DEPTH = 512
