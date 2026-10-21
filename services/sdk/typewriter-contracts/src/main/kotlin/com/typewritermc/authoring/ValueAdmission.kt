package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import com.typewritermc.types.actualType
import com.typewritermc.types.bits
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.endpoint
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.isCanonicalDecimal
import com.typewritermc.types.items
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.signed
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EnumerationResolvedRepresentation
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.LinkResolvedRepresentation
import skirout.editor.v1.type_catalog.MappingResolvedRepresentation
import skirout.editor.v1.type_catalog.RecordResolvedRepresentation
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.SequenceResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeUse
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

/** A value admitted against [schema] with no structural problems or unfinished locations. */
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

/** Checks record shape and type compatibility while allowing [DataValue.UNFILLED] at otherwise valid locations. */
fun AuthoringRecord.validateStructure(catalog: CheckedCatalog): StructuralResult {
    val root = ValueLocation(AUTHORING_ROOT, ValuePath())
    return when (val configuration = configuration) {
        is TypeSelection.Complete -> {
            when (val resolved = catalog.resolve(configuration.use.use)) {
                is Resolution.Invalid -> {
                    StructuralResult.Invalid(resolved.diagnostics.map { it.asValueProblem(root) })
                }

                is Resolution.Ready -> {
                    val inspection = ValueInspection(catalog)
                    inspection.validatePayload(DataValue.record(fields), resolved.value, root)
                    inspection.structuralResult()
                }
            }
        }

        is TypeSelection.Pending -> {
            validatePending(configuration, catalog, root)
        }
    }
}

