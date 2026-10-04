package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.InitializationDescriptor
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.RelationSelection
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.SelectionId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.SnapshotId
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RelationContract
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import java.util.Collections
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Retains every executable catalog service used by one authored snapshot.
 *
 * The catalog owner supplies a lease that can be retained independently. Closing a snapshot releases only the
 * retain acquired for that snapshot root. Provider callbacks therefore cannot unload while a retained snapshot is
 * still evaluating.
 */
interface SnapshotCatalogLease : AutoCloseable {
    val generation: CatalogGeneration
    val checked: CheckedCatalog
    val nativeBindings: NativeBindingRegistry
    val providers: OwnedProviderRegistry
    val checks: List<OwnedCheckRecipe>
    val relations: List<RelationContract>
    val endpointBindings: List<EndpointBindingTemplate>
    val resources: List<AuthoringResourceDefinition>
    val initialization: List<InitializationDescriptor>
        get() = emptyList()
    val configuration: List<ConfigurationRecipe>
        get() = emptyList()

    fun retain(): SnapshotCatalogLease
}

@ConsistentCopyVisibility
data class AuthoredSnapshotRoot internal constructor(
    val id: SnapshotId,
    val catalog: SnapshotCatalogLease,
    val resources: Map<ResourceId, AuthoringRecord>,
    val resourceDefinitions: Map<ResourceId, ResourceDefinitionId>,
    val links: Map<LinkOccurrenceId, LinkOccurrence>,
    val inputs: Map<InputIdentity, InputToken>,
    internal val sequence: Long,
) {
    internal val readContext = ReadContext(id, catalog.generation)
    internal val graphIndexes = ConcurrentHashMap<RelationSelection, CapturedGraphIndex>()
}

data class AuthoringSnapshotDelta(
    val snapshot: SnapshotId,
    val upsertedResources: Map<ResourceId, AuthoringRecord> = emptyMap(),
    val removedResources: Set<ResourceId> = emptySet(),
    val inputTokens: Map<InputIdentity, InputToken>,
    val catalog: SnapshotCatalogLease? = null,
    val resourceDefinitions: Map<ResourceId, ResourceDefinitionId> = emptyMap(),
) {
    init {
        require(upsertedResources.keys.intersect(removedResources).isEmpty()) {
            "A snapshot delta cannot upsert and remove the same resource."
        }
        require(resourceDefinitions.keys.all { it in upsertedResources }) {
            "Snapshot resource definition metadata must accompany an upserted resource."
        }
    }
}

data class AuthoredSnapshotSeed(
    val snapshot: SnapshotId,
    val resources: Map<ResourceId, AuthoringRecord>,
    val inputTokens: Map<InputIdentity, InputToken>,
    val resourceDefinitions: Map<ResourceId, ResourceDefinitionId> = emptyMap(),
)

data class SnapshotInstallResult(
    val snapshot: SnapshotId,
    val changed: Set<InputIdentity>,
)

data class SnapshotCommit<T>(
    val result: T,
    val delta: AuthoringSnapshotDelta?,
)

interface SnapshotLease : AutoCloseable {
    val root: AuthoredSnapshotRoot

    fun originalView(): AuthoredSnapshotView

    fun stagedView(
        upsertedResources: Map<ResourceId, AuthoringRecord>,
        removedResources: Set<ResourceId> = emptySet(),
    ): AuthoredSnapshotView
}

/**
 * Makes the read source explicit. Checks use Original. Edit preparation may use Staged while retaining the original
 * root and evidence as its conflict boundary.
 */
sealed interface AuthoredSnapshotView {
    val original: AuthoredSnapshotRoot
    val resources: Map<ResourceId, AuthoringRecord>
    val links: Map<LinkOccurrenceId, LinkOccurrence>
    val readContext: ReadContext

    @ConsistentCopyVisibility
    data class Original internal constructor(
        override val original: AuthoredSnapshotRoot,
    ) : AuthoredSnapshotView {
        override val resources: Map<ResourceId, AuthoringRecord> get() = original.resources
        override val links: Map<LinkOccurrenceId, LinkOccurrence> get() = original.links
        override val readContext: ReadContext get() = original.readContext
    }

