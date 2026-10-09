package com.typewritermc.realm.authoring

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.CheckedWriteResult
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.ConnectIntent
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftEdits
import com.typewritermc.authoring.DraftView
import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.EditPreparationId
import com.typewritermc.authoring.EditablePath
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InitializationRequestId
import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.LocatedInitializationDiagnostic
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparationTarget
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.PreparedEditResult
import com.typewritermc.authoring.PreparedValue
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.StructuralResult
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.authoring.authoredDefault
import com.typewritermc.authoring.validateStructure
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.TypedSelection
import com.typewritermc.realm.checking.CapturedAuthoringReads
import com.typewritermc.realm.checking.DefaultObservationRecorder
import com.typewritermc.realm.checking.SnapshotReadCapability
import com.typewritermc.realm.repository.AuthoringMutationPlan
import com.typewritermc.realm.repository.AuthoringMutationPlanner
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.MutationPlanningResult
import com.typewritermc.realm.repository.canonicalPreparedIntentDigest
import com.typewritermc.realm.repository.requiredExpectations
import com.typewritermc.types.DataValue
import com.typewritermc.types.ListItem
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingException
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import kotlinx.serialization.encodeToString
import java.security.MessageDigest
import java.util.UUID

internal sealed interface ParentMaterialization {
    data class Ready(
        val value: DataValue.Named,
    ) : ParentMaterialization

    data class NeedsInput(
        val at: ValueLocation,
    ) : ParentMaterialization

    data class Rejected(
        val problem: ValueProblem,
    ) : ParentMaterialization
}

internal fun interface ParentMaterializer {
    fun materialize(
        catalog: AuthoringCatalogLease,
        containing: TypeDefinitionId,
        field: com.typewritermc.types.catalog.ResolvedField,
        expected: TypeUse.Named,
        at: ValueLocation,
    ): ParentMaterialization
}

internal class RealmDraftEdits(
    private val snapshots: AuthoringViewStore,
    private val repository: AuthoringRepository,
    private val parentMaterializer: ParentMaterializer = CatalogParentMaterializer,
    private val creation: InitializationRuntime? = null,
) : DraftEdits {
    override suspend fun DraftView.prepareEdit(
        id: EditPreparationId,
        block: suspend EditContext.() -> Unit,
    ): PreparedEditResult {
        val lease = snapshots.retain(readContext)
        try {
            if (catalog != lease.root.catalog.generation) {
                return PreparedEditResult.Rejected(listOf(ValueProblem(location, "catalog_changed")))
            }
            val context = RealmEditContext(lease, id, creation, parentMaterializer)
            context.block()
            return context.prepare()
        } finally {
            lease.close()
        }
    }

    override suspend fun commit(edit: PreparedEdit): CommitResult = repository.commit(edit)
}