/** Admits a complete value for native use, distinguishing unfinished locations from structurally invalid content. */
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
        if (value != DataValue.UNFILLED) problems += ValueProblem(root.field(name), "dependent_field_requires_type")
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
        if (value == DataValue.UNFILLED) {
            unfinished += at
            return
        }
        when (val use = checked.use) {
            is TypeUse.NullableWrapper -> {
                if (value == DataValue.NULL) return
                validateUseWithResolver(value, use.value.value, at, depth + 1)
            }

            is TypeUse.NamedWrapper -> {
                val named = value as? DataValue.NamedWrapper
                if (named == null) {
                    problem(at, "expected_named")
                    return
                }
                if (named.actualType != use.value) {
                    problem(at, "wrong_actual_type")
                    return
                }
                validatePayload(named.payload, checked, at, depth + 1)
            }

            is TypeUse.ScalarWrapper -> {
                validateScalar(value, use.value, at)
            }

            else -> {
                unknownVariant(use)
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
        if (value == DataValue.UNFILLED) {
            unfinished += at
            return
        }
        when (expected) {
            is TypeUse.NullableWrapper -> {
                if (value == DataValue.NULL) return
                validateUse(value, expected.value.value, at, depth + 1)
            }

            is TypeUse.ScalarWrapper -> {
                validateScalar(value, expected.value, at)
            }

            is TypeUse.NamedWrapper -> {
                val named = value as? DataValue.NamedWrapper
                if (named == null) {
                    problem(at, "expected_named")
                    return
                }
                val resolver = catalog
                if (resolver == null) {
                    if (named.actualType != expected.value) problem(at, "wrong_actual_type")
                    return
                }
                if (!resolver.isReadableAs(named.actualType.use, expected)) {
                    problem(at, "unreadable_actual_type")
                    return
                }
                when (val actual = resolver.resolve(named.actualType.use)) {
                    is Resolution.Invalid -> problems += actual.diagnostics.map { it.asValueProblem(at) }
                    is Resolution.Ready -> validatePayload(named.payload, actual.value, at, depth + 1)
                }
            }

            else -> {
                unknownVariant(expected)
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
        if (value == DataValue.UNFILLED) {
            unfinished += at
            return
        }
        when (val representation = checked.schema.representation) {
            is ResolvedRepresentation.ScalarWrapper -> validateScalar(value, representation.value.kind, at)
            is ResolvedRepresentation.RecordWrapper -> validateRecord(value, representation.value, at, depth)
            is ResolvedRepresentation.SequenceWrapper -> validateSequence(value, representation.value, at, depth)
            is ResolvedRepresentation.MappingWrapper -> validateMapping(value, representation.value, at, depth)
            is ResolvedRepresentation.EnumerationWrapper -> validateEnumeration(value, representation.value, at)
            is ResolvedRepresentation.LinkWrapper -> validateLink(value, representation.value, at)
            else -> unknownVariant(representation)
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
                is TypeUse.ScalarWrapper -> {
                    validateScalar(value, use.value, at)
                }

                is TypeUse.NullableWrapper -> {
                    if (value != DataValue.NULL) validateUseWithResolver(value, use.value.value, at, depth + 1)
                }

                is TypeUse.NamedWrapper -> {
                    problem(at, "catalog_required_for_nested_named")
                }

                else -> {
                    unknownVariant(use)
                }
            }
        }
    }

    private fun validateRecord(
        value: DataValue,
        representation: RecordResolvedRepresentation,
        at: ValueLocation,
        depth: Int,
    ) {
        val record = value as? DataValue.RecordWrapper
        if (record == null) {
            problem(at, "expected_record")
            return
        }
        val fields = representation.fields.associateBy { it.key }
        val present = record.fields.mapView
        (present.keys - fields.keys).forEach { name -> problem(at.field(name), "unknown_field") }
        (fields.keys - present.keys).forEach { name -> problem(at.field(name), "missing_field") }
        fields.forEach { (name, field) ->
            present[name]?.let { validateUse(it.value, field.type, at.field(name), depth + 1) }
        }
    }

    private fun validateSequence(
        value: DataValue,
        representation: SequenceResolvedRepresentation,
        at: ValueLocation,
        depth: Int,
    ) {
        val items =
            when (representation.kind) {
                CollectionKind.LIST -> (value as? DataValue.ListValueWrapper)?.items
                CollectionKind.SET -> (value as? DataValue.SetValueWrapper)?.items
                else -> unknownVariant(representation.kind)
            }
        if (items == null) {
            problem(at, if (representation.kind == CollectionKind.LIST) "expected_list" else "expected_set")
            return
        }
        val duplicateIds = items.groupBy { it.id }.filterValues { it.size > 1 }.keys
        duplicateIds.forEach { id -> problem(at.item(id), "duplicate_item_id") }
        items.forEach { item -> validateUse(item.value, representation.item, at.item(item.id), depth + 1) }
    }

    private fun validateMapping(
        value: DataValue,
        representation: MappingResolvedRepresentation,
        at: ValueLocation,
        depth: Int,
    ) {
        val rows = (value as? DataValue.MapValueWrapper)?.rows
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
        representation: EnumerationResolvedRepresentation,
        at: ValueLocation,
    ) {
        val enum = value as? DataValue.EnumCaseWrapper
        if (enum == null) {
            problem(at, "expected_enum")
            return
        }
        if (representation.cases.none { it.key == enum.value }) problem(at, "unknown_enum_case")
    }

    private fun validateLink(
        value: DataValue,
        representation: LinkResolvedRepresentation,
        at: ValueLocation,
    ) {
        val link = value as? DataValue.LinkWrapper
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
            kind is ScalarKind.FloatWrapper &&
            kind.value.width == FloatWidth.THIRTY_TWO &&
            value is DataValue.FloatWrapper &&
            value.value.isFinite() &&
            value.value.toFloat().toDouble() != value.value
        ) {
            problem(at, "float32_precision_loss")
            return
        }
        val valid =
            when (kind) {
                ScalarKind.UNIT -> value == DataValue.UNIT
                ScalarKind.BOOLEAN -> value is DataValue.BooleanWrapper
                ScalarKind.TEXT -> value is DataValue.StringValueWrapper
                ScalarKind.BYTES -> value is DataValue.BytesWrapper
                is ScalarKind.IntegerWrapper -> value is DataValue.IntegerWrapper && value.fits(kind.value.width)
                is ScalarKind.FloatWrapper -> value is DataValue.FloatWrapper && value.fits(kind.value.width)
                ScalarKind.DECIMAL -> value is DataValue.DecimalWrapper && value.value.isCanonicalDecimal()
                ScalarKind.TIMESTAMP -> value is DataValue.TimestampWrapper
                ScalarKind.DURATION -> value is DataValue.DurationWrapper
                else -> unknownVariant(kind)
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

private fun DataValue.IntegerWrapper.fits(width: IntegerWidth): Boolean = value.toBigIntegerOrNull()?.fits(width) == true

private fun DataValue.FloatWrapper.fits(width: FloatWidth): Boolean = value.isFinite() && value.fits(width)

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
        FloatWidth.THIRTY_TWO -> toFloat().isFinite() && toFloat().toDouble() == this
        FloatWidth.SIXTY_FOUR -> true
        else -> unknownVariant(width)
    }

private fun DeclarationDiagnostic.asValueProblem(at: ValueLocation) = ValueProblem(at, code)

private val AUTHORING_ROOT = ResourceId("authoring")

private const val MAX_AUTHORED_VALUE_DEPTH = 512