    @ConsistentCopyVisibility
    data class Staged internal constructor(
        override val original: AuthoredSnapshotRoot,
        override val resources: Map<ResourceId, AuthoringRecord>,
        override val links: Map<LinkOccurrenceId, LinkOccurrence>,
    ) : AuthoredSnapshotView {
        override val readContext = ReadContext(original.id, original.catalog.generation)
        internal val graphIndexes = ConcurrentHashMap<RelationSelection, CapturedGraphIndex>()
    }
}

internal fun AuthoredSnapshotView.graphIndex(selection: RelationSelection): CapturedGraphIndex =
    when (this) {
        is AuthoredSnapshotView.Original -> {
            original.graphIndexes.computeIfAbsent(selection) { CapturedGraphIndex(this, selection) }
        }

        is AuthoredSnapshotView.Staged -> {
            graphIndexes.computeIfAbsent(selection) { CapturedGraphIndex(this, selection) }
        }
    }

interface AuthoringSnapshotStore : AutoCloseable {
    fun <T> commitAndInstall(commit: () -> SnapshotCommit<T>): T

    fun capture(): SnapshotLease

    fun retain(id: SnapshotId): SnapshotLease

    fun install(delta: AuthoringSnapshotDelta): SnapshotInstallResult

    fun currentToken(identity: InputIdentity): InputToken
}

