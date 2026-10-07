package com.typewritermc.realm.checking

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.TraversalDirection
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.complete
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InspectionCompletion
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.TypedSelection
import com.typewritermc.checking.UndecidedCandidate
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RepresentationKind
import com.typewritermc.configuration.kind
import com.typewritermc.expression.EvaluationDiagnostic
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.realm.authoring.AuthoredReadView
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.realm.repository.CapturedAuthoringValues
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.types.DataValue
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.canonicalValueKey
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import java.util.concurrent.CancellationException

fun interface SelectionPredicateEvaluator {
    fun evaluate(
        predicate: ExpressionNode,
        subject: DraftBinding,
        reads: AuthoredReads,
    ): Availability<Boolean>
}

data class SnapshotReadLimits(
    val maxReads: Long = 100_000,
    val maxSelectionCandidates: Long = 100_000,
    val maxOccurrenceValues: Long = 500_000,
    val maxCheckTuples: Long = 100_000,
)

data class SnapshotReadHealth(
    val missing: List<ValueLocation>,
    val failures: List<EvaluationDiagnostic>,
    val incomplete: List<String>,
)

/**
 * Reads one immutable authored view and records the exact logical inputs used by the caller.
 *
 * Original views provide admissible evidence. Staged views are intended for edit validation and retain the original
 * snapshot identity so callers can keep original conflict evidence separate from proposed content.
 */
