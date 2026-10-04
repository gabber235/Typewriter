package com.typewritermc.authoring

import com.typewritermc.types.CollectionKind
import com.typewritermc.types.DataValue
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import java.math.BigInteger

class DefaultInitializationRuntime(
    private val catalog: CheckedCatalog,
    private val bindings: NativeBindingRegistry,
    initialization: List<InitializationDescriptor> = emptyList(),
) : InitializationRuntime {
    private val initialization = initialization.associateBy(InitializationDescriptor::definition)

    override suspend fun prepare(request: InitializationRequest): PreparedCreation = prepareNow(request)

    fun prepareNow(request: InitializationRequest): PreparedCreation {
        if (request.catalog != catalog.generation) {
            return unavailable(request, "catalog_generation_mismatch", "The initialization request uses a different catalog generation.")
        }
        val selection = request.type
        if (selection is TypeSelection.Pending) return preparePending(request, selection)
        val use =
            selection.completeUse()
                ?: return unavailable(request, "incomplete_type_selection", "Initialization requires every type argument to be selected.")
        val checked =
            when (val resolution = catalog.resolve(use)) {
                is Resolution.Invalid -> {
                    return unavailable(request, "invalid_type_selection", resolution.diagnostics.joinToString { it.code })
                }

                is Resolution.Ready -> {
                    resolution.value
                }
            }
        rejectUnknownFields(request, checked.schema.fields.mapTo(linkedSetOf(), com.typewritermc.types.catalog.ResolvedField::key))
            ?.let { return it }
        val supplied = linkedMapOf<String, DataValue>()
        val ordinary = linkedMapOf<String, DataValue>()
        val samples = linkedMapOf<com.typewritermc.types.FieldOwner, CompleteValue>()
        val findings = mutableListOf<InitializationDiagnostic>()
        val defaulted = bindings.defaultedFields(checked)
        val descriptor = initialization[use.definition]
        val startupCaptured =
            descriptor
                ?.takeIf { it.mode == InitializationMode.Startup }
                ?.captured
                ?.associate { it.field to it.value }
                .orEmpty()
        checked.schema.fields.forEach { field ->
            val owner = com.typewritermc.types.FieldOwner(field.declarationOwner, field.key)
            val fieldFindings = mutableListOf<InitializationDiagnostic>()
            val context = DefaultInitializationContext()
            val authoredDefault =
                if (owner !in defaulted && field.key !in request.supplied) {
                    (startupCaptured[owner] ?: ordinaryDefault(field.type, context, fieldFindings)).also {
                        ordinary[field.key] = it
                    }
                } else {
                    null
                }
            val value =
                request.supplied[field.key] ?: authoredDefault?.let { samplingDefault(field.type, it, context, fieldFindings) }
                    ?: return@forEach
            findings += fieldFindings.map { it.prepend(PathSegment.Field(field.key)) }
            request.supplied[field.key]?.let { supplied[field.key] = it }
            if (owner in defaulted) return@forEach
            when (val result = completeSample(field.type, value)) {
                null -> Unit
                is CompletenessResult.Complete -> samples[owner] = result.value
                is CompletenessResult.Invalid, is CompletenessResult.Unfinished -> Unit
            }
        }
        val capture =
            if (descriptor?.mode == InitializationMode.Startup) {
                CaptureResult.Captured(descriptor.captured.associate { it.field to it.value })
            } else {
                bindings.sampleDefaults(checked, SamplingInputs(samples))
            }
        findings += descriptor?.diagnostics.orEmpty()
        findings += (capture as? CaptureResult.Unavailable)?.reasons.orEmpty()
        val captured = (capture as? CaptureResult.Captured)?.values.orEmpty()
        val fields = supplied.toMutableMap()
        checked.schema.fields.forEach { field ->
            if (field.key in fields) return@forEach
            val owner = com.typewritermc.types.FieldOwner(field.declarationOwner, field.key)
            fields[field.key] =
                when {
                    owner in captured -> captured.getValue(owner)
                    owner in defaulted -> DataValue.Unfilled
                    else -> ordinary.getValue(field.key)
                }
        }
        return PreparedCreation(AuthoringRecord(TypeSelection.Complete(use), fields), findings)
    }

    private fun preparePending(
        request: InitializationRequest,
        selection: TypeSelection.Pending,
    ): PreparedCreation {
        val partial =
            when (val resolution = catalog.resolvePartial(selection)) {
                is Resolution.Invalid -> {
                    return unavailable(request, "invalid_type_selection", resolution.diagnostics.joinToString { it.code })
                }

                is Resolution.Ready -> {
                    resolution.value
                }
            }
        val descriptor = initialization[selection.definition]
        val knownKeys = partial.knownFields.mapTo(linkedSetOf(), com.typewritermc.types.catalog.ResolvedField::key)
        val dependentKeys = partial.dependentFields.mapTo(linkedSetOf()) { it.owner.name }
        rejectUnknownFields(request, knownKeys + dependentKeys)?.let { return it }
        request.supplied.keys.firstOrNull { it in dependentKeys }?.let { dependent ->
            val field = partial.dependentFields.single { it.owner.name == dependent }.owner
            return unavailable(
                request,
                InitializationDiagnostic(
                    field = field,
                    code = "dependent_field_type_unavailable",
                    message = "Field $dependent cannot be supplied until every type argument it uses is selected.",
                ),
            )
        }
        val captured =
            descriptor
                ?.takeIf { it.mode == InitializationMode.Startup }
                ?.captured
                ?.associate { it.field to it.value }
                .orEmpty()
        val defaulted = bindings.defaultedFields(selection.definition)
        val findings = mutableListOf<InitializationDiagnostic>()
        val fields = linkedMapOf<String, DataValue>()
        partial.knownFields.forEach { field ->
            val owner = com.typewritermc.types.FieldOwner(field.declarationOwner, field.key)
            val fieldFindings = mutableListOf<InitializationDiagnostic>()
            fields[field.key] =
                request.supplied[field.key]
                    ?: captured[owner]
                    ?: if (owner in defaulted) {
                        DataValue.Unfilled
                    } else {
                        ordinaryDefault(field.type, DefaultInitializationContext(), fieldFindings)
                    }
            findings += fieldFindings.map { it.prepend(PathSegment.Field(field.key)) }
        }
        partial.dependentFields.forEach { field -> fields[field.owner.name] = DataValue.Unfilled }
        findings += descriptor?.diagnostics.orEmpty()
        findings +=
            InitializationDiagnostic(
                field = null,
                code = "incomplete_type_selection",
                message = "Initialization left fields that depend on unfinished type arguments unfilled.",
            )
        return PreparedCreation(AuthoringRecord(selection, fields), findings)
    }

    private fun unavailable(
        request: InitializationRequest,
        code: String,
        message: String,
    ): PreparedCreation = unavailable(request, InitializationDiagnostic(null, code, message))

    private fun unavailable(
        request: InitializationRequest,
        diagnostic: InitializationDiagnostic,
    ): PreparedCreation =
        PreparedCreation(
            AuthoringRecord(request.type, request.supplied),
            listOf(diagnostic),
        )

    private fun rejectUnknownFields(
        request: InitializationRequest,
        declared: Set<String>,
    ): PreparedCreation? {
        val unknown =
            request.supplied.keys
                .filterNot(declared::contains)
                .sorted()
        if (unknown.isEmpty()) return null
        return unavailable(
            request,
            "unknown_field",
            "Initialization supplied undeclared fields: ${unknown.joinToString()}.",
        )
    }

    private fun ordinaryDefault(
        use: TypeUse,
        context: DefaultInitializationContext,
        findings: MutableList<InitializationDiagnostic>,
    ): DataValue {
        when (context.enter(use)) {
            DefaultEntry.Recursive -> {
                findings +=
                    InitializationDiagnostic(
                        field = null,
                        code = "recursive_default_unavailable",
                        message = "A required recursive value of type $use has no finite ordinary default.",
                    )
                return DataValue.Unfilled
            }

            DefaultEntry.DepthLimit -> {
                findings +=
                    InitializationDiagnostic(
                        field = null,
                        code = "default_depth_limit",
                        message = "The ordinary default exceeds the supported nesting depth.",
                    )
                return DataValue.Unfilled
            }

            DefaultEntry.Ready -> {}
        }
        return try {
            when (use) {
                is TypeUse.Nullable -> DataValue.Null
                is TypeUse.Scalar -> use.kind.authoredDefault()
                is TypeUse.Named -> namedDefault(use, context, findings)
            }
        } finally {
            context.exit()
        }
    }

    private fun namedDefault(
        use: TypeUse.Named,
        context: DefaultInitializationContext,
        findings: MutableList<InitializationDiagnostic>,
    ): DataValue {
        val checked =
            when (val resolution = catalog.resolve(use)) {
                is Resolution.Invalid -> return DataValue.Unfilled
                is Resolution.Ready -> resolution.value
            }
        val payload =
            when (val representation = checked.schema.representation) {
                is ResolvedRepresentation.Scalar -> {
                    representation.kind.authoredDefault()
                }

                is ResolvedRepresentation.Sequence -> {
                    when (representation.kind) {
                        CollectionKind.List -> DataValue.ListValue(emptyList())
                        CollectionKind.Set -> DataValue.SetValue(emptyList())
                    }
                }

                is ResolvedRepresentation.Mapping -> {
                    DataValue.MapValue(emptyList())
                }

                is ResolvedRepresentation.Enumeration -> {
                    representation.cases.firstOrNull()?.let { DataValue.EnumCase(it.key) } ?: DataValue.Unfilled
                }

                is ResolvedRepresentation.Link -> {
                    DataValue.Unfilled
                }

                is ResolvedRepresentation.Record -> {
                    if (representation.abstract) return DataValue.Unfilled
                    val defaulted = bindings.defaultedFields(checked)
                    val descriptor = initialization[use.definition]
                    val startupCaptured =
                        descriptor
                            ?.takeIf { it.mode == InitializationMode.Startup }
                            ?.captured
                            ?.associate { it.field to it.value }
                            .orEmpty()
                    val required = linkedMapOf<com.typewritermc.types.FieldOwner, CompleteValue>()
                    val ordinary = linkedMapOf<String, DataValue>()
                    representation.fields.forEach { field ->
                        val owner = com.typewritermc.types.FieldOwner(field.declarationOwner, field.key)
                        if (owner in defaulted) return@forEach
                        val nestedFindings = mutableListOf<InitializationDiagnostic>()
                        val authoredDefault = startupCaptured[owner] ?: ordinaryDefault(field.type, context, nestedFindings)
                        ordinary[field.key] = authoredDefault
                        val sample = samplingDefault(field.type, authoredDefault, context, nestedFindings)
                        findings += nestedFindings.map { it.prepend(PathSegment.Field(field.key)) }
                        val complete = completeSample(field.type, sample) as? CompletenessResult.Complete
                        if (complete != null) required[owner] = complete.value
                    }
                    val capture =
                        if (descriptor?.mode == InitializationMode.Startup) {
                            CaptureResult.Captured(descriptor.captured.associate { it.field to it.value })
                        } else {
                            bindings.sampleDefaults(checked, SamplingInputs(required))
                        }
                    findings += descriptor?.diagnostics.orEmpty().map { it.atOwnField() }
                    findings +=
                        (capture as? CaptureResult.Unavailable)
                            ?.reasons
                            .orEmpty()
                            .map { it.atOwnField() }
                    val captured = (capture as? CaptureResult.Captured)?.values.orEmpty()
                    DataValue.Record(
                        representation.fields.associate { field ->
                            val owner = com.typewritermc.types.FieldOwner(field.declarationOwner, field.key)
                            field.key to
                                when {
                                    owner in captured -> captured.getValue(owner)
                                    owner in defaulted -> DataValue.Unfilled
                                    else -> ordinary.getValue(field.key)
                                }
                        },
                    )
                }
            }
        return if (payload == DataValue.Unfilled) payload else DataValue.Named(use, payload)
    }

    private fun InitializationDiagnostic.atOwnField(): InitializationDiagnostic =
        if (relativePath != null || field == null) {
            this
        } else {
            copy(relativePath = ValuePath(listOf(PathSegment.Field(requireNotNull(field).name))))
        }

    private fun InitializationDiagnostic.prepend(segment: PathSegment): InitializationDiagnostic =
        copy(relativePath = ValuePath(listOf(segment) + relativePath?.segments.orEmpty()))

    private fun samplingDefault(
        use: TypeUse,
        ordinary: DataValue,
        context: DefaultInitializationContext,
        findings: MutableList<InitializationDiagnostic>,
    ): DataValue {
        if (ordinary != DataValue.Unfilled) return ordinary
        val expected = resolveNamed(use) ?: return ordinary
        val representation = expected.schema.representation as? ResolvedRepresentation.Record ?: return ordinary
        if (!representation.abstract) return ordinary
        val unavailable = mutableListOf<InitializationDiagnostic>()
        catalog.concreteForms(expected).forEach { concrete ->
            val concreteUse = concrete.use as? TypeUse.Named ?: return@forEach
            val candidateFindings = mutableListOf<InitializationDiagnostic>()
            val candidate = ordinaryDefault(concreteUse, context, candidateFindings)
            when (concrete.complete(candidate)) {
                is CompletenessResult.Complete -> {
                    findings += candidateFindings
                    return candidate
                }

                is CompletenessResult.Invalid, is CompletenessResult.Unfinished -> {
                    unavailable += candidateFindings
                }
            }
        }
        findings += unavailable.distinct()
        return ordinary
    }

    private fun completeSample(
        expected: TypeUse,
        value: DataValue,
    ): CompletenessResult? {
        val named = value as? DataValue.Named
        if (named != null && named.actualType != expected) {
            if (!catalog.isReadableAs(named.actualType, expected)) return null
            val actual = resolveNamed(named.actualType) ?: return null
            return actual.complete(value)
        }
        val checked =
            when (val resolution = catalog.resolve(expected)) {
                is Resolution.Invalid -> return null
                is Resolution.Ready -> resolution.value
            }
        return checked.complete(value)
    }

    private fun resolveNamed(use: TypeUse): CheckedType? {
        val named =
            when (use) {
                is TypeUse.Named -> use
                is TypeUse.Nullable -> use.value as? TypeUse.Named
                is TypeUse.Scalar -> null
            } ?: return null
        return when (val resolution = catalog.resolve(named)) {
            is Resolution.Invalid -> null
            is Resolution.Ready -> resolution.value
        }
    }
}