private class RealmEditContext(
    private val lease: AuthoringLease,
    private val preparation: EditPreparationId,
    private val creation: InitializationRuntime?,
    private val parentMaterializer: ParentMaterializer,
) : EditContext,
    SnapshotReadCapability {
    private val recorder = DefaultObservationRecorder()
    private val intents = mutableListOf<EditIntent>()
    private val problems = mutableListOf<ValueProblem>()
    private val needsInput = linkedSetOf<ValueLocation>()
    private val initializationFindings = mutableListOf<LocatedInitializationDiagnostic>()
    private val materializationOccurrences = mutableMapOf<Pair<ValueLocation, String>, Int>()
    private val original = lease.root.resources
    private val editReadContext = lease.root.readContext
    private val planner =
        AuthoringMutationPlanner(
            lease.root.catalog.checked,
            lease.root.catalog.relations,
            lease.root.catalog.endpointBindings,
        )
    private var staged = original
    private var reads = CapturedAuthoringReads(lease.originalView(), recorder, readContext = editReadContext)

    override val snapshotReads: CapturedAuthoringReads
        get() = reads

    override val catalog get() = reads.catalog
    override val readContext: ReadContext get() = reads.readContext

    override fun <T> read(path: BoundPath<T>): Availability<T> = reads.read(path)

    override fun <T> readRepresentation(
        path: BoundPath<*>,
        representation: TypeUse,
    ): Availability<T> = reads.readRepresentation(path, representation)

    override fun presence(path: BoundPath<*>): Availability<Boolean> = reads.presence(path)

    override fun binding(path: BoundPath<*>): Availability<DraftBinding> = reads.binding(path)

    override fun canonicalValueKey(path: BoundPath<*>): Availability<String> = reads.canonicalValueKey(path)

    override fun members(path: BoundCollectionPath): List<ItemId> = reads.members(path)

    override fun <D> select(query: TypedSelection<D>): PartialSelection<D> = reads.select(query)

    override suspend fun create(
        id: ResourceId,
        record: AuthoringRecord,
    ) {
        append(EditIntent.CreateResource(id, record))
    }

    override suspend fun delete(id: ResourceId) {
        append(EditIntent.DeleteResource(id))
    }

    override suspend fun <V> set(
        path: EditablePath<V>,
        value: V,
    ) {
        val actual = validate(path) ?: return
        val checked =
            lease.root.catalog.checked
                .resolve(actual) as? Resolution.Ready
        if (checked == null) {
            problems += ValueProblem(path.location, "unresolved_write_type")
            return
        }
        val encoded =
            try {
                lease.root.catalog.nativeBindings
                    .bind(checked.value)
                    .encodeAny(value)
            } catch (failure: NativeBindingException) {
                problems += ValueProblem(path.location, failure.code)
                return
            }
        write(path.location, encoded)
    }

    override suspend fun <V> clear(path: EditablePath<V>) {
        val type = validate(path) ?: return
        write(path.location, if (type is TypeUse.Nullable) DataValue.Null else DataValue.Unfilled)
    }

    private fun validate(path: EditablePath<*>): TypeUse? {
        if (path.binding.readContext !== readContext) {
            problems += ValueProblem(path.location, "edit_context_mismatch")
            return null
        }
        reads.observeInput(InputIdentity.Form(path.binding.location))
        val actual = staged[path.location.resource]?.authoredTypeAt(path.location.path, lease.root.catalog.checked)
        if (actual != path.expected) {
            problems += ValueProblem(path.location, "write_type_mismatch")
            return null
        }
        return actual
    }

    override suspend fun insert(
        path: BoundCollectionPath,
        after: ItemId?,
        value: DataValue,
    ): ItemId {
        val id = ItemId("item:${UUID.randomUUID()}")
        append(EditIntent.Insert(path.location, after, ListItem(id, value)))
        return id
    }

    override suspend fun remove(
        path: BoundCollectionPath,
        item: ItemId,
    ) {
        append(EditIntent.Remove(path.location, item))
    }

    override suspend fun move(
        path: BoundCollectionPath,
        item: ItemId,
        after: ItemId?,
    ) {
        append(EditIntent.Move(path.location, item, after))
    }

    override suspend fun connect(intent: ConnectIntent) {
        append(EditIntent.ConnectRelation(intent))
    }

    override suspend fun disconnect(occurrence: LinkOccurrenceId) {
        append(EditIntent.DisconnectRelation(occurrence))
    }

    override suspend fun retag(
        at: ValueLocation,
        type: TypeUse.Named,
    ) {
        append(EditIntent.Retag(at, type))
    }

    override suspend fun checkedSet(
        path: ValueLocation,
        value: DataValue,
    ): CheckedWriteResult {
        val intentCount = intents.size
        val priorProblems = problems.toList()
        val priorNeedsInput = needsInput.toSet()
        write(path, value)
        val writeProblems = problems.drop(priorProblems.size)
        val writeNeedsInput = needsInput - priorNeedsInput
        if (writeProblems.isNotEmpty() || writeNeedsInput.isNotEmpty()) {
            rollbackCheckedWrite(intentCount, priorProblems, priorNeedsInput)
            return CheckedWriteResult.Rejected(
                writeProblems + writeNeedsInput.map { ValueProblem(it, "parent_needs_input") },
            )
        }
        val planned = plan()
        if (planned is MutationPlanningResult.Rejected) {
            rollbackCheckedWrite(intentCount, priorProblems, priorNeedsInput)
            return CheckedWriteResult.Rejected(planned.problems)
        }
        return CheckedWriteResult.Applied
    }

    private fun rollbackCheckedWrite(
        intentCount: Int,
        priorProblems: List<ValueProblem>,
        priorNeedsInput: Set<ValueLocation>,
    ) {
        while (intents.size > intentCount) intents.removeLast()
        problems.clear()
        problems += priorProblems
        needsInput.clear()
        needsInput += priorNeedsInput
        refresh()
    }

    fun prepare(): PreparedEditResult {
        val locatedFindings = initializationFindings.toList()
        if (needsInput.isNotEmpty()) return PreparedEditResult.NeedsInput(needsInput.toList(), locatedFindings)
        if (problems.isNotEmpty()) return PreparedEditResult.Rejected(problems.distinct(), locatedFindings)
        val witness =
            PreparedEdit(
                catalog = lease.root.catalog.generation,
                expectations = emptyList(),
                intents = intents.toList(),
            )
        val planned = plan()
        if (planned is MutationPlanningResult.Rejected) {
            val choices =
                planned.problems
                    .filter { it.code == "counterpart_choice_required" }
                    .mapTo(linkedSetOf(), ValueProblem::location)
            if (choices.isNotEmpty()) return PreparedEditResult.NeedsInput(choices.toList(), locatedFindings)
            return PreparedEditResult.Rejected(planned.problems, locatedFindings)
        }
        val required =
            lease.root.values.requiredExpectations(
                witness,
                original,
                lease.root.catalog.relations.mapTo(linkedSetOf()) {
                    it.id
                },
                (planned as MutationPlanningResult.Accepted).plan,
            )
        required.forEach(recorder::observe)
        return PreparedEditResult.Prepared(witness.copy(expectations = recorder.captured()), locatedFindings)
    }

    private suspend fun write(
        location: ValueLocation,
        value: DataValue,
    ) {
        while (true) {
            when (val missing = staged.missingParent(location, lease.root.catalog.checked)) {
                null -> {
                    break
                }

                is MissingParent.Item -> {
                    problems += ValueProblem(missing.at, "item_missing")
                    return
                }

                is MissingParent.Value -> {
                    when (
                        val materialized =
                            parentMaterializer.materialize(
                                lease.root.catalog,
                                missing.containing,
                                missing.field,
                                missing.expected,
                                missing.at,
                            )
                    ) {
                        is ParentMaterialization.Ready -> {
                            append(EditIntent.SetValue(missing.at, materialized.value))
                        }

                        is ParentMaterialization.NeedsInput -> {
                            val priorProblems = problems.size
                            val dynamic = materializeDynamic(missing)
                            if (dynamic == null) {
                                if (problems.size == priorProblems) needsInput += materialized.at
                                return
                            }
                            append(EditIntent.SetValue(missing.at, dynamic))
                        }

                        is ParentMaterialization.Rejected -> {
                            problems += materialized.problem
                            return
                        }
                    }
                }
            }
        }
        append(EditIntent.SetValue(location, value))
    }

    private suspend fun materializeDynamic(missing: MissingParent.Value): DataValue.Named? {
        val runtime = creation ?: return null
        val containing = missing.containingType
        if (containing != null && missing.containingFields != null) {
            val descriptor =
                lease.root.catalog.initialization
                    .singleOrNull { it.definition == containing.definition }
            if (descriptor?.mode == com.typewritermc.authoring.InitializationMode.Creation) {
                val containingLocation = missing.containingLocation()
                reads.observeInput(InputIdentity.Form(containingLocation))
                reads.observeInput(InputIdentity.Value(containingLocation))
                val prepared =
                    runtime.prepare(
                        initializationRequest(
                            missing = missing,
                            type = containing,
                            supplied = missing.containingFields - missing.field.key,
                            suffix = "containing",
                        ),
                    )
                if (!acceptPreparedValue(prepared, containing, containingLocation)) return null
                val record = (prepared.content as PreparedContent.Record).record
                val authoredField = record.fields.getValue(missing.field.key)
                val fieldValue = authoredField as? DataValue.Named
                if (fieldValue != null &&
                    lease.root.catalog.checked
                        .isReadableAs(fieldValue.actualType, missing.expected)
                ) {
                    return fieldValue
                }
                if (authoredField == DataValue.Unfilled) {
                    needsInput += missing.at
                    return null
                }
                problems += ValueProblem(missing.at, "initialization_field_type_mismatch")
                return null
            }
        }
        val descriptor =
            lease.root.catalog.initialization
                .singleOrNull { it.definition == missing.expected.definition }
        if (descriptor?.mode != com.typewritermc.authoring.InitializationMode.Creation) return null
        val prepared =
            runtime.prepare(
                initializationRequest(
                    missing = missing,
                    type = missing.expected,
                    supplied = emptyMap(),
                    suffix = "child",
                ),
            )
        if (!acceptPreparedValue(prepared, missing.expected, missing.at)) return null
        val record = (prepared.content as PreparedContent.Record).record
        return DataValue.Named(missing.expected, DataValue.Record(record.fields))
    }

    private fun acceptPreparedValue(
        prepared: PreparedValue,
        expected: TypeUse.Named,
        base: ValueLocation,
    ): Boolean {
        initializationFindings +=
            prepared.findings.map { finding ->
                val location =
                    finding.relativePath?.let { relative ->
                        base.copy(path = ValuePath(base.path.segments + relative.segments))
                    } ?: base
                LocatedInitializationDiagnostic(location, finding)
            }
        val record = (prepared.content as? PreparedContent.Record)?.record
        if (record == null || record.configuration != TypeSelection.Complete(expected)) {
            problems += ValueProblem(base, "initialization_configuration_mismatch")
            return false
        }
        return when (val structural = record.validateStructure(lease.root.catalog.checked)) {
            StructuralResult.Valid -> {
                true
            }

            is StructuralResult.Invalid -> {
                problems +=
                    structural.problems.map { problem ->
                        ValueProblem(
                            base.copy(
                                path = ValuePath(base.path.segments + problem.location.path.segments),
                            ),
                            problem.code,
                        )
                    }
                false
            }
        }
    }

    private fun MissingParent.Value.containingLocation(): ValueLocation = at.copy(path = ValuePath(at.path.segments.dropLast(1)))

    private fun initializationRequest(
        missing: MissingParent.Value,
        type: TypeUse.Named,
        supplied: Map<String, DataValue>,
        suffix: String,
    ): InitializationRequest {
        val location = authoringStorageJson.encodeToString(ValueLocation.serializer(), missing.at)
        val locationDigest = location.sha256()
        val occurrenceKey = missing.at to suffix
        val occurrence = materializationOccurrences.getOrDefault(occurrenceKey, 0)
        materializationOccurrences[occurrenceKey] = occurrence + 1
        val prefix =
            canonicalPreparedIntentDigest(
                PreparedEdit(
                    catalog = lease.root.catalog.generation,
                    expectations = recorder.captured(),
                    intents = intents.toList(),
                ),
            )
        return InitializationRequest(
            id = InitializationRequestId("${preparation.value}:$locationDigest:$suffix:$occurrence"),
            catalog = lease.root.catalog.generation,
            target = PreparationTarget.Record(TypeSelection.Complete(type)),
            supplied = DataValue.Record(supplied),
            intentHash = "$prefix:$locationDigest:$suffix",
        )
    }

    private fun append(intent: EditIntent) {
        intents += intent
        refresh(intent)
    }

    private fun refresh(fallback: EditIntent? = null) {
        when (val result = plan()) {
            is MutationPlanningResult.Accepted -> staged = original.apply(result.plan)
            is MutationPlanningResult.Rejected -> if (fallback != null) staged = staged.applyLocally(fallback)
        }
        val changed = staged.filter { (id, value) -> original[id] != value }
        val removed = original.keys - staged.keys
        reads = CapturedAuthoringReads(lease.stagedView(changed, removed), recorder, readContext = editReadContext)
    }

    private fun plan(): MutationPlanningResult =
        planner.plan(
            original,
            PreparedEdit(
                lease.root.catalog.generation,
                emptyList(),
                intents,
            ),
        )
}