class InMemoryAuthoringSnapshotStore(
    catalog: SnapshotCatalogLease,
    seed: AuthoredSnapshotSeed,
) : AuthoringSnapshotStore {
    private val lock = Any()
    private var nextSequence = 0L
    private val roots = linkedMapOf<SnapshotId, RootRetention>()
    private var closed = false

    private var current: RootRetention =
        createRoot(
            snapshot = seed.snapshot,
            catalog = catalog,
            resources = immutableResources(seed.resources),
            resourceDefinitions = seed.resourceDefinitions,
            inputs = seed.inputTokens,
        ).also { roots[it.root.id] = it }

    override fun <T> commitAndInstall(commit: () -> SnapshotCommit<T>): T =
        synchronized(lock) {
            ensureOpen()
            val committed = commit()
            committed.delta?.let(::install)
            committed.result
        }

    override fun capture(): SnapshotLease =
        synchronized(lock) {
            ensureOpen()
            retain(current)
        }

    override fun retain(id: SnapshotId): SnapshotLease =
        synchronized(lock) {
            ensureOpen()
            retain(requireNotNull(roots[id]) { "Snapshot ${id.value} is no longer retained." })
        }

    override fun install(delta: AuthoringSnapshotDelta): SnapshotInstallResult =
        synchronized(lock) {
            ensureOpen()
            val before = current
            val mutable = before.root.resources.toMutableMap()
            val mutableDefinitions = before.root.resourceDefinitions.toMutableMap()
            delta.removedResources.forEach(mutable::remove)
            delta.removedResources.forEach(mutableDefinitions::remove)
            val definitionCatalog = delta.catalog ?: before.root.catalog
            delta.upsertedResources.forEach { (id, record) -> mutable[id] = immutableRecord(record) }
            delta.upsertedResources.forEach { (id, record) ->
                if (id !in mutableDefinitions) {
                    mutableDefinitions[id] =
                        delta.resourceDefinitions[id]
                            ?: record.resourceDefinition(definitionCatalog.resources, definitionCatalog.checked).id
                }
            }
            val afterResources = immutableMap(mutable)
            val structuralChanges = changedAuthoringInputs(before.root.resources, afterResources).toMutableSet()
            val nextCatalog = delta.catalog
            val catalogChanged = nextCatalog != null && nextCatalog.generation != before.root.catalog.generation
            if (catalogChanged) {
                structuralChanges += InputIdentity.Catalog(requireNotNull(nextCatalog).generation)
            }
            val missingTokens = structuralChanges - delta.inputTokens.keys
            require(missingTokens.isEmpty()) {
                "Committed snapshot delta omitted tokens for changed inputs: ${missingTokens.joinToString()}"
            }
            require(delta.snapshot !in roots) { "Snapshot ${delta.snapshot.value} is already installed." }
            delta.inputTokens.forEach { (identity, token) ->
                require(before.root.inputs[identity] != token) { "Changed input $identity retained its previous token." }
            }
            val inputs = before.root.inputs + delta.inputTokens
            val retainedCatalog = (nextCatalog ?: before.root.catalog).retain()
            val next = createRoot(delta.snapshot, retainedCatalog, afterResources, mutableDefinitions, inputs)
            roots[next.root.id] = next
            current = next
            releaseCurrentOwnership(before)
            if (nextCatalog != null) nextCatalog.close()
            SnapshotInstallResult(next.root.id, delta.inputTokens.keys)
        }

    override fun currentToken(identity: InputIdentity): InputToken =
        synchronized(lock) {
            ensureOpen()
            current.root.inputs[identity] ?: absentInputToken()
        }

    override fun close(): Unit =
        synchronized(lock) {
            if (closed) return
            closed = true
            roots.values.toList().forEach { retention ->
                retention.current = false
                prune(retention)
            }
        }

    private fun createRoot(
        snapshot: SnapshotId,
        catalog: SnapshotCatalogLease,
        resources: Map<ResourceId, AuthoringRecord>,
        resourceDefinitions: Map<ResourceId, ResourceDefinitionId>,
        inputs: Map<InputIdentity, InputToken>,
    ): RootRetention {
        val required = requiredAuthoringInputs(resources) + InputIdentity.Catalog(catalog.generation)
        val missing = required - inputs.keys
        require(missing.isEmpty()) { "Snapshot ${snapshot.value} is missing input tokens: ${missing.joinToString()}" }
        val links = discoverLinks(resources)
        val resolvedDefinitions =
            resources.mapValues { (id, record) ->
                resourceDefinitions[id]
                    ?: record.resourceDefinition(catalog.resources, catalog.checked).id
            }
        val root =
            AuthoredSnapshotRoot(
                id = snapshot,
                catalog = catalog,
                resources = resources,
                resourceDefinitions = immutableMap(resolvedDefinitions),
                links = immutableMap(links),
                inputs = immutableMap(inputs),
                sequence = nextSequence++,
            )
        return RootRetention(root)
    }

    private fun retain(retention: RootRetention): SnapshotLease {
        retention.leases++
        return DefaultSnapshotLease(retention.root) { release(retention) }
    }

    private fun release(retention: RootRetention) =
        synchronized(lock) {
            check(retention.leases > 0) { "Snapshot lease released more than once." }
            retention.leases--
            prune(retention)
        }

    private fun releaseCurrentOwnership(retention: RootRetention) {
        retention.current = false
        prune(retention)
    }

    private fun prune(retention: RootRetention) {
        if (retention.current || retention.leases != 0) return
        roots.remove(retention.root.id)
        if (!retention.catalogClosed) {
            retention.catalogClosed = true
            retention.root.catalog.close()
        }
    }

    private fun ensureOpen() {
        check(!closed) { "Authoring snapshot store is closed." }
    }

    private class RootRetention(
        val root: AuthoredSnapshotRoot,
        var current: Boolean = true,
        var leases: Int = 0,
        var catalogClosed: Boolean = false,
    )
}

private class DefaultSnapshotLease(
    override val root: AuthoredSnapshotRoot,
    private val release: () -> Unit,
) : SnapshotLease {
    private val closed = AtomicBoolean()

    override fun originalView(): AuthoredSnapshotView = AuthoredSnapshotView.Original(root)

    override fun stagedView(
        upsertedResources: Map<ResourceId, AuthoringRecord>,
        removedResources: Set<ResourceId>,
    ): AuthoredSnapshotView {
        check(!closed.get()) { "Cannot stage reads from a closed snapshot lease." }
        require(upsertedResources.keys.intersect(removedResources).isEmpty()) {
            "A staged view cannot upsert and remove the same resource."
        }
        val records = root.resources.toMutableMap()
        removedResources.forEach(records::remove)
        upsertedResources.forEach { (id, record) -> records[id] = immutableRecord(record) }
        val immutable = immutableMap(records)
        return AuthoredSnapshotView.Staged(root, immutable, immutableMap(discoverLinks(immutable)))
    }

    override fun close() {
        if (closed.compareAndSet(false, true)) release()
    }
}

