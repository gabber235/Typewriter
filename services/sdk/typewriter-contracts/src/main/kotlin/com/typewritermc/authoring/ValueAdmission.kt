package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import com.typewritermc.types.actualType
import com.typewritermc.types.bits
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.contentOwner
import com.typewritermc.types.catalog.referencedDefinitions
import com.typewritermc.types.catalog.unavailableCode
import com.typewritermc.types.endpoint
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.identityKey
import com.typewritermc.types.isCanonicalDecimal
import com.typewritermc.types.items
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.signed
import com.typewritermc.types.storedUse
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.diagnostic.StructuralResult
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.LinkResolvedRepresentation
import skirout.editor.v1.type_catalog.MappingResolvedRepresentation
import skirout.editor.v1.type_catalog.RecordResolvedRepresentation
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.SequenceResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import java.math.BigInteger
import skirout.kernel.v1.resource_id.ResourceId as SkirResourceId

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

/**
 * A way a value does not fit its schema, the type it is about when that type is gone or invalid, and the target of the
 * link stored where it is. Two misfits are the same when their location, code, type and target agree, so a second use
 * of a missing type is a new one.
 */
data class Misfit(
    val problem: ValueProblem,
    val type: TypeDefinitionId? = null,
    val target: SkirResourceId? = null,
) {
    /**
     * Whether a change made this misfit, given the ones the value had [before]. A link that does not fit and now points
     * at another target is new, as a new link would be; one that was removed is not, since that leaves less misfit.
     */
    fun isNewAgainst(before: Set<Misfit>): Boolean = this !in before && (target != null || before.none { it.copy(target = null) == this })
}

/** Checks record shape and type compatibility while allowing [DataValue.UNFILLED] at otherwise valid locations. */
fun AuthoringRecord.validateStructure(catalog: CheckedCatalog): StructuralResult {
    val problems = inspectStructure(catalog).problems
    return if (problems.isEmpty()) StructuralResult.VALID else StructuralResult.InvalidWrapper(problems)
}

/**
 * Every structural problem of this record on [owner], with each use of a type that is gone or invalid inside its values
 * as its own misfit at its location: a named value's actual type or a stored type use.
 */
fun AuthoringRecord.structuralMisfits(
    owner: skirout.kernel.v1.resource_id.ResourceId,
    catalog: CheckedCatalog,
): List<Misfit> {
    val inspection = inspectStructure(catalog)
    return (inspection.problems.map { Misfit(it) } + inspection.typed).map { misfit ->
        misfit.copy(problem = misfit.problem.copy(location = misfit.problem.location.copy(resource = owner)))
    }
}

private fun AuthoringRecord.inspectStructure(catalog: CheckedCatalog): ValueInspection {
    val root = ValueLocation.of(AUTHORING_ROOT)
    val inspection = ValueInspection()
    val walk = ValueWalk(catalog, inspection)
    when (val configuration = configuration) {
        is TypeSelection.CompleteWrapper -> {
            when (val resolved = catalog.resolve(configuration.use.use)) {
                is Resolution.Invalid -> inspection.problems += resolved.diagnostics.map { it.asValueProblem(root) }
                is Resolution.Ready -> walk.walkPayload(DataValue.RecordWrapper(payload), resolved.value, root)
            }
        }

        is TypeSelection.PendingWrapper -> {
            inspectPending(configuration, catalog, walk, inspection, root)
        }

        else -> {
            unknownVariant(configuration)
        }
    }
    return inspection
}

/** Admits a complete value for native use, distinguishing unfinished locations from structurally invalid content. */
fun CheckedType.complete(value: DataValue): CompletenessResult {
    val inspection = ValueInspection()
    val root = ValueLocation.of(AUTHORING_ROOT)
    ValueWalk(resolver, inspection).walkChecked(value, this, root)
    return when {
        inspection.problems.isNotEmpty() -> CompletenessResult.Invalid(inspection.problems)
        inspection.unfinished.isNotEmpty() -> CompletenessResult.Unfinished(inspection.unfinished)
        else -> CompletenessResult.Complete(CompleteValue(this, value))
    }
}

