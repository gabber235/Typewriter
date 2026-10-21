package com.typewritermc.realm.checking

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.authoring.LocatedPortableValue
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.StructuralStep
import com.typewritermc.authoring.append
import com.typewritermc.authoring.arguments
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.field
import com.typewritermc.authoring.item
import com.typewritermc.authoring.links
import com.typewritermc.authoring.locate
import com.typewritermc.authoring.mapKey
import com.typewritermc.authoring.mapValue
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.resourceIds
import com.typewritermc.authoring.root
import com.typewritermc.authoring.type
import com.typewritermc.authoring.use
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InspectionCompletion
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.TypedSelection
import com.typewritermc.checking.UndecidedCandidate
import com.typewritermc.configuration.kind
import com.typewritermc.configuration.name
import com.typewritermc.realm.authoring.AuthoredReadView
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.services.libs.utils.rethrowExceptional
import com.typewritermc.types.actualType
import com.typewritermc.types.canonicalValueKey
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.authoring_facts.TraversalDirection
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.expression.EvaluationDiagnostic
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation

fun interface SelectionPredicateEvaluator {
    fun evaluate(
        predicate: ExpressionNode,
        subject: DraftBinding,
        reads: AuthoredReads,
    ): Availability<Boolean>
}

data class ViewReadLimits(
    val maxReads: Long = 100_000,
    val maxSelectionCandidates: Long = 100_000,
    val maxOccurrenceValues: Long = 500_000,
    val maxCheckTuples: Long = 100_000,
)

data class ViewReadHealth(
    val missing: List<ValueLocation>,
    val failures: List<EvaluationDiagnostic>,
    val incomplete: List<String>,
)

/**
 * Reads a captured or request staged authored view while recording conflict evidence from its original baseline.
 *
 * Returned values come from [view], including prior operation writes in a working view. Expectations always
 * witness [AuthoredReadView.original], allowing commit admission to compare saved inputs independently of staged
 * output. Missing values, callback failures, and exhausted budgets are tracked separately in [health]; callers
 * must inspect that health before treating collected evidence as complete. Each evaluation owns its recorder
 * and mutable counters, so this reader requires serialized use.
 */