internal fun requiredAuthoringInputs(resources: Map<ResourceId, AuthoringRecord>): Set<InputIdentity> =
    buildSet {
        add(RESOURCE_SELECTION_INPUT)
        resources.forEach { (id, record) ->
            add(InputIdentity.Existence(id))
            add(InputIdentity.Form(ValueLocation(id, ValuePath())))
            collectValueInputs(DataValue.Record(record.fields), ValueLocation(id, ValuePath()), this)
        }
    }

internal fun changedAuthoringInputs(
    before: Map<ResourceId, AuthoringRecord>,
    after: Map<ResourceId, AuthoringRecord>,
): Set<InputIdentity> =
    buildSet {
        (before.keys + after.keys).forEach { id ->
            val old = before[id]
            val new = after[id]
            if (old == new) return@forEach
            if (old == null || new == null) {
                add(InputIdentity.Existence(id))
                add(RESOURCE_SELECTION_INPUT)
            }
            val root = ValueLocation(id, ValuePath())
            if (old?.configuration != new?.configuration) {
                add(InputIdentity.Form(root))
                add(RESOURCE_SELECTION_INPUT)
            }
            diffValue(old?.let { DataValue.Record(it.fields) }, new?.let { DataValue.Record(it.fields) }, root, this)
        }
    }

private fun diffValue(
    before: DataValue?,
    after: DataValue?,
    at: ValueLocation,
    changed: MutableSet<InputIdentity>,
) {
    if (before == after) return
    changed += InputIdentity.Value(at)
    if (before == null || after == null || before::class != after::class) {
        changed += InputIdentity.Form(at)
        before?.let { collectValueInputs(it, at, changed) }
        after?.let { collectValueInputs(it, at, changed) }
        return
    }
    when {
        before is DataValue.Named && after is DataValue.Named -> {
            if (before.actualType != after.actualType) changed += InputIdentity.Form(at)
            diffValue(before.payload, after.payload, at, changed)
        }

        before is DataValue.Record && after is DataValue.Record -> {
            if (before.fields.keys != after.fields.keys) changed += InputIdentity.Form(at)
            (before.fields.keys + after.fields.keys).forEach { name ->
                diffValue(before.fields[name], after.fields[name], at.field(name), changed)
            }
        }

        before is DataValue.ListValue && after is DataValue.ListValue -> {
            diffItems(before.items, after.items, at, changed)
        }

        before is DataValue.SetValue && after is DataValue.SetValue -> {
            diffItems(before.items, after.items, at, changed)
        }

        before is DataValue.MapValue && after is DataValue.MapValue -> {
            diffRows(before.rows, after.rows, at, changed)
        }
    }
}

private fun diffItems(
    before: List<ListItem>,
    after: List<ListItem>,
    at: ValueLocation,
    changed: MutableSet<InputIdentity>,
) {
    val oldIds = before.map(ListItem::id)
    val newIds = after.map(ListItem::id)
    if (oldIds.toSet() != newIds.toSet()) changed += InputIdentity.Membership(at)
    if (oldIds != newIds) changed += InputIdentity.Order(at)
    val old = before.associateBy(ListItem::id)
    val new = after.associateBy(ListItem::id)
    (old.keys + new.keys).forEach { id -> diffValue(old[id]?.value, new[id]?.value, at.item(id), changed) }
}