private object CatalogParentMaterializer : ParentMaterializer {
    override fun materialize(
        catalog: AuthoringCatalogLease,
        containing: TypeDefinitionId,
        field: com.typewritermc.types.catalog.ResolvedField,
        expected: TypeUse.Named,
        at: ValueLocation,
    ): ParentMaterialization {
        val owner = com.typewritermc.types.FieldOwner(field.declarationOwner, field.key)
        val containingDefault =
            catalog.initialization
                .singleOrNull { it.definition == containing }
                ?.captured
                ?.singleOrNull { it.field == owner }
                ?.value
        val captured = containingDefault as? DataValue.Named
        if (captured != null && catalog.checked.isReadableAs(captured.actualType, expected)) {
            return ParentMaterialization.Ready(captured)
        }
        val containingDescriptor = catalog.initialization.singleOrNull { it.definition == containing }
        if (containingDescriptor?.mode == com.typewritermc.authoring.InitializationMode.Creation) {
            return ParentMaterialization.NeedsInput(at)
        }
        val descriptor = catalog.initialization.singleOrNull { it.definition == expected.definition }
        if (descriptor?.mode == com.typewritermc.authoring.InitializationMode.Creation) {
            return ParentMaterialization.NeedsInput(at)
        }
        val checked =
            (catalog.checked.resolve(expected) as? Resolution.Ready)?.value
                ?: return ParentMaterialization.Rejected(ValueProblem(at, "unresolved_parent_type"))
        val representation =
            checked.schema.representation as? ResolvedRepresentation.Record
                ?: return ParentMaterialization.Rejected(ValueProblem(at, "parent_is_not_record"))
        if (representation.abstract) return ParentMaterialization.NeedsInput(at)
        return ParentMaterialization.Ready(recordDefault(expected, representation, catalog, setOf(expected)))
    }
}