class CapturedAuthoringReads(
    internal val view: AuthoredReadView,
    private val recorder: ObservationRecorder = DefaultObservationRecorder(),
    private val predicates: SelectionPredicateEvaluator = MissingSelectionPredicateEvaluator,
    private val limits: ViewReadLimits = ViewReadLimits(),
    override val readContext: ReadContext = view.readContext,
) : AuthoredReads {
    override val catalog: CatalogGeneration = view.original.catalog.generation

    private var reads = 0L
    private var checkTuples = 0L
    private val missing = linkedSetOf<ValueLocation>()
    private val failures = mutableListOf<EvaluationDiagnostic>()
    private val incomplete = linkedSetOf<String>()

    override fun <T> read(path: BoundPath<T>): Availability<T> {
        val complete = portable(path)
        if (complete !is Availability.Available) return complete.cast()
        return try {
            val binding =
                view.original.catalog.nativeBindings
                    .bind(complete.value.schema)
            @Suppress("UNCHECKED_CAST")
            Availability.Available(binding.decode(complete.value) as T)
        } catch (failure: Exception) {
            failure.rethrowExceptional()
            failed(
                "native_read_failed",
                failure.message ?: failure::class.simpleName.orEmpty(),
                listOf(path.location),
            ).cast()
        }
    }

    override fun <T> readRepresentation(
        path: BoundPath<*>,
        representation: TypeUse,
    ): Availability<T> {
        observeResource(path.location.resource)
        observe(InputIdentity.Catalog(catalog))
        val located = valueAt(path.location)
        if (located is LocatedValue.Missing) return unavailable(located.at)
        if (located is LocatedValue.Invalid) return failed(located.code, located.message, listOf(located.at))
        located as LocatedValue.Available
        observe(InputIdentity.Value(path.location))
        val named =
            located.value as? DataValue.NamedWrapper
                ?: return failed(
                    "expected_named_representation",
                    "A representation read requires a named authored value.",
                    listOf(path.location),
                ).cast()
        if (!view.original.catalog.checked
                .isReadableAs(named.actualType.use, path.expected)
        ) {
            return failed(
                "unreadable_value",
                "The authored value is not readable as the requested type.",
                listOf(path.location),
            ).cast()
        }
        val payload = named.payload
        if (payload == DataValue.UNFILLED || payload == DataValue.NULL) return unavailable(path.location)
        val checked = resolve(representation, path.location) ?: return Availability.Failed(failures.last())
        val complete =
            when (val result = checked.complete(payload)) {
                is CompletenessResult.Complete -> {
                    result.value
                }

                is CompletenessResult.Unfinished -> {
                    return unavailable(result.locations.map { path.location.append(it.path) })
                }

                is CompletenessResult.Invalid -> {
                    return failed(
                        result.problems.firstOrNull()?.code ?: "invalid_representation",
                        "The authored representation does not match the requested type.",
                        result.problems.map { path.location.append(it.location.path) }.ifEmpty { listOf(path.location) },
                    )
                }
            }
        return try {
            val native =
                view.original.catalog.nativeBindings
                    .bind(complete.schema)
                    .decode(complete)
            @Suppress("UNCHECKED_CAST")
            Availability.Available(native as T)
        } catch (failure: Exception) {
            failure.rethrowExceptional()
            failed(
                "representation_read_failed",
                failure.message ?: failure::class.simpleName.orEmpty(),
                listOf(path.location),
            ).cast()
        }
    }

    override fun presence(path: BoundPath<*>): Availability<Boolean> {
        observeResource(path.location.resource)
        observe(InputIdentity.Catalog(catalog))
        return when (val located = valueAt(path.location)) {
            is LocatedValue.Missing -> {
                unavailable(located.at)
            }

            is LocatedValue.Invalid -> {
                failed(located.code, located.message, listOf(located.at))
            }

            is LocatedValue.Available -> {
                observe(InputIdentity.Value(path.location))
                when (located.value) {
                    DataValue.UNFILLED -> unavailable(path.location)
                    DataValue.NULL -> Availability.Available(false)
                    else -> Availability.Available(true)
                }
            }
        }
    }

    override fun binding(path: BoundPath<*>): Availability<DraftBinding> {
        observeResource(path.location.resource)
        observe(InputIdentity.Catalog(catalog))
        observe(InputIdentity.Form(path.location))
        if (path.location.path.segments
                .isEmpty()
        ) {
            val record = view.resources[path.location.resource] ?: return unavailable(path.location)
            val selection = record.configuration
            val readable =
                when (selection) {
                    is TypeSelection.CompleteWrapper -> {
                        view.original.catalog.checked
                            .isReadableAs(selection.use.use, path.expected)
                    }

                    is TypeSelection.PendingWrapper -> {
                        pendingBindingReadableAs(selection, path.expected)
                    }

                    else -> {
                        unknownVariant(selection)
                    }
                }
            if (!readable) {
                return failed(
                    "unreadable_binding",
                    "The authored value is not readable as the requested draft type.",
                    listOf(path.location),
                )
            }
            val checked = (selection as? TypeSelection.CompleteWrapper)?.let { resolve(it.use.use, path.location) }
            return binding(path.location, selection, checked)
                ?.let { Availability.Available(it) }
                ?: Availability.Failed(failures.last())
        }
        return when (val located = valueAt(path.location)) {
            is LocatedValue.Missing -> {
                unavailable(located.at)
            }

            is LocatedValue.Invalid -> {
                failed(located.code, located.message, listOf(located.at))
            }

            is LocatedValue.Available -> {
                if (located.value == DataValue.UNFILLED || located.value == DataValue.NULL) return unavailable(path.location)
                val named =
                    located.value as? DataValue.NamedWrapper
                        ?: return failed(
                            "expected_named_binding",
                            "A draft binding requires a named authored value.",
                            listOf(path.location),
                        )
                if (!view.original.catalog.checked
                        .isReadableAs(named.actualType.use, path.expected)
                ) {
                    return failed(
                        "unreadable_binding",
                        "The authored value is not readable as the requested draft type.",
                        listOf(path.location),
                    )
                }
                val checked = resolve(named.actualType.use, path.location) ?: return Availability.Failed(failures.last())
                Availability.Available(
                    DraftBinding(
                        catalog,
                        readContext,
                        path.location,
                        DraftExpectation.Complete(checked),
                        TypeSelection.CompleteWrapper(named.actualType),
                    ),
                )
            }
        }
    }

    override fun canonicalValueKey(path: BoundPath<*>): Availability<String> {
        observeResource(path.location.resource)
        observe(InputIdentity.Catalog(catalog))
        return when (val located = valueAt(path.location)) {
            is LocatedValue.Missing -> {
                unavailable(located.at)
            }

            is LocatedValue.Invalid -> {
                failed(located.code, located.message, listOf(located.at))
            }

            is LocatedValue.Available -> {
                observe(InputIdentity.Value(path.location))
                val value = located.value
                if (value == DataValue.UNFILLED || value == DataValue.NULL) return unavailable(path.location)
                val actual = (value as? DataValue.NamedWrapper)?.actualType?.use ?: path.expected
                if (!view.original.catalog.checked
                        .isReadableAs(actual, path.expected)
                ) {
                    return failed(
                        "unreadable_value",
                        "The authored value is not readable as the requested type.",
                        listOf(path.location),
                    )
                }
                Availability.Available(value.canonicalValueKey())
            }
        }
    }

    override fun members(path: BoundCollectionPath): List<ItemId> {
        observeResource(path.location.resource)
        observe(InputIdentity.Form(path.location))
        observe(InputIdentity.Membership(path.location))
        observe(InputIdentity.Order(path.location))
        return when (val value = valueAt(path.location)) {
            is LocatedValue.Available -> {
                when (val data = value.value.unwrapNamed()) {
                    is DataValue.ListValueWrapper -> {
                        data.items.map(ListItem::id)
                    }

                    is DataValue.SetValueWrapper -> {
                        data.items.map(ListItem::id)
                    }

                    is DataValue.MapValueWrapper -> {
                        data.rows.map(MapRow::id)
                    }

                    DataValue.UNFILLED -> {
                        unavailable(path.location)
                        emptyList()
                    }

                    else -> {
                        failed("expected_collection", "The authored value is not a collection.", listOf(path.location))
                        emptyList()
                    }
                }
            }

            is LocatedValue.Missing -> {
                unavailable(value.at)
                emptyList()
            }

            is LocatedValue.Invalid -> {
                failed(value.code, value.message, listOf(value.at))
                emptyList()
            }
        }
    }

    override fun <D> select(query: TypedSelection<D>): PartialSelection<D> {
        observe(RESOURCE_SELECTION_INPUT)
        observe(InputIdentity.Catalog(catalog))
        val known = mutableListOf<D>()
        val undecided = mutableListOf<UndecidedCandidate>()
        val queryFailures = mutableListOf<EvaluationDiagnostic>()
        var candidates = 0L
        var interrupted: String? = null

        for ((resource, record) in view.resources.entries.sortedBy { it.key.value }) {
            if (++candidates > limits.maxSelectionCandidates) {
                interrupted = "selection candidate limit exceeded"
                markIncomplete(requireNotNull(interrupted))
                break
            }
            observeResource(resource)
            val root = ValueLocation.of(resource)
            observe(InputIdentity.Form(root))
            when (val match = match(record.configuration, query.type.match)) {
                TypeMatch.No -> {}

                TypeMatch.Undecided -> {
                    undecided += UndecidedCandidate(resource.toResourceId(), listOf(root))
                }

                is TypeMatch.Yes -> {
                    val binding = binding(root, record.configuration, match.checked)
                    if (binding == null) {
                        undecided += UndecidedCandidate(resource.toResourceId(), listOf(root))
                        continue
                    }
                    val predicate = query.predicate
                    if (predicate == null) {
                        known += query.type.bind(binding)
                        continue
                    }
                    when (val result = predicates.evaluate(predicate, binding, this)) {
                        is Availability.Available -> {
                            if (result.value) known += query.type.bind(binding)
                        }

                        is Availability.Unavailable -> {
                            undecided += UndecidedCandidate(resource.toResourceId(), result.locations)
                        }

                        is Availability.Failed -> {
                            queryFailures += result.diagnostic
                            failures += result.diagnostic
                        }
                    }
                }
            }
        }
        return PartialSelection(
            knownMatches = known,
            undecided = undecided,
            completion = interrupted?.let(InspectionCompletion::Interrupted) ?: InspectionCompletion.Complete,
            failures = queryFailures,
        )
    }

    fun portable(path: BoundPath<*>): Availability<CompleteValue> {
        observeResource(path.location.resource)
        observe(InputIdentity.Catalog(catalog))
        val located = valueAt(path.location)
        if (located is LocatedValue.Missing) return unavailable(located.at)
        if (located is LocatedValue.Invalid) return failed(located.code, located.message, listOf(located.at))
        located as LocatedValue.Available
        observe(InputIdentity.Value(path.location))
        if (located.value == DataValue.UNFILLED) return unavailable(path.location)
        val actual = (located.value as? DataValue.NamedWrapper)?.actualType?.use ?: path.expected
        if (!view.original.catalog.checked
                .isReadableAs(actual, path.expected)
        ) {
            return failed("unreadable_value", "The authored value is not readable as the requested type.", listOf(path.location))
        }
        val checked = resolve(actual, path.location) ?: return Availability.Failed(failures.last())
        return when (val result = checked.complete(located.value)) {
            is CompletenessResult.Complete -> {
                Availability.Available(result.value)
            }

            is CompletenessResult.Unfinished -> {
                unavailable(result.locations.map { path.location.append(it.path) })
            }

            is CompletenessResult.Invalid -> {
                val locations = result.problems.map { path.location.append(it.location.path) }
                failed(
                    result.problems.firstOrNull()?.code ?: "invalid_value",
                    "The authored value does not match its checked schema.",
                    locations.ifEmpty { listOf(path.location) },
                )
            }
        }
    }

    internal fun authoredValue(location: ValueLocation): Availability<DataValue> {
        observeResource(location.resource)
        observe(InputIdentity.Catalog(catalog))
        return when (val located = valueAt(location)) {
            is LocatedValue.Missing -> {
                unavailable(located.at)
            }

            is LocatedValue.Invalid -> {
                failed(located.code, located.message, listOf(located.at))
            }

            is LocatedValue.Available -> {
                observe(InputIdentity.Value(location))
                if (located.value == DataValue.UNFILLED) unavailable(location) else Availability.Available(located.value)
            }
        }
    }

    fun discoverOccurrences(owner: TypeDefinitionId): List<DraftBinding> {
        observe(RESOURCE_SELECTION_INPUT)
        observe(InputIdentity.Catalog(catalog))
        val occurrences = mutableListOf<DraftBinding>()
        var inspected = 0L

        fun visit(
            resource: ResourceId,
            value: DataValue,
            at: ValueLocation,
        ) {
            if (++inspected > limits.maxOccurrenceValues) {
                markIncomplete("occurrence discovery limit exceeded")
                return
            }
            when (value) {
                is DataValue.NamedWrapper -> {
                    observe(InputIdentity.Form(at))
                    val checked =
                        value.actualType
                            .takeIf { it.definition.couldRepresent(owner) }
                            ?.let { resolve(it.use, at) }
                    if (checked != null && checked.represents(owner)) {
                        occurrences +=
                            DraftBinding(
                                catalog,
                                readContext,
                                at,
                                DraftExpectation.Complete(checked),
                                TypeSelection.CompleteWrapper(value.actualType),
                            )
                    }
                    visit(resource, value.payload, at)
                }

                is DataValue.RecordWrapper -> {
                    value.fields.forEach { field -> visit(resource, field.value, at.field(field.name)) }
                }

                is DataValue.ListValueWrapper -> {
                    observe(InputIdentity.Membership(at))
                    value.items.forEach { visit(resource, it.value, at.item(it.id)) }
                }

                is DataValue.SetValueWrapper -> {
                    observe(InputIdentity.Membership(at))
                    value.items.forEach { visit(resource, it.value, at.item(it.id)) }
                }

                is DataValue.MapValueWrapper -> {
                    observe(InputIdentity.Membership(at))
                    value.rows.forEach { row ->
                        visit(resource, row.key, at.item(row.id).mapKey())
                        visit(resource, row.value, at.item(row.id).mapValue())
                    }
                }

                else -> {}
            }
        }
        view.resources.entries.sortedBy { it.key.value }.forEach { (resource, record) ->
            observeResource(resource)
            val root = ValueLocation.of(resource)
            when (val selection = record.configuration) {
                is TypeSelection.CompleteWrapper -> {
                    val checked =
                        selection.use
                            .takeIf { it.definition.couldRepresent(owner) }
                            ?.let { resolve(it.use, root) }
                    if (checked != null && checked.represents(owner)) {
                        occurrences += DraftBinding(catalog, readContext, root, DraftExpectation.Complete(checked), selection)
                    }
                }

                is TypeSelection.PendingWrapper -> {
                    if (view.original.catalog.checked
                            .isNominalSubtype(selection.definition, owner)
                    ) {
                        val partial =
                            view.original.catalog.checked
                                .resolvePartial(selection)
                        if (partial is Resolution.Ready) {
                            occurrences +=
                                DraftBinding(catalog, readContext, root, DraftExpectation.PartialRoot(partial.value), selection)
                        }
                    }
                }

                else -> {
                    unknownVariant(selection)
                }
            }
            record.fields.forEach { field -> visit(resource, field.value, root.field(field.name)) }
        }
        return occurrences
    }

    fun <D> discoverResources(type: DraftType<D>): List<DraftBinding> {
        observe(RESOURCE_SELECTION_INPUT)
        observe(InputIdentity.Catalog(catalog))
        return view.resources.entries.sortedBy { it.key.value }.mapNotNull { (resource, record) ->
            observeResource(resource)
            val root = ValueLocation.of(resource)
            observe(InputIdentity.Form(root))
            val result = match(record.configuration, type.match)
            if (result !is TypeMatch.Yes) return@mapNotNull null
            binding(root, record.configuration, result.checked)
        }
    }

    fun health(): ViewReadHealth = ViewReadHealth(missing.toList(), failures.toList(), incomplete.toList())

    fun observations(): List<EditExpectation> = recorder.captured()

    internal fun observeInput(identity: InputIdentity) {
        observe(identity)
    }

    internal fun recordFailure(diagnostic: EvaluationDiagnostic) {
        failures += diagnostic
    }

    internal fun recordIncomplete(reason: String) {
        markIncomplete(reason)
    }

    internal fun admitCheckTuple(): Boolean {
        if (++checkTuples <= limits.maxCheckTuples) return true
        markIncomplete("check occurrence tuple limit exceeded")
        return false
    }

    internal fun resourceBinding(resource: ResourceId): Availability<DraftBinding> {
        observeResource(resource)
        val record = view.resources[resource] ?: return unavailable(ValueLocation.of(resource))
        val location = ValueLocation.of(resource)
        observe(InputIdentity.Form(location))
        val checked = (record.configuration as? TypeSelection.CompleteWrapper)?.let { resolve(it.use.use, location) }
        val binding = binding(location, record.configuration, checked)
        return binding?.let { Availability.Available(it) }
            ?: failed("resource_binding_failed", "The resource could not be bound to its captured catalog.", listOf(location))
    }

    internal fun bindResource(
        location: ValueLocation,
        requested: ResourceTypeMatch,
    ): DraftBinding? {
        require(location.path.segments.isEmpty()) { "A resource check subject must use a root location." }
        observeResource(location.resource)
        observe(InputIdentity.Catalog(catalog))
        observe(InputIdentity.Form(location))
        val record = view.resources[location.resource] ?: return null
        val match = match(record.configuration, requested) as? TypeMatch.Yes ?: return null
        return binding(location, record.configuration, match.checked)
    }

    internal fun bindOccurrence(
        location: ValueLocation,
        owner: TypeDefinitionId,
    ): DraftBinding? {
        observeResource(location.resource)
        observe(InputIdentity.Catalog(catalog))
        if (location.path.segments.isEmpty()) {
            val record = view.resources[location.resource] ?: return null
            observe(InputIdentity.Form(location))
            val selection = record.configuration
            val checked =
                when (selection) {
                    is TypeSelection.CompleteWrapper -> resolve(selection.use.use, location)
                    is TypeSelection.PendingWrapper -> null
                    else -> unknownVariant(selection)
                }
            if (
                checked?.represents(owner) != true &&
                (selection as? TypeSelection.PendingWrapper)?.let {
                    view.original.catalog.checked
                        .isNominalSubtype(it.definition, owner)
                } != true
            ) {
                return null
            }
            return binding(location, selection, checked)
        }
        val located = valueAt(location) as? LocatedValue.Available ?: return null
        observe(InputIdentity.Form(location))
        val named = located.value as? DataValue.NamedWrapper ?: return null
        val checked = resolve(named.actualType.use, location) ?: return null
        if (!checked.represents(owner)) return null
        return DraftBinding(
            catalog,
            readContext,
            location,
            DraftExpectation.Complete(checked),
            TypeSelection.CompleteWrapper(named.actualType),
        )
    }

    internal fun matchesRepresentation(
        subject: DraftBinding,
        pattern: RelativeFieldPattern,
        expected: RepresentationKind?,
    ): Boolean {
        if (expected == null) return true
        val use =
            expectedType(subject, pattern, view.original.catalog.checked)
                ?: return false
        val resolved =
            view.original.catalog.checked
                .resolve(use) as? Resolution.Ready ?: return false
        return resolved.value.schema.representation
            .kind() == expected
    }

    fun expand(
        subject: ValueLocation,
        pattern: RelativeFieldPattern,
    ): List<ValueLocation> {
        var locations = listOf(subject)
        pattern.segments.forEach { segment ->
            locations =
                locations.flatMap { location ->
                    when (segment) {
                        is FieldPatternSegment.FieldWrapper -> {
                            val value = (valueAt(location) as? LocatedValue.Available)?.value?.unwrapNamed()
                            if (value == DataValue.NULL) emptyList() else listOf(location.field(segment.name))
                        }

                        FieldPatternSegment.ITEMS -> {
                            collectionLocations(location, CollectionPart.Item)
                        }

                        FieldPatternSegment.KEYS -> {
                            collectionLocations(location, CollectionPart.Key)
                        }

                        FieldPatternSegment.VALUES -> {
                            collectionLocations(location, CollectionPart.Value)
                        }

                        else -> {
                            unknownVariant(segment)
                        }
                    }
                }
        }
        return locations
    }

    private fun valueAt(location: ValueLocation): LocatedValue {
        val record = view.resources[location.resource] ?: return LocatedValue.Missing(location)
        if (location.path.segments.isEmpty()) {
            val selection = record.configuration as? TypeSelection.CompleteWrapper ?: return LocatedValue.Missing(location)
            return LocatedValue.Available(DataValue.named(selection.use, DataValue.RecordWrapper(record.payload)))
        }
        val result =
            DataValue.RecordWrapper(record.payload).locate(location.path) { step ->
                val at = ValueLocation(resource = location.resource, path = step.at)
                when (step) {
                    is StructuralStep.Form -> observe(InputIdentity.Form(at))
                    is StructuralStep.Membership -> observe(InputIdentity.Membership(at))
                }
            }
        return when (result) {
            is LocatedPortableValue.Value -> {
                LocatedValue.Available(result.value)
            }

            is LocatedPortableValue.Row -> {
                LocatedValue.Invalid(location, "expected_value", "The path ends at a map row rather than a value.")
            }

            is LocatedPortableValue.Missing -> {
                LocatedValue.Missing(location.copy(path = result.traversed))
            }

            is LocatedPortableValue.Invalid -> {
                LocatedValue.Invalid(
                    location.copy(path = result.traversed),
                    result.code,
                    when (result.code) {
                        "expected_record" -> "A field was read from a nonrecord value."
                        "expected_map_row" -> "A map branch was read outside a map row."
                        else -> "The portable path is invalid."
                    },
                )
            }
        }
    }

    private fun collectionLocations(
        location: ValueLocation,
        part: CollectionPart,
    ): List<ValueLocation> {
        observe(InputIdentity.Membership(location))
        return when (val located = valueAt(location)) {
            is LocatedValue.Available -> {
                when (val value = located.value.unwrapNamed()) {
                    is DataValue.ListValueWrapper -> {
                        value.items.map { location.item(it.id) }
                    }

                    is DataValue.SetValueWrapper -> {
                        value.items.map { location.item(it.id) }
                    }

                    is DataValue.MapValueWrapper -> {
                        when (part) {
                            CollectionPart.Item -> {
                                value.rows.flatMap {
                                    listOf(
                                        location.item(it.id).mapKey(),
                                        location.item(it.id).mapValue(),
                                    )
                                }
                            }

                            CollectionPart.Key -> {
                                value.rows.map { location.item(it.id).mapKey() }
                            }

                            CollectionPart.Value -> {
                                value.rows.map { location.item(it.id).mapValue() }
                            }
                        }
                    }

                    else -> {
                        emptyList()
                    }
                }
            }

            else -> {
                emptyList()
            }
        }
    }

    private fun match(
        selection: TypeSelection,
        requested: ResourceTypeMatch,
    ): TypeMatch =
        when (requested) {
            ResourceTypeMatch.AnyResource -> {
                when (selection) {
                    is TypeSelection.CompleteWrapper -> TypeMatch.Yes(resolve(selection.use.use, null))
                    is TypeSelection.PendingWrapper -> TypeMatch.Yes(null)
                    else -> unknownVariant(selection)
                }
            }

            is ResourceTypeMatch.Definition -> {
                when (selection) {
                    is TypeSelection.CompleteWrapper -> {
                        if (!selection.use.definition.couldRepresent(requested.id)) return TypeMatch.No
                        val checked = resolve(selection.use.use, null)
                        if (checked?.represents(requested.id) == true) TypeMatch.Yes(checked) else TypeMatch.No
                    }

                    is TypeSelection.PendingWrapper -> {
                        if (view.original.catalog.checked
                                .isNominalSubtype(selection.definition, requested.id)
                        ) {
                            TypeMatch.Yes(null)
                        } else {
                            TypeMatch.No
                        }
                    }

                    else -> {
                        unknownVariant(selection)
                    }
                }
            }

            is ResourceTypeMatch.Application -> {
                when (selection) {
                    is TypeSelection.CompleteWrapper -> {
                        if (selection.use != requested.use) return TypeMatch.No
                        val checked = resolve(selection.use.use, null)
                        TypeMatch.Yes(checked)
                    }

                    is TypeSelection.PendingWrapper -> {
                        if (selection.definition == requested.use.definition) {
                            TypeMatch.Undecided
                        } else {
                            TypeMatch.No
                        }
                    }

                    else -> {
                        unknownVariant(selection)
                    }
                }
            }
        }

    private fun TypeDefinitionId.couldRepresent(expected: TypeDefinitionId): Boolean =
        this == expected ||
            view.original.catalog.checked
                .isNominalSubtype(this, expected)

    private fun pendingBindingReadableAs(
        selection: TypeSelection.PendingWrapper,
        expected: TypeUse,
    ): Boolean {
        val expectedNamed = expected as? TypeUse.NamedWrapper
        if (expectedNamed != null && selection.definition == expectedNamed.value.definition) {
            if (selection.arguments.size != expectedNamed.value.arguments.size) return false
            return selection.arguments.zip(expectedNamed.value.arguments).all { (actual, required) ->
                when (actual) {
                    is ArgumentSelection.ChosenWrapper -> {
                        view.original.catalog.checked
                            .isReadableAs(actual.type, required)
                    }

                    ArgumentSelection.UNFILLED -> {
                        true
                    }

                    else -> {
                        unknownVariant(actual)
                    }
                }
            }
        }
        return view.original.catalog.checked
            .knownApplications(selection)
            .any { application ->
                view.original.catalog.checked
                    .isReadableAs(application.use, expected)
            }
    }

    private fun binding(
        location: ValueLocation,
        selection: TypeSelection,
        checked: CheckedType?,
    ): DraftBinding? =
        when (selection) {
            is TypeSelection.CompleteWrapper -> {
                val resolved = checked ?: resolve(selection.use.use, location) ?: return null
                DraftBinding(catalog, readContext, location, DraftExpectation.Complete(resolved), selection)
            }

            is TypeSelection.PendingWrapper -> {
                when (
                    val partial =
                        view.original.catalog.checked
                            .resolvePartial(selection)
                ) {
                    is Resolution.Ready -> {
                        DraftBinding(catalog, readContext, location, DraftExpectation.PartialRoot(partial.value), selection)
                    }

                    is Resolution.Invalid -> {
                        failed("unresolved_partial_type", partial.diagnostics.joinToString { it.code }, listOf(location))
                        null
                    }
                }
            }

            else -> {
                unknownVariant(selection)
            }
        }

    private fun resolve(
        use: TypeUse,
        at: ValueLocation?,
    ): CheckedType? =
        when (
            val result =
                view.original.catalog.checked
                    .resolve(use)
        ) {
            is Resolution.Ready -> {
                result.value
            }

            is Resolution.Invalid -> {
                failed(
                    "unresolved_type",
                    result.diagnostics.joinToString { it.code },
                    listOfNotNull(at),
                )
                null
            }
        }

    private fun observeResource(resource: ResourceId) {
        observe(InputIdentity.Existence(resource))
    }

    private fun observe(identity: InputIdentity) {
        if (++reads > limits.maxReads) {
            markIncomplete("authored read limit exceeded")
            return
        }
        val original = view.original
        val values = original.values
        when (identity) {
            is InputIdentity.Value -> {
                recorder.observe(EditExpectation.createValue(at = identity.at, expected = values.value(identity.at)))
            }

            is InputIdentity.Form -> {
                recorder.observe(EditExpectation.createConfiguration(at = identity.at, expected = values.configuration(identity.at)))
            }

            is InputIdentity.Membership -> {
                recorder.observe(EditExpectation.createValue(at = identity.at, expected = values.value(identity.at)))
            }

            is InputIdentity.Order -> {
                recorder.observe(EditExpectation.createValue(at = identity.at, expected = values.value(identity.at)))
            }

            is InputIdentity.Existence -> {
                recorder.observe(
                    EditExpectation.createResourceExists(
                        id = identity.resource,
                        expected = values.resource(identity.resource) != null,
                    ),
                )
            }

            is InputIdentity.Selection -> {
                recorder.observe(EditExpectation.resourceIds(values.resourceIds()))
            }

            is InputIdentity.Incoming -> {
                original.catalog.relations.filter { identity.relation == null || it.id == identity.relation }.forEach { contract ->
                    recorder.observe(
                        EditExpectation.links(
                            identity.resource,
                            contract.id,
                            TraversalDirection.BOTH,
                            values.links(identity.resource, contract.id, TraversalDirection.BOTH),
                        ),
                    )
                }
            }

            is InputIdentity.Catalog -> {}
        }
    }

    private fun unavailable(location: ValueLocation): Availability.Unavailable =
        Availability.Unavailable(listOf(location)).also { missing += location }

    private fun unavailable(locations: List<ValueLocation>): Availability.Unavailable =
        Availability.Unavailable(locations).also { missing += locations }

    private fun failed(
        code: String,
        message: String,
        locations: List<ValueLocation>,
    ): Availability.Failed {
        val diagnostic = EvaluationDiagnostic(code = code, message = message, locations = locations)
        failures += diagnostic
        return Availability.Failed(diagnostic)
    }

    private fun markIncomplete(reason: String) {
        incomplete += reason
    }
}