private fun AuthoringRecord.inspectPending(
    selection: TypeSelection.PendingWrapper,
    catalog: CheckedCatalog,
    walk: ValueWalk<Unit>,
    inspection: ValueInspection,
    root: ValueLocation,
) {
    val partial = catalog.resolvePartial(selection)
    if (partial is Resolution.Invalid) {
        inspection.problems += partial.diagnostics.map { it.asValueProblem(root) }
        return
    }
    partial as Resolution.Ready
    val known = partial.value.knownFields.associateBy { it.key }
    val dependent = partial.value.dependentFields.associateBy { it.owner.name }
    val expectedKeys = known.keys + dependent.keys
    val problems = mutableListOf<ValueProblem>()
    val present = fields.mapView.keys
    (present - expectedKeys).forEach { key -> problems += ValueProblem(location = root.field(key), code = "unknown_field") }
    (expectedKeys - present).forEach { key -> problems += ValueProblem(location = root.field(key), code = "missing_field") }
    known.forEach { (name, field) ->
        val value = field(name) ?: return@forEach
        walk.walk(value, field.type, root.field(name))
    }
    dependent.forEach { (name, _) ->
        val value = field(name) ?: return@forEach
        if (value != DataValue.UNFILLED) problems += ValueProblem(location = root.field(name), code = "dependent_field_requires_type")
    }
    inspection.problems += problems
}

/**
 * What the one schema walk does at each node it reaches. Inspection records a problem and goes on; evaluation stops at
 * the first. Every node sees a non null type: a nullable use around a value walks its inner type.
 */
interface ValueVisitor<R> {
    /** A check failed at [at]; [type] is the type it is about when that type is gone or invalid. */
    fun problem(
        at: ValueLocation,
        code: String,
        type: TypeDefinitionId? = null,
    )

    /** What a node that failed a check stands for, so inspection can go on. A visitor that throws in [problem] never reaches it. */
    fun placeholder(at: ValueLocation): R

    fun unfinished(at: ValueLocation): R

    fun nullValue(at: ValueLocation): R

    fun scalar(
        value: DataValue,
        kind: ScalarKind,
        at: ValueLocation,
    ): R

    fun link(
        link: DataValue.LinkWrapper,
        at: ValueLocation,
    ): R

    fun sequence(
        kind: CollectionKind,
        items: List<R>,
        at: ValueLocation,
    ): R

    fun mapping(
        rows: List<Pair<R, R>>,
        at: ValueLocation,
    ): R

    /** A named record; [actual] is the stored value's own type, expanded and applied, never a field key. */
    fun record(
        actual: TypeUse,
        fields: Map<String, R>,
        at: ValueLocation,
    ): R

    /** Any other named value, an enum case or a value class, with its payload's answer. */
    fun named(
        actual: TypeUse,
        payload: R,
        at: ValueLocation,
    ): R

    /** True for a Var or function typed position this visitor reads later; the walk then calls [deferred] and does not descend. */
    fun defers(use: TypeUse): Boolean = false

    fun deferred(
        value: DataValue,
        use: TypeUse,
        at: ValueLocation,
    ): R = error("This visitor reads every position now.")
}

/**
 * The one schema walk over a stored value, so fit, evaluation and the formula sites cannot drift apart. It resolves each
 * node's type, checks it, and hands the node to [visitor]: one set of locations (item ids, map key and value), one
 * nullable rule, one actual type rule (a named value's own type decides its record), and the collection rules by
 * identity key. A content type that is gone or invalid is a problem at the named value or stored type use that names it.
 */