private fun typeDefault(
    type: TypeUse,
    catalog: AuthoringCatalogLease,
    visiting: Set<TypeUse.Named>,
): DataValue {
    return when (type) {
        is TypeUse.Nullable -> {
            DataValue.Null
        }

        is TypeUse.Scalar -> {
            type.kind.authoredDefault()
        }

        is TypeUse.Named -> {
            if (type in visiting) return DataValue.Unfilled
            val checked = (catalog.checked.resolve(type) as? Resolution.Ready)?.value ?: return DataValue.Unfilled
            when (val representation = checked.schema.representation) {
                is ResolvedRepresentation.Scalar -> {
                    val payload = representation.kind.authoredDefault()
                    if (payload == DataValue.Unfilled) payload else DataValue.Named(type, payload)
                }

                is ResolvedRepresentation.Sequence -> {
                    DataValue.Named(
                        type,
                        if (representation.kind == com.typewritermc.types.CollectionKind.List) {
                            DataValue.ListValue(emptyList())
                        } else {
                            DataValue.SetValue(emptyList())
                        },
                    )
                }

                is ResolvedRepresentation.Mapping -> {
                    DataValue.Named(type, DataValue.MapValue(emptyList()))
                }

                is ResolvedRepresentation.Enumeration -> {
                    representation.cases.firstOrNull()?.let { DataValue.Named(type, DataValue.EnumCase(it.key)) }
                        ?: DataValue.Unfilled
                }

                is ResolvedRepresentation.Link -> {
                    DataValue.Unfilled
                }

                is ResolvedRepresentation.Record -> {
                    if (representation.abstract) return DataValue.Unfilled
                    val descriptor = catalog.initialization.singleOrNull { it.definition == type.definition }
                    if (descriptor?.mode == com.typewritermc.authoring.InitializationMode.Creation) {
                        DataValue.Unfilled
                    } else {
                        recordDefault(type, representation, catalog, visiting + type)
                    }
                }
            }
        }
    }
}

