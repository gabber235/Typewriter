package com.typewritermc.authoring

import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.actualType
import com.typewritermc.types.bytes
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.duration
import com.typewritermc.types.field
import com.typewritermc.types.fieldMap
import com.typewritermc.types.fields
import com.typewritermc.types.integer
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.setValue
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ResolvedField
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import java.math.BigInteger

/**
 * Prepares editable values from catalog schemas, supplied content, and generated Kotlin constructor defaults.
 *
 * Ordinary defaults fill values that have no omitted constructor default. Omitted defaults are sampled only when
 * their constructor inputs are complete; otherwise their paths remain deferred in a caller owned continuation.
 * Resumption validates that continuation against this catalog before accepting answers and retrying deferred work.
 * Constructor sampling can execute user code. The runtime keeps no preparation session between calls.
 */
class DefaultInitializationRuntime(
    private val catalog: CheckedCatalog,
    private val bindings: NativeBindingRegistry,
) : InitializationRuntime {
    override suspend fun prepare(request: InitializationRequest): PreparedValue = prepareNow(request)

    override suspend fun step(operation: PreparationOperation): PreparationStep = stepNow(operation)

    /** Evaluates a portable continuation without retaining caller state in this runtime. */
    fun stepNow(operation: PreparationOperation): PreparationStep {
        val request: InitializationRequest
        val context: DefaultInitializationContext
        when (operation) {
            is PreparationOperation.Start -> {
                request = operation.request
                context = DefaultInitializationContext()
            }

            is PreparationOperation.Resume -> {
                val draft = operation.draft.immutableCopy()
                val invalid = validateContinuation(draft, operation.answers)
                if (invalid != null) return PreparationStep.Unavailable(draft.copy(findings = listOf(invalid)))
                var value = draft.content.portableValue()
                for (answer in operation.answers) {
                    value = (value.writeField(answer.path, answer.value) as ValueReplacement.Replaced).value
                }
                request = InitializationRequest(draft.catalog, draft.target, value)
                context = DefaultInitializationContext(draft.pendingDefaults.toSet(), resuming = true)
            }
        }
        val prepared = evaluate(request, context)
        val requirements = requiredInputs(request.target, prepared.content, context.deferred)
        val draft =
            PreparationDraft(
                request.catalog,
                request.target,
                prepared.content,
                context.deferred.toSet(),
                requirements,
                prepared.findings.toList(),
            ).immutableCopy()
        val expected =
            when (val target = request.target) {
                is PreparationTarget.Value -> target.type
                is PreparationTarget.Record -> target.selection.completeUse()?.use
            }
        val failed =
            context.unavailable || expected == null || !admissibleInput(expected, prepared.content.portableValue()) ||
                request.catalog != catalog.generation || requirements.any { catalog.resolve(it.expected) is Resolution.Invalid }
        return when {
            failed -> PreparationStep.Unavailable(draft)
            requirements.isNotEmpty() -> PreparationStep.NeedsInput(draft)
            context.deferred.isNotEmpty() -> PreparationStep.Unavailable(draft)
            else -> PreparationStep.Ready(PreparedValue(draft.content, draft.findings))
        }
    }

    private fun validateContinuation(
        draft: PreparationDraft,
        answers: List<InputAnswer>,
    ): InitializationDiagnostic? {
        fun invalid(message: String) = InitializationDiagnostic(null, "invalid_preparation_continuation", message)
        if (draft.catalog != catalog.generation) return invalid("The preparation catalog changed.")
        when (val target = draft.target) {
            is PreparationTarget.Record -> {
                if ((draft.content as? PreparedContent.Record)?.record?.configuration != target.selection) {
                    return invalid("The prepared record does not match its requested selection.")
                }
            }

            is PreparationTarget.Value -> {
                if (draft.content !is PreparedContent.Value) {
                    return invalid("Value preparation requires value content.")
                }
            }
        }
        val validDefaults = linkedSetOf<ValuePath>()
        walkPrepared(draft.target, draft.content) { path, _, value, owner ->
            if (owner != null && value == DataValue.UNFILLED && owner.second in bindings.defaultedFields(owner.first)) {
                validDefaults += path
            }
        }
        if (!validDefaults.containsAll(draft.pendingDefaults)) return invalid("A pending default is not an omitted constructor field.")
        val required = requiredInputs(draft.target, draft.content, draft.pendingDefaults)
        if ((required.toSet() != draft.requiredInputs.toSet()) ||
            (required.size != draft.requiredInputs.size)
        ) {
            return invalid("The preparation inputs do not match its typed content.")
        }
        if (answers.map { it.path }.toSet().size != answers.size) return invalid("An input was answered more than once.")
        for (answer in answers) {
            val input =
                required.singleOrNull { it.path == answer.path }
                    ?: return invalid("The answer does not belong to a pending input.")
            if (answer.value == DataValue.UNFILLED) return invalid("The answer is unfinished.")
            if (!admissibleInput(input.expected, answer.value)) return invalid("The answer does not match its applied type.")
        }
        return null
    }

    private fun admissibleInput(
        expected: TypeUse,
        value: DataValue,
        depth: Int = 0,
    ): Boolean {
        if (depth > MAX_DEFAULT_DEPTH) return false
        if (value == DataValue.UNFILLED) return true
        if (expected is TypeUse.NullableWrapper) {
            if (value == DataValue.NULL) return true
            return admissibleInput(expected.value.value, value, depth + 1)
        }
        val actual = (value as? DataValue.NamedWrapper)?.actualType?.use ?: expected
        if (!catalog.isReadableAs(actual, expected)) return false
        val checked = (catalog.resolve(actual) as? Resolution.Ready)?.value ?: return false
        val payload = (value as? DataValue.NamedWrapper)?.payload ?: value
        if (payload == DataValue.UNFILLED) return true
        return when (val representation = checked.schema.representation) {
            is ResolvedRepresentation.RecordWrapper -> {
                val record = payload as? DataValue.RecordWrapper ?: return false
                if (representation.value.abstract_) return false
                record.fields.all { supplied ->
                    val field = representation.value.fields.singleOrNull { it.key == supplied.name }
                    field != null && admissibleInput(field.type, supplied.value, depth + 1)
                }
            }

            is ResolvedRepresentation.SequenceWrapper -> {
                val items =
                    when (representation.value.kind) {
                        CollectionKind.LIST -> (payload as? DataValue.ListValueWrapper)?.items
                        CollectionKind.SET -> (payload as? DataValue.SetValueWrapper)?.items
                        else -> unknownVariant(representation.value.kind)
                    } ?: return false
                items.map { it.id }.toSet().size == items.size &&
                    items.all { admissibleInput(representation.value.item, it.value, depth + 1) }
            }

            is ResolvedRepresentation.MappingWrapper -> {
                val rows = (payload as? DataValue.MapValueWrapper)?.rows ?: return false
                rows.map { it.id }.toSet().size == rows.size &&
                    rows.all {
                        admissibleInput(representation.value.key, it.key, depth + 1) &&
                            admissibleInput(representation.value.value, it.value, depth + 1)
                    }
            }

            is ResolvedRepresentation.ScalarWrapper,
            is ResolvedRepresentation.EnumerationWrapper,
            is ResolvedRepresentation.LinkWrapper,
            -> {
                when (completeSample(expected, value)) {
                    is CompletenessResult.Complete, is CompletenessResult.Unfinished -> true
                    is CompletenessResult.Invalid, null -> false
                }
            }

            else -> {
                unknownVariant(representation)
            }
        }
    }

    private fun requiredInputs(
        target: PreparationTarget,
        content: PreparedContent,
        pending: Set<ValuePath>,
    ): List<RequiredInput> {
        val inputs = linkedMapOf<ValuePath, RequiredInput>()
        walkPrepared(target, content) { path, type, value, _ ->
            if ((value == DataValue.UNFILLED || (value is DataValue.NamedWrapper && value.payload == DataValue.UNFILLED)) &&
                path !in pending
            ) {
                inputs[path] = RequiredInput(path, type)
            }
        }
        return inputs.values.toList()
    }

    private fun walkPrepared(
        target: PreparationTarget,
        content: PreparedContent,
        visit: (ValuePath, TypeUse, DataValue, Pair<TypeDefinitionId, FieldOwner>?) -> Unit,
    ) {
        fun walk(
            type: TypeUse,
            value: DataValue,
            path: ValuePath,
            owner: Pair<TypeDefinitionId, FieldOwner>? = null,
        ) {
            visit(path, type, value, owner)
            if (value == DataValue.UNFILLED || value == DataValue.NULL) return
            val actual = (value as? DataValue.NamedWrapper)?.actualType?.use ?: type
            val checked = (catalog.resolve(actual) as? Resolution.Ready)?.value ?: return
            val payload = (value as? DataValue.NamedWrapper)?.payload ?: value
            when (val representation = checked.schema.representation) {
                is ResolvedRepresentation.RecordWrapper -> {
                    val record = payload as? DataValue.RecordWrapper ?: return
                    val definition = (actual as? TypeUse.NamedWrapper)?.value?.definition ?: return
                    representation.value.fields.forEach { field ->
                        walk(
                            field.type,
                            record.field(field.key) ?: DataValue.UNFILLED,
                            path.field(field.key),
                            definition to FieldOwner(definition = field.declarationOwner, name = field.key),
                        )
                    }
                }

                is ResolvedRepresentation.SequenceWrapper -> {
                    val items =
                        when (payload) {
                            is DataValue.ListValueWrapper -> payload.items
                            is DataValue.SetValueWrapper -> payload.items
                            else -> return
                        }
                    items.forEach { walk(representation.value.item, it.value, path.item(it.id)) }
                }

                is ResolvedRepresentation.MappingWrapper -> {
                    (payload as? DataValue.MapValueWrapper)?.rows?.forEach {
                        walk(representation.value.key, it.key, path.item(it.id).append(PathSegment.MapKey))
                        walk(representation.value.value, it.value, path.item(it.id).append(PathSegment.MapValue))
                    }
                }

                is ResolvedRepresentation.ScalarWrapper,
                is ResolvedRepresentation.EnumerationWrapper,
                is ResolvedRepresentation.LinkWrapper,
                -> {}

                else -> {
                    unknownVariant(representation)
                }
            }
        }
        val type =
            when (target) {
                is PreparationTarget.Value -> target.type
                is PreparationTarget.Record -> target.selection.completeUse()?.use
            } ?: return
        walk(type, content.portableValue(), ValuePath())
    }

    private fun resumeValue(
        type: TypeUse,
        value: DataValue,
        context: DefaultInitializationContext,
        findings: MutableList<InitializationDiagnostic>,
        path: ValuePath,
    ): DataValue {
        if (value == DataValue.UNFILLED || value == DataValue.NULL) return value
        val actual = (value as? DataValue.NamedWrapper)?.actualType?.use ?: type
        val checked = (catalog.resolve(actual) as? Resolution.Ready)?.value ?: return value
        val payload = (value as? DataValue.NamedWrapper)?.payload ?: value
        val resumed =
            when (val representation = checked.schema.representation) {
                is ResolvedRepresentation.RecordWrapper -> {
                    val record = payload as? DataValue.RecordWrapper ?: return value
                    if (record.fields.any { supplied -> checked.schema.fields.none { it.key == supplied.name } }) {
                        findings += InitializationDiagnostic(null, "unknown_field", "The continuation contains an undeclared field.", path)
                        return value
                    }
                    val prepared = prepareRecordFields(checked, record.value.fieldMap, context, path)
                    findings += prepared.findings
                    DataValue.record(prepared.fields)
                }

                is ResolvedRepresentation.SequenceWrapper -> {
                    when (payload) {
                        is DataValue.ListValueWrapper -> {
                            DataValue.listValue(
                                payload.items.map {
                                    it.copy(
                                        value = resumeValue(representation.value.item, it.value, context, findings, path.item(it.id)),
                                    )
                                },
                            )
                        }

                        is DataValue.SetValueWrapper -> {
                            DataValue.setValue(
                                payload.items.map {
                                    it.copy(
                                        value = resumeValue(representation.value.item, it.value, context, findings, path.item(it.id)),
                                    )
                                },
                            )
                        }

                        else -> {
                            payload
                        }
                    }
                }

                is ResolvedRepresentation.MappingWrapper -> {
                    when (payload) {
                        is DataValue.MapValueWrapper -> {
                            DataValue.mapValue(
                                payload.rows.map { row ->
                                    row.copy(
                                        key =
                                            resumeValue(
                                                representation.value.key,
                                                row.key,
                                                context,
                                                findings,
                                                path.item(row.id).append(PathSegment.MapKey),
                                            ),
                                        value =
                                            resumeValue(
                                                representation.value.value,
                                                row.value,
                                                context,
                                                findings,
                                                path.item(row.id).append(PathSegment.MapValue),
                                            ),
                                    )
                                },
                            )
                        }

                        else -> {
                            payload
                        }
                    }
                }

                is ResolvedRepresentation.ScalarWrapper,
                is ResolvedRepresentation.EnumerationWrapper,
                is ResolvedRepresentation.LinkWrapper,
                -> {
                    payload
                }

                else -> {
                    unknownVariant(representation)
                }
            }
        return if (value is DataValue.NamedWrapper) DataValue.named(value.actualType, resumed) else resumed
    }

    fun prepareNow(request: InitializationRequest): PreparedValue = evaluate(request, DefaultInitializationContext())

    private fun evaluate(
        request: InitializationRequest,
        context: DefaultInitializationContext,
    ): PreparedValue {
        if (request.catalog != catalog.generation) {
            context.unavailable = true
            return unavailable(request, "catalog_generation_mismatch", "The initialization request uses a different catalog generation.")
        }
        return when (val target = request.target) {
            is PreparationTarget.Value -> prepareValue(request, target.type, context)
            is PreparationTarget.Record -> prepareRecord(request, target.selection, context)
        }
    }

    private fun prepareValue(
        request: InitializationRequest,
        type: TypeUse,
        context: DefaultInitializationContext,
    ): PreparedValue {
        val findings = mutableListOf<InitializationDiagnostic>()
        val value =
            request.supplied?.let {
                if (context.resuming) resumeValue(type, it, context, findings, ValuePath()) else it
            } ?: ordinaryDefault(type, context, findings, ValuePath())
        return PreparedValue(PreparedContent.Value(value), findings)
    }

    private fun prepareRecord(
        request: InitializationRequest,
        selection: TypeSelection,
        context: DefaultInitializationContext,
    ): PreparedValue {
        context.unavailable = true
        val suppliedFields =
            suppliedRecord(request) ?: return unavailable(request, "invalid_supplied_value", "Record preparation requires a record value.")
        if (selection is TypeSelection.Pending) return preparePending(request, selection)
        val use =
            selection.completeUse()
                ?: return unavailable(request, "incomplete_type_selection", "Initialization requires every type argument to be selected.")
        val checked =
            when (val resolution = catalog.resolve(use.use)) {
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
            checked.schema.fields.mapTo(linkedSetOf(), ResolvedField::key),
        )?.let { return it }
        context.unavailable = false
        val prepared = prepareRecordFields(checked, suppliedFields, context, ValuePath())
        return PreparedValue(
            PreparedContent.Record(AuthoringRecord(TypeSelection.Complete(use), prepared.fields)),
            prepared.findings,
        )
    }

    private fun prepareRecordFields(
        checked: CheckedType,
        suppliedFields: Map<String, DataValue>,
        context: DefaultInitializationContext,
        path: ValuePath,
    ): RecordPreparation {
        val fields = suppliedFields.toMutableMap()
        val inputs = linkedMapOf<FieldOwner, CompleteValue>()
        val findings = mutableListOf<InitializationDiagnostic>()
        val blockers = mutableListOf<InitializationDiagnostic>()
        val defaulted = bindings.defaultedFields(checked)
        val omitted =
            checked.schema.fields.filter { field ->
                (field.key !in suppliedFields || path.field(field.key) in context.pending) &&
                    FieldOwner(definition = field.declarationOwner, name = field.key) in defaulted
            }
        checked.schema.fields.forEach { field ->
            val owner = FieldOwner(definition = field.declarationOwner, name = field.key)
            if (field in omitted) return@forEach
            val fieldFindings = mutableListOf<InitializationDiagnostic>()
            val value =
                (
                    suppliedFields[field.key]?.let { supplied ->
                        if (context.resuming) resumeValue(field.type, supplied, context, fieldFindings, path.field(field.key)) else supplied
                    } ?: ordinaryDefault(field.type, context, fieldFindings, path.field(field.key))
                ).also {
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
                    context.unavailable = true
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
                    context.unavailable = true
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
                omitted.isEmpty() -> {
                    CaptureResult.Captured(emptyMap())
                }

                blockers.isNotEmpty() -> {
                    CaptureResult.Unavailable(blockers)
                }

                else -> {
                    bindings.sampleDefaults(checked, inputs).also {
                        if (it is CaptureResult.Unavailable) context.unavailable = true
                    }
                }
            }
        findings += (capture as? CaptureResult.Unavailable)?.reasons.orEmpty().map { it.atOwnField() }
        val captured = (capture as? CaptureResult.Captured)?.values.orEmpty()
        omitted.forEach { field ->
            val owner = FieldOwner(definition = field.declarationOwner, name = field.key)
            fields[field.key] = captured[owner] ?: DataValue.UNFILLED
            if (owner !in captured) context.deferred += path.field(field.key)
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
        val knownKeys = partial.knownFields.mapTo(linkedSetOf(), ResolvedField::key)
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
            val owner = FieldOwner(definition = field.declarationOwner, name = field.key)
            val fieldFindings = mutableListOf<InitializationDiagnostic>()
            fields[field.key] =
                supplied[field.key]
                    ?: if (owner in defaulted) {
                        DataValue.UNFILLED
                    } else {
                        ordinaryDefault(field.type, DefaultInitializationContext(), fieldFindings, ValuePath().field(field.key))
                    }
            findings += fieldFindings.map { it.prepend(PathSegment.Field(field.key)) }
        }
        partial.dependentFields.forEach { field -> fields[field.owner.name] = DataValue.UNFILLED }
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
                    PreparedContent.Value(request.supplied ?: DataValue.UNFILLED)
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
            is DataValue.RecordWrapper -> value.value.fieldMap
            else -> null
        }

    private fun ordinaryDefault(
        use: TypeUse,
        context: DefaultInitializationContext,
        findings: MutableList<InitializationDiagnostic>,
        path: ValuePath,
    ): DataValue {
        when (context.enter(use)) {
            DefaultEntry.Recursive -> {
                context.unavailable = true
                findings +=
                    InitializationDiagnostic(
                        field = null,
                        code = "recursive_default_unavailable",
                        message = "A required recursive value of type $use has no finite ordinary default.",
                    )
                return DataValue.UNFILLED
            }

            DefaultEntry.DepthLimit -> {
                context.unavailable = true
                findings +=
                    InitializationDiagnostic(
                        field = null,
                        code = "default_depth_limit",
                        message = "The ordinary default exceeds the supported nesting depth.",
                    )
                return DataValue.UNFILLED
            }

            DefaultEntry.Ready -> {}
        }
        return try {
            when (use) {
                is TypeUse.NullableWrapper -> DataValue.NULL
                is TypeUse.ScalarWrapper -> use.value.authoredDefault()
                is TypeUse.NamedWrapper -> namedDefault(use.value, context, findings, path)
                else -> unknownVariant(use)
            }
        } finally {
            context.exit()
        }
    }

    private fun namedDefault(
        use: NamedTypeUse,
        context: DefaultInitializationContext,
        findings: MutableList<InitializationDiagnostic>,
        path: ValuePath,
    ): DataValue {
        val checked =
            when (val resolution = catalog.resolve(use.use)) {
                is Resolution.Invalid -> {
                    context.unavailable = true
                    return DataValue.UNFILLED
                }

                is Resolution.Ready -> {
                    resolution.value
                }
            }
        val payload =
            when (val representation = checked.schema.representation) {
                is ResolvedRepresentation.ScalarWrapper -> {
                    representation.value.kind.authoredDefault()
                }

                is ResolvedRepresentation.SequenceWrapper -> {
                    when (representation.value.kind) {
                        CollectionKind.LIST -> DataValue.listValue(emptyList())
                        CollectionKind.SET -> DataValue.setValue(emptyList())
                        else -> unknownVariant(representation.value.kind)
                    }
                }

                is ResolvedRepresentation.MappingWrapper -> {
                    DataValue.mapValue(emptyList())
                }

                is ResolvedRepresentation.EnumerationWrapper -> {
                    representation.value.cases
                        .firstOrNull()
                        ?.let { DataValue.EnumCaseWrapper(it.key) } ?: DataValue.UNFILLED
                }

                is ResolvedRepresentation.LinkWrapper -> {
                    DataValue.UNFILLED
                }

                is ResolvedRepresentation.RecordWrapper -> {
                    if (representation.value.abstract_) return DataValue.UNFILLED
                    val prepared = prepareRecordFields(checked, emptyMap(), context, path)
                    findings += prepared.findings
                    DataValue.record(prepared.fields)
                }

                else -> {
                    unknownVariant(representation)
                }
            }
        return if (payload == DataValue.UNFILLED) payload else DataValue.named(use, payload)
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
        val named = value as? DataValue.NamedWrapper
        if (named != null && named.actualType.use != expected) {
            if (!catalog.isReadableAs(named.actualType.use, expected)) return null
            val actual = resolveNamed(named.actualType.use) ?: return null
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
                is TypeUse.NamedWrapper -> use
                is TypeUse.NullableWrapper -> use.value.value as? TypeUse.NamedWrapper
                is TypeUse.ScalarWrapper -> null
                else -> unknownVariant(use)
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

private class DefaultInitializationContext(
    val pending: Set<ValuePath> = emptySet(),
    val resuming: Boolean = false,
) {
    val deferred = linkedSetOf<ValuePath>()
    var unavailable = false
    private val stack = mutableListOf<TypeUse>()

    fun enter(use: TypeUse): DefaultEntry {
        if (stack.size >= MAX_DEFAULT_DEPTH) return DefaultEntry.DepthLimit
        if (use in stack) return DefaultEntry.Recursive
        if (use is TypeUse.NamedWrapper) {
            val previous = stack.filterIsInstance<TypeUse.NamedWrapper>().lastOrNull { it.value.definition == use.value.definition }
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
        is TypeUse.NamedWrapper -> pending.addAll(value.arguments)
        is TypeUse.NullableWrapper -> pending += value.value
        is TypeUse.ScalarWrapper -> Unit
        else -> unknownVariant(this)
    }
    while (pending.isNotEmpty()) {
        when (val current = pending.removeFirst()) {
            candidate -> return true
            is TypeUse.NamedWrapper -> pending.addAll(current.value.arguments)
            is TypeUse.NullableWrapper -> pending += current.value.value
            is TypeUse.ScalarWrapper -> Unit
            else -> unknownVariant(current)
        }
    }
    return false
}

private const val MAX_DEFAULT_DEPTH = 512

fun ScalarKind.authoredDefault(): DataValue =
    when (this) {
        ScalarKind.UNIT -> DataValue.UNIT
        ScalarKind.BOOLEAN -> DataValue.BooleanWrapper(false)
        ScalarKind.TEXT -> DataValue.StringValueWrapper("")
        ScalarKind.BYTES -> DataValue.bytes(byteArrayOf())
        is ScalarKind.IntegerWrapper -> DataValue.integer(BigInteger.ZERO)
        is ScalarKind.FloatWrapper -> DataValue.FloatWrapper(0.0)
        ScalarKind.DECIMAL -> DataValue.DecimalWrapper("0")
        ScalarKind.DURATION -> DataValue.duration(kotlin.time.Duration.ZERO)
        ScalarKind.TIMESTAMP -> DataValue.UNFILLED
        else -> unknownVariant(this)
    }

private fun TypeSelection.completeUse(): NamedTypeUse? =
    when (this) {
        is TypeSelection.Complete -> {
            use
        }

        is TypeSelection.Pending -> {
            val chosen = arguments.map { (it as? ArgumentSelection.Chosen)?.type ?: return null }
            definition.namedUse(chosen)
        }
    }

private fun PreparedContent.portableValue(): DataValue =
    when (this) {
        is PreparedContent.Value -> value
        is PreparedContent.Record -> DataValue.record(record.fields)
    }