class ValueWalk<R>(
    private val catalog: CheckedCatalog?,
    private val visitor: ValueVisitor<R>,
) {
    /** [value] at the declared [use]. */
    fun walk(
        value: DataValue,
        use: TypeUse,
        at: ValueLocation,
    ): R = validateUse(value, use, at, 0)

    /** The payload [value] of [checked], such as a resource's fields under its configuration. */
    fun walkPayload(
        value: DataValue,
        checked: CheckedType,
        at: ValueLocation,
    ): R = validatePayload(value, checked, checked.use, at, 0)

    /** [value] admitted against the applied [checked] type itself. */
    fun walkChecked(
        value: DataValue,
        checked: CheckedType,
        at: ValueLocation,
    ): R = validateCheckedValue(value, checked, at, 0)

    /** Reports each content type [use] names that stands in as the error type, at [at]. */
    private fun noteUnavailable(
        use: TypeUse,
        at: ValueLocation,
    ) {
        val resolver = catalog ?: return
        use.referencedDefinitions().distinct().filter { it.contentOwner() != null }.forEach { id ->
            resolver.unavailableCode(id)?.let { visitor.problem(at, it, id) }
        }
    }

    private fun validateCheckedValue(
        value: DataValue,
        checked: CheckedType,
        at: ValueLocation,
        depth: Int,
    ): R {
        if (!withinDepth(at, depth)) return visitor.placeholder(at)
        if (visitor.defers(checked.use)) return visitor.deferred(value, checked.use, at)
        if (value == DataValue.UNFILLED) return visitor.unfinished(at)
        return when (val use = checked.use) {
            is TypeUse.NullableWrapper -> {
                if (value == DataValue.NULL) {
                    visitor.nullValue(at)
                } else {
                    validateUseWithResolver(value, use.value.value, at, depth + 1)
                }
            }

            is TypeUse.NamedWrapper -> {
                val named = value as? DataValue.NamedWrapper ?: return problem(at, "expected_named")
                if (named.actualType == use.value) {
                    noteUnavailable(named.actualType.use, at)
                    validatePayload(named.payload, checked, expanded(named.actualType.use), at, depth + 1)
                } else {
                    validateUse(value, use, at, depth)
                }
            }

            is TypeUse.ScalarWrapper -> {
                validateScalar(value, use.value, at)
            }

            is TypeUse.FunctionWrapper -> {
                validateUse(value, use.storedUse, at, depth)
            }

            else -> {
                unknownVariant(use)
            }
        }
    }

    private fun validateUse(
        value: DataValue,
        expected: TypeUse,
        at: ValueLocation,
        depth: Int,
    ): R {
        if (!withinDepth(at, depth)) return visitor.placeholder(at)
        if (visitor.defers(expected)) return visitor.deferred(value, expected, at)
        if (value == DataValue.UNFILLED) return visitor.unfinished(at)
        return when (expected) {
            is TypeUse.NullableWrapper -> {
                if (value == DataValue.NULL) visitor.nullValue(at) else validateUse(value, expected.value.value, at, depth + 1)
            }

            is TypeUse.ScalarWrapper -> {
                validateScalar(value, expected.value, at)
            }

            is TypeUse.NamedWrapper -> {
                validateNamed(value, expected, at, depth)
            }

            is TypeUse.FunctionWrapper -> {
                validateUse(value, expected.storedUse, at, depth)
            }

            else -> {
                unknownVariant(expected)
            }
        }
    }

    /** A value at a named position: it carries its own type, which must be readable as [expected]. */
    private fun validateNamed(
        value: DataValue,
        expected: TypeUse.NamedWrapper,
        at: ValueLocation,
        depth: Int,
    ): R {
        val named = value as? DataValue.NamedWrapper ?: return problem(at, "expected_named")
        val resolver = catalog
        if (resolver == null) {
            return if (named.actualType != expected.value) problem(at, "wrong_actual_type") else visitor.placeholder(at)
        }
        if (!resolver.isReadableAs(named.actualType.use, expected)) return problem(at, "unreadable_actual_type")
        noteUnavailable(named.actualType.use, at)
        return when (val actual = resolver.resolve(named.actualType.use)) {
            is Resolution.Invalid -> {
                actual.diagnostics.forEach { visitor.problem(at, it.code) }
                visitor.placeholder(at)
            }

            is Resolution.Ready -> {
                validatePayload(named.payload, actual.value, expanded(named.actualType.use), at, depth + 1)
            }
        }
    }

    /** [actual] is the named value's own type; a record answers through it, a scalar representation as a named value. */
    private fun validatePayload(
        value: DataValue,
        checked: CheckedType,
        actual: TypeUse,
        at: ValueLocation,
        depth: Int,
    ): R {
        if (!withinDepth(at, depth)) return visitor.placeholder(at)
        if (value == DataValue.UNFILLED) return visitor.unfinished(at)
        return when (val representation = checked.schema.representation) {
            is ResolvedRepresentation.ScalarWrapper -> visitor.named(actual, validateScalar(value, representation.value.kind, at), at)
            is ResolvedRepresentation.RecordWrapper -> validateRecord(value, representation.value, actual, at, depth)
            is ResolvedRepresentation.SequenceWrapper -> validateSequence(value, representation.value, at, depth)
            is ResolvedRepresentation.MappingWrapper -> validateMapping(value, representation.value, at, depth)
            is ResolvedRepresentation.LinkWrapper -> validateLink(value, representation.value, at)
            else -> unknownVariant(representation)
        }
    }

    private fun validateUseWithResolver(
        value: DataValue,
        use: TypeUse,
        at: ValueLocation,
        depth: Int,
    ): R {
        if (!withinDepth(at, depth)) return visitor.placeholder(at)
        if (catalog != null) return validateUse(value, use, at, depth)
        return when (use) {
            is TypeUse.ScalarWrapper -> {
                validateScalar(value, use.value, at)
            }

            is TypeUse.NullableWrapper -> {
                if (value != DataValue.NULL) validateUseWithResolver(value, use.value.value, at, depth + 1) else visitor.nullValue(at)
            }

            is TypeUse.NamedWrapper, is TypeUse.FunctionWrapper -> {
                problem(at, "catalog_required_for_nested_named")
            }

            else -> {
                unknownVariant(use)
            }
        }
    }

    private fun validateRecord(
        value: DataValue,
        representation: RecordResolvedRepresentation,
        actual: TypeUse,
        at: ValueLocation,
        depth: Int,
    ): R {
        val record = value as? DataValue.RecordWrapper ?: return problem(at, "expected_record")
        val fields = representation.fields.associateBy { it.key }
        val present = record.fields.mapView
        (present.keys - fields.keys).forEach { name -> visitor.problem(at.field(name), "unknown_field") }
        (fields.keys - present.keys).forEach { name -> visitor.problem(at.field(name), "missing_field") }
        val answers =
            fields.entries.mapNotNull { (name, field) ->
                present[name]?.let { name to validateUse(it.value, field.type, at.field(name), depth + 1) }
            }
        return visitor.record(actual, answers.toMap(), at)
    }

    private fun validateSequence(
        value: DataValue,
        representation: SequenceResolvedRepresentation,
        at: ValueLocation,
        depth: Int,
    ): R {
        val items =
            when (representation.kind) {
                CollectionKind.LIST -> (value as? DataValue.ListValueWrapper)?.items
                CollectionKind.SET -> (value as? DataValue.SetValueWrapper)?.items
                else -> unknownVariant(representation.kind)
            } ?: return problem(at, if (representation.kind == CollectionKind.LIST) "expected_list" else "expected_set")
        val duplicateIds = items.groupBy { it.id }.filterValues { it.size > 1 }.keys
        duplicateIds.forEach { id -> visitor.problem(at.item(id), "duplicate_item_id") }
        if (representation.kind == CollectionKind.SET) {
            items.repeatsBy { it.value.identityKey() }.forEach { item -> visitor.problem(at.item(item.id), "duplicate_set_value") }
        }
        return visitor.sequence(
            representation.kind,
            items.map { item -> validateUse(item.value, representation.item, at.item(item.id), depth + 1) },
            at,
        )
    }

    private fun validateMapping(
        value: DataValue,
        representation: MappingResolvedRepresentation,
        at: ValueLocation,
        depth: Int,
    ): R {
        val rows = (value as? DataValue.MapValueWrapper)?.rows ?: return problem(at, "expected_map")
        val duplicateIds = rows.groupBy { it.id }.filterValues { it.size > 1 }.keys
        duplicateIds.forEach { id -> visitor.problem(at.item(id), "duplicate_item_id") }
        rows.repeatsBy { it.key.identityKey() }.forEach { row -> visitor.problem(at.item(row.id).mapKey(), "duplicate_map_key") }
        return visitor.mapping(
            rows.map { row ->
                validateUse(row.key, representation.key, at.item(row.id).mapKey(), depth + 1) to
                    validateUse(row.value, representation.value, at.item(row.id).mapValue(), depth + 1)
            },
            at,
        )
    }

    private fun validateLink(
        value: DataValue,
        representation: LinkResolvedRepresentation,
        at: ValueLocation,
    ): R {
        val link = value as? DataValue.LinkWrapper ?: return problem(at, "expected_link")
        if (link.endpoint != representation.endpoint) return problem(at, "wrong_endpoint")
        return visitor.link(link, at)
    }

    private fun validateScalar(
        value: DataValue,
        kind: ScalarKind,
        at: ValueLocation,
    ): R {
        if (losesFloat32Precision(value, kind)) return problem(at, "float32_precision_loss")
        if (!scalarFits(value, kind)) return problem(at, "wrong_scalar")
        if (value is DataValue.TypeUseWrapper && !validateHeldType(value.value, at)) return visitor.placeholder(at)
        return visitor.scalar(value, kind, at)
    }

    /** A finite float stored at a 32 bit position that a Float cannot hold exactly. */
    private fun losesFloat32Precision(
        value: DataValue,
        kind: ScalarKind,
    ): Boolean =
        kind is ScalarKind.FloatWrapper &&
            kind.value.width == FloatWidth.THIRTY_TWO &&
            value is DataValue.FloatWrapper &&
            value.value.isFinite() &&
            value.value.toFloat().toDouble() != value.value

    /** Whether [value] has the form of a [kind] scalar. */
    private fun scalarFits(
        value: DataValue,
        kind: ScalarKind,
    ): Boolean =
        when (kind) {
            is ScalarKind.IntegerWrapper -> value is DataValue.IntegerWrapper && value.fits(kind.value.width)
            is ScalarKind.FloatWrapper -> value is DataValue.FloatWrapper && value.fits(kind.value.width)
            ScalarKind.DECIMAL -> value is DataValue.DecimalWrapper && value.value.isCanonicalDecimal()
            else -> plainScalarForms[kind]?.invoke(value) ?: unknownVariant(kind)
        }

    /** A held type must resolve; a content type it names that is gone or invalid is its own problem here. False when one was found. */
    private fun validateHeldType(
        use: TypeUse,
        at: ValueLocation,
    ): Boolean {
        val resolver = catalog ?: return true
        var fits = true
        (resolver.resolve(use) as? Resolution.Invalid)?.let { invalid ->
            fits = false
            invalid.diagnostics.forEach { visitor.problem(at, it.code) }
        }
        use.referencedDefinitions().distinct().filter { it.contentOwner() != null }.forEach { id ->
            resolver.unavailableCode(id)?.let {
                fits = false
                visitor.problem(at, it, id)
            }
        }
        return fits
    }

    /** The named value's own type with every field key expanded, as the visitor receives it. */
    private fun expanded(use: TypeUse): TypeUse = catalog?.expand(use) ?: use

    private fun problem(
        at: ValueLocation,
        code: String,
    ): R {
        visitor.problem(at, code)
        return visitor.placeholder(at)
    }

    private fun withinDepth(
        at: ValueLocation,
        depth: Int,
    ): Boolean {
        if (depth <= MAX_AUTHORED_VALUE_DEPTH) return true
        visitor.problem(at, "value_depth_limit")
        return false
    }
}