private fun recordDefault(
    type: TypeUse.Named,
    representation: ResolvedRepresentation.Record,
    catalog: AuthoringCatalogLease,
    visiting: Set<TypeUse.Named>,
): DataValue.Named {
    val descriptor = catalog.initialization.singleOrNull { it.definition == type.definition }
    val capturedFields = descriptor?.captured.orEmpty().associate { it.field to it.value }
    val defaultedFields =
        catalog.providers
            .nativeBindings()
            .singleOrNull { it.factory.definition == type.definition }
            ?.factory
            ?.constructionPlan
            ?.defaultedFields
            .orEmpty()
    val unavailableDefaults = descriptor?.diagnostics.orEmpty().mapNotNullTo(hashSetOf()) { it.field }
    val fields =
        representation.fields.associate { field ->
            val owner = com.typewritermc.types.FieldOwner(field.declarationOwner, field.key)
            val value =
                capturedFields[owner]
                    ?: if (owner in defaultedFields || owner in unavailableDefaults) {
                        DataValue.Unfilled
                    } else {
                        typeDefault(field.type, catalog, visiting)
                    }
            field.key to value
        }
    return DataValue.Named(type, DataValue.Record(fields))
}

private sealed interface MissingParent {
    data class Value(
        val at: ValueLocation,
        val containing: TypeDefinitionId,
        val containingType: TypeUse.Named?,
        val containingFields: Map<String, DataValue>?,
        val field: com.typewritermc.types.catalog.ResolvedField,
        val expected: TypeUse.Named,
    ) : MissingParent