private fun diffRows(
    before: List<MapRow>,
    after: List<MapRow>,
    at: ValueLocation,
    changed: MutableSet<InputIdentity>,
) {
    val oldIds = before.map(MapRow::id)
    val newIds = after.map(MapRow::id)
    if (oldIds.toSet() != newIds.toSet()) changed += InputIdentity.Membership(at)
    if (oldIds != newIds) changed += InputIdentity.Order(at)
    val old = before.associateBy(MapRow::id)
    val new = after.associateBy(MapRow::id)
    (old.keys + new.keys).forEach { id ->
        diffValue(old[id]?.key, new[id]?.key, at.item(id).mapKey(), changed)
        diffValue(old[id]?.value, new[id]?.value, at.item(id).mapValue(), changed)
    }
}

private fun collectValueInputs(
    value: DataValue,
    at: ValueLocation,
    inputs: MutableSet<InputIdentity>,
) {
    inputs += InputIdentity.Value(at)
    when (value) {
        is DataValue.Named -> {
            inputs += InputIdentity.Form(at)
            collectValueInputs(value.payload, at, inputs)
        }

        is DataValue.Record -> {
            value.fields.forEach { (name, field) -> collectValueInputs(field, at.field(name), inputs) }
        }

        is DataValue.ListValue -> {
            inputs += InputIdentity.Membership(at)
            inputs += InputIdentity.Order(at)
            value.items.forEach { collectValueInputs(it.value, at.item(it.id), inputs) }
        }

        is DataValue.SetValue -> {
            inputs += InputIdentity.Membership(at)
            inputs += InputIdentity.Order(at)
            value.items.forEach { collectValueInputs(it.value, at.item(it.id), inputs) }
        }

        is DataValue.MapValue -> {
            inputs += InputIdentity.Membership(at)
            inputs += InputIdentity.Order(at)
            value.rows.forEach { row ->
                collectValueInputs(row.key, at.item(row.id).mapKey(), inputs)
                collectValueInputs(row.value, at.item(row.id).mapValue(), inputs)
            }
        }

        else -> {
            Unit
        }
    }
}

private fun discoverLinks(resources: Map<ResourceId, AuthoringRecord>): Map<LinkOccurrenceId, LinkOccurrence> =
    buildMap {
        resources.forEach { (resource, record) ->
            record.fields.forEach { (name, value) ->
                discoverLinks(resource, value, ValueLocation(resource, ValuePath(listOf(PathSegment.Field(name)))), this)
            }
        }
    }

private fun discoverLinks(
    source: ResourceId,
    value: DataValue,
    at: ValueLocation,
    links: MutableMap<LinkOccurrenceId, LinkOccurrence>,
) {
    when (value) {
        is DataValue.Link -> {
            val id = LinkOccurrenceId(value.endpoint, at)
            links[id] = LinkOccurrence(id, source, LinkTarget(value.target.resource, value.target.opposite))
        }

        is DataValue.Named -> {
            discoverLinks(source, value.payload, at, links)
        }

        is DataValue.Record -> {
            value.fields.forEach { (name, field) -> discoverLinks(source, field, at.field(name), links) }
        }

        is DataValue.ListValue -> {
            value.items.forEach { discoverLinks(source, it.value, at.item(it.id), links) }
        }

        is DataValue.SetValue -> {
            value.items.forEach { discoverLinks(source, it.value, at.item(it.id), links) }
        }

        is DataValue.MapValue -> {
            value.rows.forEach { row ->
                discoverLinks(source, row.key, at.item(row.id).mapKey(), links)
                discoverLinks(source, row.value, at.item(row.id).mapValue(), links)
            }
        }

        else -> {
            Unit
        }
    }
}

private fun immutableResources(resources: Map<ResourceId, AuthoringRecord>): Map<ResourceId, AuthoringRecord> =
    immutableMap(resources.mapValues { (_, record) -> immutableRecord(record) })

private fun immutableRecord(record: AuthoringRecord): AuthoringRecord =
    record.copy(
        configuration = immutableSelection(record.configuration),
        fields = immutableMap(record.fields.mapValues { (_, value) -> immutableValue(value) }),
    )