internal object MissingSelectionPredicateEvaluator : SelectionPredicateEvaluator {
    override fun evaluate(
        predicate: ExpressionNode,
        subject: DraftBinding,
        reads: AuthoredReads,
    ): Availability<Boolean> =
        Availability.Failed(
            EvaluationDiagnostic(
                code = "selection_evaluator_unavailable",
                message = "No selection predicate evaluator is installed.",
                locations = listOf(subject.location),
            ),
        )
}

private sealed interface LocatedValue {
    data class Available(
        val value: DataValue,
    ) : LocatedValue

    data class Missing(
        val at: ValueLocation,
    ) : LocatedValue

    data class Invalid(
        val at: ValueLocation,
        val code: String,
        val message: String,
    ) : LocatedValue
}

private sealed interface TypeMatch {
    data object No : TypeMatch

    data object Undecided : TypeMatch

    data class Yes(
        val checked: CheckedType?,
    ) : TypeMatch
}

private enum class CollectionPart {
    Item,
    Key,
    Value,
}

private fun CheckedType.represents(definition: TypeDefinitionId): Boolean =
    (use as? TypeUse.NamedWrapper)?.value?.definition == definition || schema.ancestors.any { it.definition == definition }

@Suppress("UNCHECKED_CAST")
private fun <T> Availability<*>.cast(): Availability<T> = this as Availability<T>