    data class Item(
        val at: ValueLocation,
    ) : MissingParent
}

private fun Map<ResourceId, AuthoringRecord>.missingParent(
    target: ValueLocation,
    catalog: CheckedCatalog,
): MissingParent? {
    val record = this[target.resource] ?: return null
    val parentSegments = target.path.segments.dropLast(1)
    if (parentSegments.isEmpty()) return null
    var type: TypeUse
    var value: DataValue = DataValue.Record(record.fields)
    var at = ValueLocation(target.resource, ValuePath())
    var mapping: ResolvedRepresentation.Mapping? = null
    var mapRow: com.typewritermc.types.MapRow? = null
    var remaining = parentSegments
    when (val selection = record.configuration) {
        is TypeSelection.Complete -> {
            type = selection.use
        }

        is TypeSelection.Pending -> {
            val first = remaining.first() as? PathSegment.Field ?: return null
            val partial = (catalog.resolvePartial(selection) as? Resolution.Ready)?.value ?: return null
            val field = partial.knownFields.singleOrNull { it.key == first.name } ?: return null
            at = at.append(first)
            val child = record.fields[first.name] ?: return null
            if (child == DataValue.Unfilled || child == DataValue.Null) {
                val expected = field.type.concreteNamed() ?: return MissingParent.Item(at)
                return MissingParent.Value(at, selection.definition, null, record.fields, field, expected)
            }
            type = (child as? DataValue.Named)?.actualType ?: field.type
            value = child
            remaining = remaining.drop(1)
        }
    }
    remaining.forEach { segment ->
        val pendingMapping = mapping
        if (pendingMapping != null) {
            type =
                when (segment) {
                    PathSegment.MapKey -> pendingMapping.key
                    PathSegment.MapValue -> pendingMapping.value
                    else -> return MissingParent.Item(at.append(segment))
                }
            value =
                when (segment) {
                    PathSegment.MapKey -> mapRow?.key
                    PathSegment.MapValue -> mapRow?.value
                    is PathSegment.Field, is PathSegment.Item -> null
                } ?: return MissingParent.Item(at.append(segment))
            at = at.append(segment)
            type = (value as? DataValue.Named)?.actualType ?: type
            mapping = null
            mapRow = null
            return@forEach
        }
        val traversable = if (type is TypeUse.Nullable) type.value else type
        val checked = (catalog.resolve(traversable) as? Resolution.Ready)?.value ?: return null
        when (segment) {
            is PathSegment.Field -> {
                val field = checked.schema.fields.singleOrNull { it.key == segment.name } ?: return null
                at = at.append(segment)
                val child = (value.unwrapNamed() as? DataValue.Record)?.fields?.get(segment.name) ?: return null
                if (child == DataValue.Unfilled || child == DataValue.Null) {
                    val expected = field.type.concreteNamed() ?: return MissingParent.Item(at)
                    val containing = (checked.use as? TypeUse.Named)?.definition ?: field.declarationOwner
                    val containingType = checked.use as? TypeUse.Named
                    val containingFields = value.unwrapNamed() as? DataValue.Record
                    return MissingParent.Value(
                        at,
                        containing,
                        containingType,
                        containingFields?.fields,
                        field,
                        expected,
                    )
                }
                type = (child as? DataValue.Named)?.actualType ?: field.type
                value = child
            }

            is PathSegment.Item -> {
                at = at.append(segment)
                when (val representation = checked.schema.representation) {
                    is ResolvedRepresentation.Sequence -> {
                        val child =
                            when (val collection = value.unwrapNamed()) {
                                is DataValue.ListValue -> collection.items.singleOrNull { it.id == segment.id }?.value
                                is DataValue.SetValue -> collection.items.singleOrNull { it.id == segment.id }?.value
                                else -> null
                            } ?: return MissingParent.Item(at)
                        type = (child as? DataValue.Named)?.actualType ?: representation.item
                        value = child
                    }

                    is ResolvedRepresentation.Mapping -> {
                        mapping = representation
                        mapRow =
                            (value.unwrapNamed() as? DataValue.MapValue)
                                ?.rows
                                ?.singleOrNull { it.id == segment.id }
                                ?: return MissingParent.Item(at)
                    }

                    else -> {
                        return MissingParent.Item(at)
                    }
                }
            }

            PathSegment.MapKey, PathSegment.MapValue -> {
                return MissingParent.Item(at.append(segment))
            }
        }
    }
    return null
}