class CapturedAuthoringReads(
    internal val view: AuthoredReadView,
    private val recorder: ObservationRecorder = DefaultObservationRecorder(),
    private val predicates: SelectionPredicateEvaluator = MissingSelectionPredicateEvaluator,
    private val limits: SnapshotReadLimits = SnapshotReadLimits(),
    override val readContext: ReadContext = view.readContext,
) : AuthoredReads,
    SnapshotReadCapability {
    override val snapshotReads: CapturedAuthoringReads
        get() = this
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
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (failure: Exception) {
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
            located.value as? DataValue.Named
                ?: return failed(
                    "expected_named_representation",
                    "A representation read requires a named authored value.",
                    listOf(path.location),
                ).cast()
        if (!view.original.catalog.checked
                .isReadableAs(named.actualType, path.expected)
        ) {
            return failed(
                "unreadable_value",
                "The authored value is not readable as the requested type.",
                listOf(path.location),
            ).cast()
        }
        val payload = named.payload
        if (payload == DataValue.Unfilled || payload == DataValue.Null) return unavailable(path.location)
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
        } catch (cancellation: CancellationException) {
            throw cancellation
        } catch (failure: Exception) {
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
                    DataValue.Unfilled -> unavailable(path.location)
                    DataValue.Null -> Availability.Available(false)
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
                    is TypeSelection.Complete -> {
                        view.original.catalog.checked
                            .isReadableAs(selection.use, path.expected)
                    }

                    is TypeSelection.Pending -> {
                        pendingBindingReadableAs(selection, path.expected)
                    }
                }
            if (!readable) {
                return failed(
                    "unreadable_binding",
                    "The authored value is not readable as the requested draft type.",
                    listOf(path.location),
                )
            }
            val checked = (selection as? TypeSelection.Complete)?.let { resolve(it.use, path.location) }
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
                if (located.value == DataValue.Unfilled || located.value == DataValue.Null) return unavailable(path.location)
                val named =
                    located.value as? DataValue.Named
                        ?: return failed(
                            "expected_named_binding",
                            "A draft binding requires a named authored value.",
                            listOf(path.location),
                        )
                if (!view.original.catalog.checked
                        .isReadableAs(named.actualType, path.expected)
                ) {
                    return failed(
                        "unreadable_binding",
                        "The authored value is not readable as the requested draft type.",
                        listOf(path.location),
                    )
                }
                val checked = resolve(named.actualType, path.location) ?: return Availability.Failed(failures.last())
                Availability.Available(
                    DraftBinding(
                        catalog,
                        readContext,
                        path.location,
                        DraftExpectation.Complete(checked),
                        TypeSelection.Complete(named.actualType),
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
                if (value == DataValue.Unfilled || value == DataValue.Null) return unavailable(path.location)
                val actual = (value as? DataValue.Named)?.actualType ?: path.expected
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
                    is DataValue.ListValue -> {
                        data.items.map(ListItem::id)
                    }

                    is DataValue.SetValue -> {
                        data.items.map(ListItem::id)
                    }

                    is DataValue.MapValue -> {
                        data.rows.map(MapRow::id)
                    }

                    DataValue.Unfilled -> {
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
            val root = ValueLocation(resource, ValuePath())
            observe(InputIdentity.Form(root))
            when (val match = match(record.configuration, query.type.match)) {
                TypeMatch.No -> {}

                TypeMatch.Undecided -> {
                    undecided += UndecidedCandidate(resource, listOf(root))
                }

                is TypeMatch.Yes -> {
                    val binding = binding(root, record.configuration, match.checked)
                    if (binding == null) {
                        undecided += UndecidedCandidate(resource, listOf(root))
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
                            undecided += UndecidedCandidate(resource, result.locations)
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
        if (located.value == DataValue.Unfilled) return unavailable(path.location)
        val actual = (located.value as? DataValue.Named)?.actualType ?: path.expected
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
                if (located.value == DataValue.Unfilled) unavailable(location) else Availability.Available(located.value)
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
                is DataValue.Named -> {
                    observe(InputIdentity.Form(at))
                    val checked =
                        value.actualType
                            .takeIf { it.definition.couldRepresent(owner) }
                            ?.let { resolve(it, at) }
                    if (checked != null && checked.represents(owner)) {
                        occurrences +=
                            DraftBinding(
                                catalog,
                                readContext,
                                at,
                                DraftExpectation.Complete(checked),
                                TypeSelection.Complete(value.actualType),
                            )
                    }
                    visit(resource, value.payload, at)
                }

                is DataValue.Record -> {
                    value.fields.forEach { (name, field) -> visit(resource, field, at.field(name)) }
                }

                is DataValue.ListValue -> {
                    observe(InputIdentity.Membership(at))
                    value.items.forEach { visit(resource, it.value, at.item(it.id)) }
                }

                is DataValue.SetValue -> {
                    observe(InputIdentity.Membership(at))
                    value.items.forEach { visit(resource, it.value, at.item(it.id)) }
                }

                is DataValue.MapValue -> {
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
            val root = ValueLocation(resource, ValuePath())
            when (val selection = record.configuration) {
                is TypeSelection.Complete -> {
                    val checked =
                        selection.use
                            .takeIf { it.definition.couldRepresent(owner) }
                            ?.let { resolve(it, root) }
                    if (checked != null && checked.represents(owner)) {
                        occurrences += DraftBinding(catalog, readContext, root, DraftExpectation.Complete(checked), selection)
                    }
                }

                is TypeSelection.Pending -> {
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
            }
            record.fields.forEach { (name, value) -> visit(resource, value, root.field(name)) }
        }
        return occurrences
    }

    fun <D> discoverResources(type: DraftType<D>): List<DraftBinding> {
        observe(RESOURCE_SELECTION_INPUT)
        observe(InputIdentity.Catalog(catalog))
        return view.resources.entries.sortedBy { it.key.value }.mapNotNull { (resource, record) ->
            observeResource(resource)
            val root = ValueLocation(resource, ValuePath())
            observe(InputIdentity.Form(root))
            val result = match(record.configuration, type.match)
            if (result !is TypeMatch.Yes) return@mapNotNull null
            binding(root, record.configuration, result.checked)
        }
    }

    fun health(): SnapshotReadHealth = SnapshotReadHealth(missing.toList(), failures.toList(), incomplete.toList())

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
        val record = view.resources[resource] ?: return unavailable(ValueLocation(resource, ValuePath()))
        val location = ValueLocation(resource, ValuePath())
        observe(InputIdentity.Form(location))
        val checked = (record.configuration as? TypeSelection.Complete)?.let { resolve(it.use, location) }
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
                    is TypeSelection.Complete -> resolve(selection.use, location)
                    is TypeSelection.Pending -> null
                }
            if (
                checked?.represents(owner) != true &&
                (selection as? TypeSelection.Pending)?.let {
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
        val named = located.value as? DataValue.Named ?: return null
        val checked = resolve(named.actualType, location) ?: return null
        if (!checked.represents(owner)) return null
        return DraftBinding(
            catalog,
            readContext,
            location,
            DraftExpectation.Complete(checked),
            TypeSelection.Complete(named.actualType),
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
                        is FieldPatternSegment.Field -> {
                            val value = (valueAt(location) as? LocatedValue.Available)?.value?.unwrapNamed()
                            if (value == DataValue.Null) emptyList() else listOf(location.field(segment.name))
                        }

                        FieldPatternSegment.Items -> {
                            collectionLocations(location, CollectionPart.Item)
                        }

                        FieldPatternSegment.Keys -> {
                            collectionLocations(location, CollectionPart.Key)
                        }

                        FieldPatternSegment.Values -> {
                            collectionLocations(location, CollectionPart.Value)
                        }
                    }
                }
        }
        return locations
    }

    private fun valueAt(location: ValueLocation): LocatedValue {
        val record = view.resources[location.resource] ?: return LocatedValue.Missing(location)
        if (location.path.segments.isEmpty()) {
            val complete = record.configuration as? TypeSelection.Complete ?: return LocatedValue.Missing(location)
            return LocatedValue.Available(DataValue.Named(complete.use, DataValue.Record(record.fields)))
        }
        var cursor: Cursor = Cursor.Value(DataValue.Record(record.fields))
        var traversed = ValueLocation(location.resource, ValuePath())
        for (segment in location.path.segments) {
            observe(InputIdentity.Form(traversed))
            cursor =
                when (segment) {
                    is PathSegment.Field -> {
                        val next = traversed.field(segment.name)
                        val current = cursor.valueOrNull()?.unwrapNamed()
                        if (current == DataValue.Unfilled || current == DataValue.Null) return LocatedValue.Missing(next)
                        val value =
                            current as? DataValue.Record
                                ?: return LocatedValue.Invalid(traversed, "expected_record", "A field was read from a nonrecord value.")
                        val field = value.fields[segment.name] ?: return LocatedValue.Missing(next)
                        traversed = next
                        Cursor.Value(field)
                    }

                    is PathSegment.Item -> {
                        observe(InputIdentity.Membership(traversed))
                        val value = cursor.valueOrNull()?.unwrapNamed()
                        traversed = traversed.item(segment.id)
                        when (value) {
                            is DataValue.ListValue -> value.items.singleOrNull { it.id == segment.id }?.let { Cursor.Value(it.value) }
                            is DataValue.SetValue -> value.items.singleOrNull { it.id == segment.id }?.let { Cursor.Value(it.value) }
                            is DataValue.MapValue -> value.rows.singleOrNull { it.id == segment.id }?.let(Cursor::Row)
                            else -> null
                        } ?: return LocatedValue.Missing(traversed)
                    }

                    PathSegment.MapKey -> {
                        val row =
                            cursor as? Cursor.Row
                                ?: return LocatedValue.Invalid(traversed, "expected_map_row", "A map key was read outside a map row.")
                        traversed = traversed.mapKey()
                        Cursor.Value(row.row.key)
                    }

                    PathSegment.MapValue -> {
                        val row =
                            cursor as? Cursor.Row
                                ?: return LocatedValue.Invalid(traversed, "expected_map_row", "A map value was read outside a map row.")
                        traversed = traversed.mapValue()
                        Cursor.Value(row.row.value)
                    }
                }
        }
        return cursor.valueOrNull()?.let(LocatedValue::Available)
            ?: LocatedValue.Invalid(traversed, "expected_value", "The path ends at a map row rather than a value.")
    }

    private fun collectionLocations(
        location: ValueLocation,
        part: CollectionPart,
    ): List<ValueLocation> {
        observe(InputIdentity.Membership(location))
        return when (val located = valueAt(location)) {
            is LocatedValue.Available -> {
                when (val value = located.value.unwrapNamed()) {
                    is DataValue.ListValue -> {
                        value.items.map { location.item(it.id) }
                    }

                    is DataValue.SetValue -> {
                        value.items.map { location.item(it.id) }
                    }

                    is DataValue.MapValue -> {
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
                    is TypeSelection.Complete -> TypeMatch.Yes(resolve(selection.use, null))
                    is TypeSelection.Pending -> TypeMatch.Yes(null)
                }
            }

            is ResourceTypeMatch.Definition -> {
                when (selection) {
                    is TypeSelection.Complete -> {
                        if (!selection.use.definition.couldRepresent(requested.id)) return TypeMatch.No
                        val checked = resolve(selection.use, null)
                        if (checked?.represents(requested.id) == true) TypeMatch.Yes(checked) else TypeMatch.No
                    }

                    is TypeSelection.Pending -> {
                        if (view.original.catalog.checked
                                .isNominalSubtype(selection.definition, requested.id)
                        ) {
                            TypeMatch.Yes(null)
                        } else {
                            TypeMatch.No
                        }
                    }
                }
            }

            is ResourceTypeMatch.Application -> {
                when (selection) {
                    is TypeSelection.Complete -> {
                        if (selection.use != requested.use) return TypeMatch.No
                        val checked = resolve(selection.use, null)
                        TypeMatch.Yes(checked)
                    }

                    is TypeSelection.Pending -> {
                        if (selection.definition == requested.use.definition) {
                            TypeMatch.Undecided
                        } else {
                            TypeMatch.No
                        }
                    }
                }
            }
        }

    private fun TypeDefinitionId.couldRepresent(expected: TypeDefinitionId): Boolean =
        this == expected ||
            view.original.catalog.checked
                .isNominalSubtype(this, expected)

    private fun pendingBindingReadableAs(
        selection: TypeSelection.Pending,
        expected: TypeUse,
    ): Boolean {
        val expectedNamed = expected as? TypeUse.Named
        if (expectedNamed != null && selection.definition == expectedNamed.definition) {
            if (selection.arguments.size != expectedNamed.arguments.size) return false
            return selection.arguments.zip(expectedNamed.arguments).all { (actual, required) ->
                when (actual) {
                    is ArgumentSelection.Chosen -> {
                        view.original.catalog.checked
                            .isReadableAs(actual.type, required)
                    }

                    ArgumentSelection.Unfilled -> {
                        true
                    }
                }
            }
        }
        return view.original.catalog.checked
            .knownApplications(selection)
            .any { application ->
                view.original.catalog.checked
                    .isReadableAs(application, expected)
            }
    }

    private fun binding(
        location: ValueLocation,
        selection: TypeSelection,
        checked: CheckedType?,
    ): DraftBinding? =
        when (selection) {
            is TypeSelection.Complete -> {
                val resolved = checked ?: resolve(selection.use, location) ?: return null
                DraftBinding(catalog, readContext, location, DraftExpectation.Complete(resolved), selection)
            }

            is TypeSelection.Pending -> {
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
                recorder.observe(EditExpectation.Value(identity.at, values.value(identity.at)))
            }

            is InputIdentity.Form -> {
                recorder.observe(EditExpectation.Configuration(identity.at, values.configuration(identity.at)))
            }

            is InputIdentity.Membership -> {
                recorder.observe(EditExpectation.Value(identity.at, values.value(identity.at)))
            }

            is InputIdentity.Order -> {
                recorder.observe(EditExpectation.Value(identity.at, values.value(identity.at)))
            }

            is InputIdentity.Existence -> {
                recorder.observe(
                    EditExpectation.ResourceExists(
                        identity.resource,
                        values.resource(identity.resource) != null,
                    ),
                )
            }

            is InputIdentity.Selection -> {
                recorder.observe(EditExpectation.ResourceIds(values.resourceIds()))
            }

            is InputIdentity.Incoming -> {
                original.catalog.relations.filter { identity.relation == null || it.id == identity.relation }.forEach { contract ->
                    recorder.observe(
                        EditExpectation.Links(
                            identity.resource,
                            contract.id,
                            TraversalDirection.Both,
                            values.links(identity.resource, contract.id, TraversalDirection.Both),
                        ),
                    )
                }
            }

            is InputIdentity.Catalog -> {
                Unit
            }
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
        val diagnostic = EvaluationDiagnostic(code, message, locations)
        failures += diagnostic
        return Availability.Failed(diagnostic)
    }

    private fun markIncomplete(reason: String) {
        incomplete += reason
    }
}

internal interface SnapshotReadCapability {
    val snapshotReads: CapturedAuthoringReads
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

private sealed interface Cursor {
    data class Value(
        val value: DataValue,
    ) : Cursor

    data class Row(
        val row: MapRow,
    ) : Cursor
}

private fun Cursor.valueOrNull(): DataValue? = (this as? Cursor.Value)?.value

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
    (use as? TypeUse.Named)?.definition == definition || schema.ancestors.any { it.definition == definition }

private fun DataValue.unwrapNamed(): DataValue = (this as? DataValue.Named)?.payload ?: this

private fun ValueLocation.append(relative: ValuePath): ValueLocation = copy(path = ValuePath(path.segments + relative.segments))

private fun ValueLocation.field(name: String): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.Field(name)))

private fun ValueLocation.item(id: ItemId): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.Item(id)))

private fun ValueLocation.mapKey(): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.MapKey))

private fun ValueLocation.mapValue(): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.MapValue))

@Suppress("UNCHECKED_CAST")
private fun <T> Availability<*>.cast(): Availability<T> = this as Availability<T>