/**
 * complete(), validateStructure and the misfits: the walk as a visitor that collects. A problem about a type that is
 * gone or invalid is a typed misfit, which only misfits read; every other one is a structural problem.
 */
private class ValueInspection : ValueVisitor<Unit> {
    val problems = mutableListOf<ValueProblem>()
    val unfinished = mutableListOf<ValueLocation>()
    val typed = mutableListOf<Misfit>()

    override fun problem(
        at: ValueLocation,
        code: String,
        type: TypeDefinitionId?,
    ) {
        if (type ==
            null
        ) {
            problems += ValueProblem(location = at, code = code)
        } else {
            typed += Misfit(ValueProblem(location = at, code = code), type)
        }
    }

    override fun placeholder(at: ValueLocation) = Unit

    override fun unfinished(at: ValueLocation) {
        unfinished += at
    }

    override fun nullValue(at: ValueLocation) = Unit

    override fun scalar(
        value: DataValue,
        kind: ScalarKind,
        at: ValueLocation,
    ) = Unit

    override fun link(
        link: DataValue.LinkWrapper,
        at: ValueLocation,
    ) = Unit

    override fun sequence(
        kind: CollectionKind,
        items: List<Unit>,
        at: ValueLocation,
    ) = Unit

    override fun mapping(
        rows: List<Pair<Unit, Unit>>,
        at: ValueLocation,
    ) = Unit