private fun Map<ResourceId, AuthoringRecord>.apply(plan: AuthoringMutationPlan): Map<ResourceId, AuthoringRecord> =
    (this + plan.resources) - plan.removedResources

private fun Map<ResourceId, AuthoringRecord>.applyLocally(intent: EditIntent): Map<ResourceId, AuthoringRecord> =
    when (intent) {
        is EditIntent.CreateResource -> {
            this + (intent.id to intent.record)
        }

        is EditIntent.DeleteResource -> {
            this - intent.id
        }

        is EditIntent.SetValue -> {
            update(intent.at) { intent.value }
        }

        is EditIntent.Insert -> {
            update(intent.at) { current ->
                current.mutateItems { items ->
                    val index = intent.after?.let { anchor -> items.indexOfFirst { it.id == anchor }.takeIf { it >= 0 }?.plus(1) } ?: 0
                    if (index < 0) null else items.toMutableList().also { it.add(index, intent.item) }
                }
            }
        }

        is EditIntent.Remove -> {
            update(intent.at) { it.mutateItems { items -> items.filterNot { item -> item.id == intent.item } } }
        }

        is EditIntent.Move -> {
            this
        }

        is EditIntent.Retag -> {
            update(intent.at) { value -> (value as? DataValue.Named)?.copy(actualType = intent.type) }
        }

        is EditIntent.ConfigureResource -> {
            this[intent.resource]?.let { record ->
                this + (intent.resource to record.copy(configuration = intent.configuration))
            } ?: this
        }

        is EditIntent.ConnectRelation, is EditIntent.DisconnectRelation -> {
            this
        }
    }

private fun Map<ResourceId, AuthoringRecord>.update(
    at: ValueLocation,
    transform: (DataValue) -> DataValue?,
): Map<ResourceId, AuthoringRecord> {
    val record = this[at.resource] ?: return this
    val current = DataValue.Record(record.fields).valueAt(at.path.segments) ?: return this
    val replacement = transform(current) ?: return this
    val root = DataValue.Record(record.fields).set(at.path.segments, replacement) as? DataValue.Record ?: return this
    return this + (at.resource to record.copy(fields = root.fields))
}

private fun DataValue.valueAt(segments: List<PathSegment>): DataValue? {
    if (segments.isEmpty()) return this
    return child(segments.first())?.valueAt(segments.drop(1))
}

