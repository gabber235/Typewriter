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
) : InitializationRuntime {
    override suspend fun prepare(request: InitializationRequest): PreparedValue = prepareNow(request)

    fun prepareNow(request: InitializationRequest): PreparedValue {
        if (request.catalog != catalog.generation) {
            return unavailable(request, "catalog_generation_mismatch", "The initialization request uses a different catalog generation.")
        }
        return when (val target = request.target) {
            is PreparationTarget.Value -> prepareValue(request, target.type)
            is PreparationTarget.Record -> prepareRecord(request, target.selection)
        }
    }

    private fun prepareValue(
        request: InitializationRequest,
        type: TypeUse,
    ): PreparedValue {
        val findings = mutableListOf<InitializationDiagnostic>()
        val value = request.supplied ?: ordinaryDefault(type, DefaultInitializationContext(), findings)
        return PreparedValue(PreparedContent.Value(value), findings)
    }

    private fun prepareRecord(
        request: InitializationRequest,
        selection: TypeSelection,
    ): PreparedValue {
        val suppliedFields =
            suppliedRecord(request) ?: return unavailable(request, "invalid_supplied_value", "Record preparation requires a record value.")
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
        rejectUnknownFields(
            request,
            suppliedFields,
            checked.schema.fields.mapTo(linkedSetOf(), com.typewritermc.types.catalog.ResolvedField::key),
        )?.let { return it }
        val prepared = prepareRecordFields(checked, suppliedFields, DefaultInitializationContext())
        return PreparedValue(
            PreparedContent.Record(AuthoringRecord(TypeSelection.Complete(use), prepared.fields)),
            prepared.findings,
        )
    }

    private fun prepareRecordFields(
        checked: CheckedType,
        suppliedFields: Map<String, DataValue>,
        context: DefaultInitializationContext,
    ): RecordPreparation {
        val fields = suppliedFields.toMutableMap()
        val inputs = linkedMapOf<com.typewritermc.types.FieldOwner, CompleteValue>()
        val findings = mutableListOf<InitializationDiagnostic>()
        val blockers = mutableListOf<InitializationDiagnostic>()
        val defaulted = bindings.defaultedFields(checked)
        val omitted =
            checked.schema.fields.filter { field ->
                field.key !in suppliedFields && com.typewritermc.types.FieldOwner(field.declarationOwner, field.key) in defaulted
            }
        checked.schema.fields.forEach { field ->
            val owner = com.typewritermc.types.FieldOwner(field.declarationOwner, field.key)
            if (field.key !in suppliedFields && owner in defaulted) return@forEach
            val fieldFindings = mutableListOf<InitializationDiagnostic>()
            val value =
                suppliedFields[field.key] ?: ordinaryDefault(field.type, context, fieldFindings).also {
                    fields[field.key] = it
                }
            findings += fieldFindings.map { it.prepend(PathSegment.Field(field.key)) }
            if (omitted.isEmpty()) return@forEach
            val admittedValue = value
            when (val result = completeSample(field.type, admittedValue)) {
                is CompletenessResult.Complete -> {
                    inputs[owner] = result.value
                }

                is CompletenessResult.Unfinished -> {
                    blockers +=
                        result.locations.map { location ->
                            InitializationDiagnostic(
                                owner,
                                "unfinished_constructor_input",
                                "A constructor input is unfinished, so omitted defaults cannot be evaluated.",
                                ValuePath(listOf(PathSegment.Field(field.key)) + location.path.segments),
                            )
                        }
                }

                is CompletenessResult.Invalid -> {
                    blockers +=
                        result.problems.map { problem ->
                            InitializationDiagnostic(
                                owner,
                                problem.code,
                                "A constructor input is invalid, so omitted defaults cannot be evaluated.",
                                ValuePath(listOf(PathSegment.Field(field.key)) + problem.location.path.segments),
                            )
                        }
                }

                null -> {
                    blockers +=
                        InitializationDiagnostic(
                            owner,
                            "constructor_input_type_mismatch",
                            "A constructor input does not match its declared type.",
                            ValuePath(listOf(PathSegment.Field(field.key))),
                        )
                }
            }
        }
        val capture =
            when {
                omitted.isEmpty() -> CaptureResult.Captured(emptyMap())
                blockers.isNotEmpty() -> CaptureResult.Unavailable(blockers)
                else -> bindings.sampleDefaults(checked, inputs)
            }
        findings += (capture as? CaptureResult.Unavailable)?.reasons.orEmpty().map { it.atOwnField() }
        val captured = (capture as? CaptureResult.Captured)?.values.orEmpty()
        omitted.forEach { field ->
            val owner = com.typewritermc.types.FieldOwner(field.declarationOwner, field.key)
            fields[field.key] = captured[owner] ?: DataValue.Unfilled
        }
        return RecordPreparation(fields, findings.distinct())
    }

    private fun preparePending(
        request: InitializationRequest,
        selection: TypeSelection.Pending,
    ): PreparedValue {
        val supplied =
            suppliedRecord(request) ?: return unavailable(request, "invalid_supplied_value", "Record preparation requires a record value.")
        val partial =
            when (val resolution = catalog.resolvePartial(selection)) {
                is Resolution.Invalid -> {
                    return unavailable(request, "invalid_type_selection", resolution.diagnostics.joinToString { it.code })
                }

                is Resolution.Ready -> {
                    resolution.value
                }
            }
        val knownKeys = partial.knownFields.mapTo(linkedSetOf(), com.typewritermc.types.catalog.ResolvedField::key)
        val dependentKeys = partial.dependentFields.mapTo(linkedSetOf()) { it.owner.name }
        rejectUnknownFields(request, supplied, knownKeys + dependentKeys)?.let { return it }
        supplied.keys.firstOrNull { it in dependentKeys }?.let { dependent ->
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
        val defaulted = bindings.defaultedFields(selection.definition)
        val findings = mutableListOf<InitializationDiagnostic>()
        val fields = linkedMapOf<String, DataValue>()
        partial.knownFields.forEach { field ->
            val owner = com.typewritermc.types.FieldOwner(field.declarationOwner, field.key)
            val fieldFindings = mutableListOf<InitializationDiagnostic>()
            fields[field.key] =
                supplied[field.key]
                    ?: if (owner in defaulted) {
                        DataValue.Unfilled
                    } else {
                        ordinaryDefault(field.type, DefaultInitializationContext(), fieldFindings)
                    }
            findings += fieldFindings.map { it.prepend(PathSegment.Field(field.key)) }
        }
        partial.dependentFields.forEach { field -> fields[field.owner.name] = DataValue.Unfilled }
        findings +=
            InitializationDiagnostic(
                field = null,
                code = "incomplete_type_selection",
                message = "Initialization left fields that depend on unfinished type arguments unfilled.",
            )
        return PreparedValue(PreparedContent.Record(AuthoringRecord(selection, fields)), findings)
    }

    private fun unavailable(
        request: InitializationRequest,
        code: String,
        message: String,
    ): PreparedValue = unavailable(request, InitializationDiagnostic(null, code, message))

    private fun unavailable(
        request: InitializationRequest,
        diagnostic: InitializationDiagnostic,
    ): PreparedValue =
        PreparedValue(
            when (val target = request.target) {
                is PreparationTarget.Value -> {
                    PreparedContent.Value(request.supplied ?: DataValue.Unfilled)
                }

                is PreparationTarget.Record -> {
                    PreparedContent.Record(AuthoringRecord(target.selection, suppliedRecord(request).orEmpty()))
                }
            },
            listOf(diagnostic),
        )

    private fun rejectUnknownFields(
        request: InitializationRequest,
        supplied: Map<String, DataValue>,
        declared: Set<String>,
    ): PreparedValue? {
        val unknown =
            supplied.keys
                .filterNot(declared::contains)
                .sorted()
        if (unknown.isEmpty()) return null
        return unavailable(
            request,
            "unknown_field",
            "Initialization supplied undeclared fields: ${unknown.joinToString()}.",
        )
    }

    private fun suppliedRecord(request: InitializationRequest): Map<String, DataValue>? =
        when (val value = request.supplied) {
            null -> emptyMap()
            is DataValue.Record -> value.fields
            else -> null
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
                    val prepared = prepareRecordFields(checked, emptyMap(), context)
                    findings += prepared.findings
                    DataValue.Record(prepared.fields)
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

private data class RecordPreparation(
    val fields: Map<String, DataValue>,
    val findings: List<InitializationDiagnostic>,
)

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