private enum class DefaultEntry {
    Ready,
    Recursive,
    DepthLimit,
}

private class DefaultInitializationContext {
    private val stack = mutableListOf<TypeUse>()

    fun enter(use: TypeUse): DefaultEntry {
        if (stack.size >= MAX_DEFAULT_DEPTH) return DefaultEntry.DepthLimit
        if (use in stack) return DefaultEntry.Recursive
        if (use is TypeUse.Named) {
            val previous = stack.filterIsInstance<TypeUse.Named>().lastOrNull { it.definition == use.definition }
            if (previous != null && !previous.strictlyContains(use)) return DefaultEntry.Recursive
        }
        stack += use
        return DefaultEntry.Ready
    }

    fun exit() {
        stack.removeLast()
    }
}

private fun TypeUse.strictlyContains(candidate: TypeUse): Boolean {
    val pending = ArrayDeque<TypeUse>()
    when (this) {
        is TypeUse.Named -> pending.addAll(arguments)
        is TypeUse.Nullable -> pending += value
        is TypeUse.Scalar -> Unit
    }
    while (pending.isNotEmpty()) {
        when (val current = pending.removeFirst()) {
            candidate -> return true
            is TypeUse.Named -> pending.addAll(current.arguments)
            is TypeUse.Nullable -> pending += current.value
            is TypeUse.Scalar -> Unit
        }
    }
    return false
}

private const val MAX_DEFAULT_DEPTH = 512

fun ScalarKind.authoredDefault(): DataValue =
    when (this) {
        ScalarKind.Unit -> DataValue.Unit
        ScalarKind.Boolean -> DataValue.Boolean(false)
        ScalarKind.Text -> DataValue.StringValue("")
        ScalarKind.Bytes -> DataValue.Bytes(byteArrayOf())
        is ScalarKind.Integer -> DataValue.Integer(BigInteger.ZERO)
        is ScalarKind.Float -> DataValue.Float(0.0)
        ScalarKind.Decimal -> DataValue.Decimal("0")
        ScalarKind.Duration -> DataValue.Duration(kotlin.time.Duration.ZERO)
        ScalarKind.Timestamp -> DataValue.Unfilled
    }

private fun TypeSelection.completeUse(): TypeUse.Named? =
    when (this) {
        is TypeSelection.Complete -> {
            use
        }

        is TypeSelection.Pending -> {
            val chosen = arguments.map { (it as? ArgumentSelection.Chosen)?.type ?: return null }
            TypeUse.Named(definition, chosen)
        }
    }