private fun DataValue.child(segment: PathSegment): DataValue? {
    val current = unwrapNamed()
    return when (segment) {
        is PathSegment.Field -> {
            (current as? DataValue.Record)?.fields?.get(segment.name)
        }

        is PathSegment.Item -> {
            when (current) {
                is DataValue.ListValue -> {
                    current.items.singleOrNull { it.id == segment.id }?.value
                }

                is DataValue.SetValue -> {
                    current.items.singleOrNull { it.id == segment.id }?.value
                }

                is DataValue.MapValue -> {
                    current.rows.singleOrNull { it.id == segment.id }?.let {
                        DataValue.Record(mapOf("key" to it.key, "value" to it.value))
                    }
                }

                else -> {
                    null
                }
            }
        }

        PathSegment.MapKey -> {
            (current as? DataValue.Record)?.fields?.get("key")
        }

        PathSegment.MapValue -> {
            (current as? DataValue.Record)?.fields?.get("value")
        }
    }
}

private fun DataValue.set(
    segments: List<PathSegment>,
    replacement: DataValue,
): DataValue? {
    if (segments.isEmpty()) return replacement
    if (this is DataValue.Named) return copy(payload = payload.set(segments, replacement) ?: return null)
    val head = segments.first()
    val tail = segments.drop(1)
    return when (head) {
        is PathSegment.Field -> {
            val record = this as? DataValue.Record ?: return null
            val child = record.fields[head.name]
            if (child == null && tail.isEmpty()) return record.copy(fields = record.fields + (head.name to replacement))
            val changed = child?.set(tail, replacement) ?: return null
            record.copy(fields = record.fields + (head.name to changed))
        }

        is PathSegment.Item -> {
            when (this) {
                is DataValue.ListValue -> {
                    copy(items = items.replace(head.id, tail, replacement) ?: return null)
                }

                is DataValue.SetValue -> {
                    copy(items = items.replace(head.id, tail, replacement) ?: return null)
                }

                is DataValue.MapValue -> {
                    val index = rows.indexOfFirst { it.id == head.id }
                    if (index < 0) return null
                    val row = rows[index]
                    val changed =
                        when (tail.firstOrNull()) {
                            PathSegment.MapKey -> row.copy(key = row.key.set(tail.drop(1), replacement) ?: return null)
                            PathSegment.MapValue -> row.copy(value = row.value.set(tail.drop(1), replacement) ?: return null)
                            else -> return null
                        }
                    copy(rows = rows.toMutableList().also { it[index] = changed })
                }

                else -> {
                    null
                }
            }
        }

        PathSegment.MapKey, PathSegment.MapValue -> {
            null
        }
    }
}

private fun List<ListItem>.replace(
    id: ItemId,
    tail: List<PathSegment>,
    replacement: DataValue,
): List<ListItem>? {
    val index = indexOfFirst { it.id == id }
    if (index < 0) return null
    val changed = this[index].value.set(tail, replacement) ?: return null
    return toMutableList().also { it[index] = it[index].copy(value = changed) }
}

private fun DataValue.mutateItems(transform: (List<ListItem>) -> List<ListItem>?): DataValue? {
    return when (this) {
        is DataValue.Named -> copy(payload = payload.mutateItems(transform) ?: return null)
        is DataValue.ListValue -> copy(items = transform(items) ?: return null)
        is DataValue.SetValue -> copy(items = transform(items) ?: return null)
        else -> null
    }
}

private fun DataValue.unwrapNamed(): DataValue = if (this is DataValue.Named) payload.unwrapNamed() else this

private fun TypeUse.concreteNamed(): TypeUse.Named? =
    when (this) {
        is TypeUse.Named -> this
        is TypeUse.Nullable -> value as? TypeUse.Named
        is TypeUse.Scalar -> null
    }

private fun String.sha256(): String =
    MessageDigest
        .getInstance("SHA-256")
        .digest(toByteArray())
        .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }

private fun ValueLocation.append(segment: PathSegment): ValueLocation = copy(path = ValuePath(path.segments + segment))

private fun NativeBinding<*>.encodeAny(value: Any?): DataValue {
    @Suppress("UNCHECKED_CAST")
    return (this as NativeBinding<Any?>).encode(value)
}