    override fun record(
        actual: TypeUse,
        fields: Map<String, Unit>,
        at: ValueLocation,
    ) = Unit

    override fun named(
        actual: TypeUse,
        payload: Unit,
        at: ValueLocation,
    ) = Unit
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

private fun DeclarationDiagnostic.asValueProblem(at: ValueLocation) = ValueProblem(location = at, code = code)

private val AUTHORING_ROOT = ResourceId("authoring")

private const val MAX_AUTHORED_VALUE_DEPTH = 512

/** Every element after the first whose [key] an earlier element already has. */
private fun <T> List<T>.repeatsBy(key: (T) -> String): List<T> {
    val seen = hashSetOf<String>()
    return filterNot { seen.add(key(it)) }
}

/** The form of each scalar kind that has no width or canonical text to check. */
private val plainScalarForms: Map<ScalarKind, (DataValue) -> Boolean> =
    mapOf(
        ScalarKind.UNIT to { value -> value == DataValue.UNIT },
        ScalarKind.BOOLEAN to { value -> value is DataValue.BooleanWrapper },
        ScalarKind.TEXT to { value -> value is DataValue.StringValueWrapper },
        ScalarKind.BYTES to { value -> value is DataValue.BytesWrapper },
        ScalarKind.TIMESTAMP to { value -> value is DataValue.TimestampWrapper },
        ScalarKind.DURATION to { value -> value is DataValue.DurationWrapper },
        ScalarKind.TYPE to { value -> value is DataValue.TypeUseWrapper },
    )
