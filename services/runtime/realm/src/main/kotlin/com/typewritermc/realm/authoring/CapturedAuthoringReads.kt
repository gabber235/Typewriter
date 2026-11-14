package com.typewritermc.realm.authoring

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.LocatedPortableValue
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.StructuralStep
import com.typewritermc.authoring.append
import com.typewritermc.authoring.complete
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
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InspectionCompletion
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.TypedSelection
import com.typewritermc.checking.UndecidedCandidate
import com.typewritermc.configuration.kind
import com.typewritermc.configuration.name
import com.typewritermc.expression.operations.HostFailure
import com.typewritermc.failures.rethrowExceptional
import com.typewritermc.realm.catalog.ViewCatalogLease
import com.typewritermc.realm.catalog.code
import com.typewritermc.types.actualType
import com.typewritermc.types.canonicalValueKey
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DerivedOrigin
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResourceType
import com.typewritermc.types.catalog.contentTypesOf
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
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.expression.EvaluationDiagnostic
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.FailureId
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

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
class CapturedAuthoringReads internal constructor(
    internal val view: AuthoredReadView,
    internal val recorder: ObservationRecorder = DefaultObservationRecorder(),
    private val predicates: SelectionPredicateEvaluator = MissingSelectionPredicateEvaluator,
    private val limits: ViewReadLimits = ViewReadLimits(),
    override val readContext: ReadContext = view.readContext,
) : AuthoredReads {
    override val catalog: CatalogGeneration = view.original.catalog.generation

    private var builtCatalog: Pair<Long, ViewCatalogLease>? = null

    /**
     * This reader's catalog: the code catalog plus what the view it reads declares, recording each declaration and held
     * type it reaches. A working view gets a new one when its revision changes, so an operation reads what it staged.
     */
    internal val viewCatalog: ViewCatalogLease
        get() {
            builtCatalog?.takeIf { it.first == revision }?.let { return it.second }
            val resources = view.resources
            return ViewCatalogLease(view.original.catalog.code, contentTypesOf(resources::get, derivedTypes, ::observe)).also {
                builtCatalog =
                    revision to it
            }
        }

    internal val typeCatalog: CheckedCatalog get() = viewCatalog.checked

    /** The revision of the view this reader reads: a working view counts its staged writes, any other view stays at 0. */
    internal val revision: Long get() = (view as? AuthoredReadView.Working)?.revision ?: 0L

    /** What the binds of this reader's catalog compute, as its recorder answers them. */
    internal val derivedTypes: DerivedOrigin get() = recorder.derivedTypes(this)

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
                viewCatalog.nativeBindings
                    .bind(complete.value.schema)
            @Suppress("UNCHECKED_CAST")
            Availability.Available(binding.decode(complete.value) as T)
        } catch (failure: Exception) {
            failure.rethrowExceptional()
            failed(
                HostFailure.NativeReadFailed,
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
        if (located is LocatedValue.Invalid) return failed(located.failure, located.message, listOf(located.at))
        located as LocatedValue.Available
        observe(InputIdentity.Value(path.location))
        val named =
            located.value as? DataValue.NamedWrapper
                ?: return failed(
                    HostFailure.ExpectedNamedRepresentation,
                    "A representation read requires a named authored value.",
                    listOf(path.location),
                ).cast()
        if (!typeCatalog
                .isReadableAs(named.actualType.use, path.expected)
        ) {
            return failed(
                HostFailure.UnreadableValue,
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
                        HostFailure.InvalidRepresentation,
                        "The authored representation does not match the requested type${result.problems.codes()}.",
                        result.problems.map { path.location.append(it.location.path) }.ifEmpty { listOf(path.location) },
                    )
                }
            }
        return try {
            val native =
                viewCatalog.nativeBindings
                    .bind(complete.schema)
                    .decode(complete)
            @Suppress("UNCHECKED_CAST")
            Availability.Available(native as T)
        } catch (failure: Exception) {
            failure.rethrowExceptional()
            failed(
                HostFailure.RepresentationReadFailed,
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
                failed(located.failure, located.message, listOf(located.at))
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
            if (!readableAs(record.configuration, path.expected)) {
                return failed(
                    HostFailure.UnreadableBinding,
                    "The authored value is not readable as the requested draft type.",
                    listOf(path.location),
                )
            }
            return resourceBinding(path.location.resource, record)
                ?.let { Availability.Available(it) }
                ?: Availability.Failed(failures.last())
        }
        return when (val located = valueAt(path.location)) {
            is LocatedValue.Missing -> {
                unavailable(located.at)
            }

            is LocatedValue.Invalid -> {
                failed(located.failure, located.message, listOf(located.at))
            }

            is LocatedValue.Available -> {
                if (located.value == DataValue.UNFILLED || located.value == DataValue.NULL) return unavailable(path.location)
                val named =
                    located.value as? DataValue.NamedWrapper
                        ?: return failed(
                            HostFailure.ExpectedNamedBinding,
                            "A draft binding requires a named authored value.",
                            listOf(path.location),
                        )
                if (!typeCatalog
                        .isReadableAs(named.actualType.use, path.expected)
                ) {
                    return failed(
                        HostFailure.UnreadableBinding,
                        "The authored value is not readable as the requested draft type.",
                        listOf(path.location),
                    )
                }
                val checked = resolve(named.actualType.use, path.location) ?: return Availability.Failed(failures.last())
                Availability.Available(DraftBinding(catalog, readContext, path.location, ResourceType.Complete(checked)))
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
                failed(located.failure, located.message, listOf(located.at))
            }

            is LocatedValue.Available -> {
                observe(InputIdentity.Value(path.location))
                val value = located.value
                if (value == DataValue.UNFILLED || value == DataValue.NULL) return unavailable(path.location)
                val actual = (value as? DataValue.NamedWrapper)?.actualType?.use ?: path.expected
                if (!typeCatalog
                        .isReadableAs(actual, path.expected)
                ) {
                    return failed(
                        HostFailure.UnreadableValue,
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
                        failed(HostFailure.ExpectedCollection, "The authored value is not a collection.", listOf(path.location))
                        emptyList()
                    }
                }
            }

            is LocatedValue.Missing -> {
                unavailable(value.at)
                emptyList()
            }

            is LocatedValue.Invalid -> {
                failed(value.failure, value.message, listOf(value.at))
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
            when (match(record.configuration, query.type.match)) {
                TypeMatch.No -> {}

                TypeMatch.Undecided -> {
                    undecided += UndecidedCandidate(resource.toResourceId(), listOf(root))
                }

                TypeMatch.Yes -> {
                    val binding = resourceBinding(resource, record)
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
        if (located is LocatedValue.Invalid) return failed(located.failure, located.message, listOf(located.at))
        located as LocatedValue.Available
        observe(InputIdentity.Value(path.location))
        if (located.value == DataValue.UNFILLED) return unavailable(path.location)
        val actual = (located.value as? DataValue.NamedWrapper)?.actualType?.use ?: path.expected
        if (!typeCatalog
                .isReadableAs(actual, path.expected)
        ) {
            return failed(HostFailure.UnreadableValue, "The authored value is not readable as the requested type.", listOf(path.location))
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
                    HostFailure.InvalidValue,
                    "The authored value does not match its checked schema${result.problems.codes()}.",
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
                failed(located.failure, located.message, listOf(located.at))
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
                        occurrences += DraftBinding(catalog, readContext, at, ResourceType.Complete(checked))
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
            if (representsAuthored(record.configuration, owner)) resourceBinding(resource, record)?.let { occurrences += it }
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
            if (match(record.configuration, type.match) != TypeMatch.Yes) return@mapNotNull null
            resourceBinding(resource, record)
        }
    }

    fun health(): ViewReadHealth = ViewReadHealth(missing.toList(), failures.toList(), incomplete.toList())

    /**
     * The commit guard expectations for every fact this reader read, witnessed by the view's original. Only a reader
     * outside a query keeps them; inside one, the graph holds what it read.
     */
    fun observations(): List<EditExpectation> = observedInputs().flatMap { view.original.expectations(it) }.distinct()

    /** Every fact this reader read, in read order. Only a reader outside a query keeps them. */
    internal fun observedInputs(): Set<InputIdentity> =
        checkNotNull(recorder as? DefaultObservationRecorder) { "A tracked reader keeps no observations." }.inputs

    /** Where graph reads of this reader read a node. */
    internal val graphLinks: GraphLinks by lazy { recorder.graphLinks(this) }

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
        return resourceBinding(resource, record)?.let { Availability.Available(it) }
            ?: failed(HostFailure.ResourceBindingFailed, "The resource could not be bound to its captured catalog.", listOf(location))
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
        if (match(record.configuration, requested) != TypeMatch.Yes) return null
        return resourceBinding(location.resource, record)
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
            if (!representsAuthored(record.configuration, owner)) return null
            return resourceBinding(location.resource, record)
        }
        val located = valueAt(location) as? LocatedValue.Available ?: return null
        observe(InputIdentity.Form(location))
        val named = located.value as? DataValue.NamedWrapper ?: return null
        val checked = resolve(named.actualType.use, location) ?: return null
        if (!checked.represents(owner)) return null
        return DraftBinding(catalog, readContext, location, ResourceType.Complete(checked))
    }

    internal fun matchesRepresentation(
        subject: DraftBinding,
        pattern: RelativeFieldPattern,
        expected: RepresentationKind?,
    ): Boolean {
        if (expected == null) return true
        val use =
            expectedType(subject, pattern, typeCatalog)
                ?: return false
        val resolved =
            typeCatalog
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
            val type = typeCatalog.typeOf(location.resource, record.configuration) as? Resolution.Ready
            val use = (type?.value as? ResourceType.Complete)?.checked?.use?.named ?: return LocatedValue.Missing(location)
            return LocatedValue.Available(DataValue.named(use, DataValue.RecordWrapper(record.payload)))
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
                LocatedValue.Invalid(location, HostFailure.ExpectedValue, "The path ends at a map row rather than a value.")
            }

            is LocatedPortableValue.Missing -> {
                LocatedValue.Missing(location.copy(path = result.traversed))
            }

            is LocatedPortableValue.Invalid -> {
                val (failure, message) =
                    when (result.code) {
                        "expected_record" -> HostFailure.ExpectedRecord to "A field was read from a nonrecord value."
                        "expected_map_row" -> HostFailure.ExpectedMapRow to "A map branch was read outside a map row."
                        "value_depth_limit" -> HostFailure.ValueDepthLimit to "The authored value nests too deeply."
                        else -> error("Unknown portable path failure ${result.code}.")
                    }
                LocatedValue.Invalid(location.copy(path = result.traversed), failure, message)
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
                    // A list or set has items only; its keys and values are nothing.
                    is DataValue.ListValueWrapper -> {
                        if (part == CollectionPart.Item) value.items.map { location.item(it.id) } else emptyList()
                    }

                    is DataValue.SetValueWrapper -> {
                        if (part == CollectionPart.Item) value.items.map { location.item(it.id) } else emptyList()
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

    /** Whether the creator's choices in [selection] make a resource that [requested] selects: which resources, never what they hold. */
    private fun match(
        selection: TypeSelection,
        requested: ResourceTypeMatch,
    ): TypeMatch {
        if (requested == ResourceTypeMatch.AnyResource) return TypeMatch.Yes
        val type = (typeCatalog.authoredTypeOf(selection) as? Resolution.Ready)?.value ?: return TypeMatch.No
        return when (requested) {
            ResourceTypeMatch.AnyResource -> {
                TypeMatch.Yes
            }

            is ResourceTypeMatch.Definition -> {
                if (type.represents(requested.id)) TypeMatch.Yes else TypeMatch.No
            }

            is ResourceTypeMatch.Application -> {
                when (type) {
                    is ResourceType.Complete -> if (type.checked.use == requested.use.use) TypeMatch.Yes else TypeMatch.No
                    is ResourceType.Partial -> if (type.definition == requested.use.definition) TypeMatch.Undecided else TypeMatch.No
                }
            }
        }
    }

    /** Whether the creator's choices in [selection] make a resource that a draft of [owner] binds. */
    private fun representsAuthored(
        selection: TypeSelection,
        owner: TypeDefinitionId,
    ): Boolean =
        selection.definition.couldRepresent(owner) &&
            (typeCatalog.authoredTypeOf(selection) as? Resolution.Ready)?.value?.represents(owner) == true

    private fun ResourceType.represents(owner: TypeDefinitionId): Boolean =
        when (this) {
            is ResourceType.Complete -> checked.represents(owner)
            is ResourceType.Partial -> typeCatalog.isNominalSubtype(definition, owner)
        }

    private fun TypeDefinitionId.couldRepresent(expected: TypeDefinitionId): Boolean =
        this == expected ||
            typeCatalog
                .isNominalSubtype(this, expected)

    /**
     * Whether the creator's choices in [selection] are readable as [expected]. A partial type of the expected
     * definition reads when every chosen argument does; any other partial type reads through what it already fixes.
     */
    private fun readableAs(
        selection: TypeSelection,
        expected: TypeUse,
    ): Boolean =
        when (val type = (typeCatalog.authoredTypeOf(selection) as? Resolution.Ready)?.value) {
            null -> {
                false
            }

            is ResourceType.Complete -> {
                typeCatalog.isReadableAs(type.checked.use, expected)
            }

            is ResourceType.Partial -> {
                val expectedNamed = expected.named
                if (expectedNamed != null && type.definition == expectedNamed.definition) {
                    selection.arguments.all { chosen ->
                        val required = expectedNamed.arguments.getOrNull(chosen.parameter)
                        required != null && typeCatalog.isReadableAs(chosen.type, required)
                    }
                } else {
                    typeCatalog.knownApplications(selection).any { typeCatalog.isReadableAs(it.use, expected) }
                }
            }
        }

    /** The binding of [resource]'s root to its type, or null with a failure recorded when that type does not resolve. */
    private fun resourceBinding(
        resource: ResourceId,
        record: AuthoringRecord,
    ): DraftBinding? {
        val location = ValueLocation.of(resource)
        return when (val type = typeCatalog.typeOf(resource, record.configuration)) {
            is Resolution.Ready -> {
                DraftBinding(catalog, readContext, location, type.value)
            }

            is Resolution.Invalid -> {
                failed(HostFailure.UnresolvedType, type.diagnostics.joinToString { it.code }, listOf(location))
                null
            }
        }
    }

    private fun resolve(
        use: TypeUse,
        at: ValueLocation?,
    ): CheckedType? =
        when (
            val result =
                typeCatalog
                    .resolve(use)
        ) {
            is Resolution.Ready -> {
                result.value
            }

            is Resolution.Invalid -> {
                failed(
                    HostFailure.UnresolvedType,
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
        // Every read is recorded, also past the limit, so a query never misses what it depends on.
        recorder.observe(identity)
        if (++reads > limits.maxReads) markIncomplete("authored read limit exceeded")
    }

    /** Every resource id of the view, in id order, observed as the realm's resource ids fact. */
    internal fun resourceIds(): List<ResourceId> {
        observe(RESOURCE_SELECTION_INPUT)
        return view.resources.keys.sortedBy { it.value }
    }

    /** The whole record of [id], observed as one fact. */
    internal fun record(id: ResourceId): AuthoringRecord? {
        observe(InputIdentity.Resource(id))
        return view.resources[id]
    }

    /**
     * [resource]'s root bound to the type its creator's choices give, with every computed parameter left open, so a
     * bind reads its resource without the type it computes. Null when that type does not resolve.
     */
    internal fun authoredBinding(resource: ResourceId): DraftBinding? {
        val location = ValueLocation.of(resource)
        observe(InputIdentity.Catalog(catalog))
        observe(InputIdentity.Form(location))
        val record = view.resources[resource] ?: return null
        val type = (typeCatalog.authoredTypeOf(record.configuration) as? Resolution.Ready)?.value ?: return null
        return DraftBinding(catalog, readContext, location, type)
    }

    private fun unavailable(location: ValueLocation): Availability.Unavailable =
        Availability.Unavailable(listOf(location)).also { missing += location }

    private fun unavailable(locations: List<ValueLocation>): Availability.Unavailable =
        Availability.Unavailable(locations).also { missing += locations }

    private fun failed(
        failure: FailureId,
        message: String,
        locations: List<ValueLocation>,
    ): Availability.Failed {
        val diagnostic = EvaluationDiagnostic(failure = failure, message = message, locations = locations)
        failures += diagnostic
        return Availability.Failed(diagnostic)
    }

    private fun markIncomplete(reason: String) {
        incomplete += reason
    }
}

/** The admission problem codes, for a failure message: empty, or a colon and the distinct codes. */
private fun List<ValueProblem>.codes(): String = if (isEmpty()) "" else ": " + map { it.code }.distinct().joinToString()

internal object MissingSelectionPredicateEvaluator : SelectionPredicateEvaluator {
    override fun evaluate(
        predicate: ExpressionNode,
        subject: DraftBinding,
        reads: AuthoredReads,
    ): Availability<Boolean> =
        Availability.Failed(
            EvaluationDiagnostic(
                failure = HostFailure.SelectionEvaluatorUnavailable,
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
        val failure: FailureId,
        val message: String,
    ) : LocatedValue
}

private sealed interface TypeMatch {
    data object No : TypeMatch

    data object Undecided : TypeMatch

    data object Yes : TypeMatch
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