private fun immutableSelection(selection: TypeSelection): TypeSelection =
    when (selection) {
        is TypeSelection.Complete -> {
            selection.copy(use = immutableNamedUse(selection.use))
        }

        is TypeSelection.Pending -> {
            selection.copy(
                arguments =
                    immutableList(
                        selection.arguments.map { argument ->
                            when (argument) {
                                is ArgumentSelection.Chosen -> argument.copy(type = immutableTypeUse(argument.type))
                                ArgumentSelection.Unfilled -> argument
                            }
                        },
                    ),
            )
        }
    }

private fun immutableNamedUse(use: com.typewritermc.types.TypeUse.Named): com.typewritermc.types.TypeUse.Named =
    use.copy(arguments = immutableList(use.arguments.map(::immutableTypeUse)))

private fun immutableTypeUse(use: com.typewritermc.types.TypeUse): com.typewritermc.types.TypeUse =
    when (use) {
        is com.typewritermc.types.TypeUse.Named -> immutableNamedUse(use)
        is com.typewritermc.types.TypeUse.Nullable -> use.copy(value = immutableTypeUse(use.value))
        is com.typewritermc.types.TypeUse.Scalar -> use
    }

private fun immutableValue(value: DataValue): DataValue =
    when (value) {
        is DataValue.Record -> {
            value.copy(fields = immutableMap(value.fields.mapValues { (_, field) -> immutableValue(field) }))
        }

        is DataValue.Named -> {
            value.copy(
                actualType = immutableNamedUse(value.actualType),
                payload = immutableValue(value.payload),
            )
        }

        is DataValue.ListValue -> {
            value.copy(items = immutableList(value.items.map { it.copy(value = immutableValue(it.value)) }))
        }

        is DataValue.SetValue -> {
            value.copy(items = immutableList(value.items.map { it.copy(value = immutableValue(it.value)) }))
        }

        is DataValue.MapValue -> {
            value.copy(rows = immutableList(value.rows.map { it.copy(key = immutableValue(it.key), value = immutableValue(it.value)) }))
        }

        is DataValue.Bytes -> {
            value.copy(value = immutableList(value.value))
        }

        is DataValue.Link -> {
            value.copy(
                target =
                    value.target.copy(
                        opposite = value.target.opposite?.let { path -> ValuePath(immutableList(path.segments)) },
                    ),
            )
        }

        else -> {
            value
        }
    }

private fun AuthoringRecord.resourceDefinition(
    definitions: List<AuthoringResourceDefinition>,
    catalog: CheckedCatalog,
): AuthoringResourceDefinition {
    val definition = configuration.definition()
    val candidates =
        definitions.filter { resource ->
            if (resource.root == definition) return@filter true
            val complete =
                (configuration as? TypeSelection.Complete)?.use
                    ?: return@filter catalog.isNominalSubtype(definition, resource.root)
            val resolved = catalog.resolve(complete) as? Resolution.Ready ?: return@filter false
            resolved.value.schema.ancestors
                .any { it.definition == resource.root }
        }
    return requireNotNull(candidates.singleOrNull()) {
        "Authored type $definition must belong to exactly one resource definition."
    }
}

private fun TypeSelection.definition(): com.typewritermc.types.TypeDefinitionId =
    when (this) {
        is TypeSelection.Complete -> use.definition
        is TypeSelection.Pending -> definition
    }

private fun ValueLocation.field(name: String): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.Field(name)))

private fun ValueLocation.item(id: ItemId): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.Item(id)))

private fun ValueLocation.mapKey(): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.MapKey))

private fun ValueLocation.mapValue(): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.MapValue))

internal fun absentInputToken(): InputToken = InputToken("absent")

internal val RESOURCE_SELECTION_INPUT: InputIdentity = InputIdentity.Selection(SelectionId("realm.resources"))

private fun <K, V> immutableMap(values: Map<K, V>): Map<K, V> = Collections.unmodifiableMap(LinkedHashMap(values))

private fun <T> immutableList(values: List<T>): List<T> = Collections.unmodifiableList(ArrayList(values))
