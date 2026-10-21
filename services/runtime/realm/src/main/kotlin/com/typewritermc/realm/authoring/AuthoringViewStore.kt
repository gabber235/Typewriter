package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.RelationSelection
import com.typewritermc.authoring.ResourceDisplayCatalog
import com.typewritermc.authoring.SelectionId
import com.typewritermc.authoring.field
import com.typewritermc.authoring.item
import com.typewritermc.authoring.mapKey
import com.typewritermc.authoring.mapValue
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.root
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.operations.OperationCatalog
import com.typewritermc.realm.repository.CapturedAuthoringValues
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.immutableMapCopy
import com.typewritermc.types.items
import com.typewritermc.types.ownsResources
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.rows
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import java.util.IdentityHashMap
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Retains every executable catalog service used by one immutable authoring view.
 *
 * The catalog owner supplies a lease that can be retained independently. Closing a view releases only the
 * retain acquired for that view. Provider callbacks therefore cannot unload while a retained view is
 * still evaluating.
 */
interface AuthoringCatalogLease : AutoCloseable {
    val generation: CatalogGeneration
    val checked: CheckedCatalog
    val nativeBindings: NativeBindingRegistry
    val providers: OwnedProviderRegistry
    val checks: List<OwnedCheckRecipe>
    val relations: List<RelationContract>
    val endpointBindings: List<EndpointBindingTemplate>
    val configuration: List<ConfigurationRecipe>
    val operations: OperationCatalog

    /** The realm root type of this catalog, whose single instance owns every realm section. */
    val realmRoot: TypeDefinitionId
        get() = RealmRootDefinition.id

    /** The published placement field of each declared type that has one; other types are absent. */
    val placementFields: Map<TypeDefinitionId, ValuePath>

    /** The resource displays that name resources; a catalog without declared displays names none. */
    val displays: ResourceDisplayCatalog
        get() = ResourceDisplayCatalog()

    fun retain(): AuthoringCatalogLease
}

/** Identifies the relations of this catalog that belong to the resource ownership family. */
val AuthoringCatalogLease.ownershipRelationIds: Set<RelationId>
    get() = relations.filter { it.ownsResources }.mapTo(hashSetOf(), RelationContract::id)

/**
 * Captures saved resources and their catalog as the baseline for one authoring observation.
 *
 * Links and graph projections are derived from the captured fields. The view store owns catalog retention;
 * callers needing the view beyond a synchronous read hold an [AuthoringLease]. Operation overlays can share
 * the observation identity while carrying request local values, without installing them as saved state.
 */
@ConsistentCopyVisibility
data class AuthoringView internal constructor(
    val catalog: AuthoringCatalogLease,
    val resources: Map<ResourceId, AuthoringRecord>,
    val links: Map<LinkOccurrenceId, LinkOccurrence>,
    /** Identifies this saved view until replacement, including across state transfer chunks. */
    val observationId: String =
        UUID
            .randomUUID()
            .toString(),
) {
    internal val readContext = ReadContext(catalog.generation)
    internal val graphIndexes = ConcurrentHashMap<RelationSelection, CapturedGraphIndex>()
    internal val projection by lazy {
        ResourceValueMapper.project(
            links.values,
            resources,
            catalog.relations,
            catalog.checked,
        )
    }
    internal val values by lazy {
        CapturedAuthoringValues(resources, projection.projections)
    }
}

data class AuthoringViewDelta(
    val upsertedResources: Map<ResourceId, AuthoringRecord> = emptyMap(),
    val removedResources: Set<ResourceId> = emptySet(),
    val catalog: AuthoringCatalogLease? = null,
)

data class AuthoringSeed(
    val resources: Map<ResourceId, AuthoringRecord>,
)

/**
 * Keeps one captured baseline and its executable catalog alive across suspension.
 *
 * Staged read views overlay this baseline without saving changes. Close the lease after all readers finish;
 * creating a staged view does not independently retain its catalog.
 */
interface AuthoringLease : AutoCloseable {
    val root: AuthoringView

    fun originalView(): AuthoredReadView

    fun stagedView(
        upsertedResources: Map<ResourceId, AuthoringRecord>,
        removedResources: Set<ResourceId> = emptySet(),
    ): AuthoredReadView
}

sealed interface AuthoredReadView {
    val original: AuthoringView
    val resources: Map<ResourceId, AuthoringRecord>
    val links: Map<LinkOccurrenceId, LinkOccurrence>
    val readContext: ReadContext

    class Original internal constructor(
        override val original: AuthoringView,
    ) : AuthoredReadView {
        override val resources get() = original.resources
        override val links get() = original.links
        override val readContext get() = original.readContext
    }

    class Staged internal constructor(
        override val original: AuthoringView,
        override val resources: Map<ResourceId, AuthoringRecord>,
        override val links: Map<LinkOccurrenceId, LinkOccurrence>,
    ) : AuthoredReadView {
        override val readContext = ReadContext(original.catalog.generation)
        internal val graphIndexes = ConcurrentHashMap<RelationSelection, CapturedGraphIndex>()
    }

    /** A request owned staged graph whose evidence remains attached to its immutable baseline. */
    class Working internal constructor(
        override val original: AuthoringView,
    ) : AuthoredReadView {
        override var resources: Map<ResourceId, AuthoringRecord> = original.resources
            private set
        private var cachedLinks: Map<LinkOccurrenceId, LinkOccurrence>? = original.links
        override val links: Map<LinkOccurrenceId, LinkOccurrence>
            get() = cachedLinks ?: discoverLinks(resources).immutableMapCopy().also { cachedLinks = it }
        override val readContext = original.readContext
        internal val graphIndexes = ConcurrentHashMap<RelationSelection, CapturedGraphIndex>()

        /**
         * Counts the staged writes applied so far. A writer may replace the graph with the same map instance it
         * mutated, so readers caching derived facts key them on this counter rather than on map identity.
         */
        var revision: Long = 0
            private set

        fun replace(next: Map<ResourceId, AuthoringRecord>) {
            resources = next
            cachedLinks = null
            graphIndexes.clear()
            revision++
        }
    }
}

internal fun AuthoredReadView.graphIndex(selection: RelationSelection): CapturedGraphIndex =
    when (this) {
        is AuthoredReadView.Original -> original.graphIndexes.computeIfAbsent(selection) { CapturedGraphIndex(this, selection) }
        is AuthoredReadView.Staged -> graphIndexes.computeIfAbsent(selection) { CapturedGraphIndex(this, selection) }
        is AuthoredReadView.Working -> graphIndexes.computeIfAbsent(selection) { CapturedGraphIndex(this, selection) }
    }

/**
 * Owns the current saved authoring view and retains retired views while readers still lease them.
 *
 * Repository admission prepares and installs replacement views here after coordinating persistent writes.
 * [changes] is an invalidation signal, so consumers capture current state rather than treating its counter
 * as a database revision. Invalidated storage reloads on the next read or capture. Store operations are
 * serialized internally; the repository owns serialization across a complete edit admission and persistence.
 */
interface AuthoringViewStore : AutoCloseable {
    /** Signals installed or invalidated saved input. Readers still capture a retained view. */
    val changes: StateFlow<Long>

    fun <T> read(block: (AuthoringView) -> T): T

    fun capture(): AuthoringLease

    fun retain(context: ReadContext): AuthoringLease

    fun prepare(delta: AuthoringViewDelta): AuthoringView

    fun install(view: AuthoringView)

    fun invalidate(reload: () -> AuthoringSeed)
}

class InMemoryAuthoringViewStore(
    catalog: AuthoringCatalogLease,
    seed: AuthoringSeed,
) : AuthoringViewStore {
    private val lock = Any()
    private val changed = MutableStateFlow(0L)
    override val changes: StateFlow<Long> = changed.asStateFlow()
    private val roots = IdentityHashMap<ReadContext, RootRetention>()
    private var closed = false
    private var reload: (() -> AuthoringSeed)? = null
    private var current = createRoot(catalog, seed.resources).also { roots[it.root.readContext] = it }

    override fun <T> read(block: (AuthoringView) -> T): T =
        synchronized(lock) {
            ensureOpen()
            ensureCurrent()
            block(current.root)
        }

    override fun capture(): AuthoringLease =
        synchronized(lock) {
            ensureOpen()
            ensureCurrent()
            retain(current)
        }

    override fun retain(context: ReadContext): AuthoringLease =
        synchronized(lock) {
            ensureOpen()
            retain(requireNotNull(roots[context]) { "The original read view is no longer retained." })
        }

    override fun prepare(delta: AuthoringViewDelta): AuthoringView =
        read { before ->
            require(
                delta.upsertedResources.keys
                    .intersect(delta.removedResources)
                    .isEmpty(),
            )
            val catalog = delta.catalog ?: before.catalog
            val resources = before.resources + delta.upsertedResources - delta.removedResources
            createRoot(catalog.retain(), resources).root
        }

    override fun install(view: AuthoringView) =
        synchronized(lock) {
            ensureOpen()
            require(view.readContext !in roots) { "The read view is already installed." }
            val before = current
            current = RootRetention(view)
            roots[view.readContext] = current
            before.current = false
            prune(before)
            changed.value += 1
        }

    override fun close() {
        synchronized(lock) {
            if (closed) return@synchronized
            closed = true
            roots.values.toList().forEach {
                it.current = false
                prune(it)
            }
        }
    }

    override fun invalidate(reload: () -> AuthoringSeed) =
        synchronized(lock) {
            ensureOpen()
            this.reload = reload
            changed.value += 1
        }

    private fun ensureCurrent() {
        val loader = reload ?: return
        val seed = loader()
        val replacement = createRoot(current.root.catalog.retain(), seed.resources)
        install(replacement.root)
        reload = null
    }

    private fun createRoot(
        catalog: AuthoringCatalogLease,
        resources: Map<ResourceId, AuthoringRecord>,
    ): RootRetention {
        try {
            val immutable = immutableResources(resources)
            return RootRetention(AuthoringView(catalog, immutable, discoverLinks(immutable).immutableMapCopy()))
        } catch (failure: Throwable) {
            try {
                catalog.close()
            } catch (closing: Throwable) {
                failure.addSuppressed(closing)
            }
            throw failure
        }
    }

    private fun retain(retention: RootRetention): AuthoringLease {
        retention.leases++
        return DefaultAuthoringLease(retention.root) {
            synchronized(lock) {
                check(retention.leases > 0)
                retention.leases--
                prune(retention)
            }
        }
    }

    private fun prune(retention: RootRetention) {
        if (retention.current || retention.leases != 0) return
        roots.remove(retention.root.readContext)
        retention.root.catalog.close()
    }

    private fun ensureOpen() = check(!closed) { "The authoring view store is closed." }

    private class RootRetention(
        val root: AuthoringView,
        var current: Boolean = true,
        var leases: Int = 0,
    )
}

private class DefaultAuthoringLease(
    override val root: AuthoringView,
    private val release: () -> Unit,
) : AuthoringLease {
    private val closed = AtomicBoolean()

    override fun originalView(): AuthoredReadView = AuthoredReadView.Original(root)

    override fun stagedView(
        upsertedResources: Map<ResourceId, AuthoringRecord>,
        removedResources: Set<ResourceId>,
    ): AuthoredReadView {
        check(!closed.get()) { "The original read view lease is closed." }
        require(upsertedResources.keys.intersect(removedResources).isEmpty())
        val resources = immutableResources(root.resources + upsertedResources - removedResources)
        return AuthoredReadView.Staged(root, resources, discoverLinks(resources).immutableMapCopy())
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
            add(InputIdentity.Form(ValueLocation.of(id)))
            collectValueInputs(DataValue.RecordWrapper(record.payload), ValueLocation.of(id), this)
        }
    }

private fun collectValueInputs(
    value: DataValue,
    at: ValueLocation,
    inputs: MutableSet<InputIdentity>,
) {
    inputs += InputIdentity.Value(at)
    when (value) {
        is DataValue.NamedWrapper -> {
            inputs += InputIdentity.Form(at)
            collectValueInputs(value.payload, at, inputs)
        }

        is DataValue.RecordWrapper -> {
            value.fields.forEach { field -> collectValueInputs(field.value, at.field(field.name), inputs) }
        }

        is DataValue.ListValueWrapper -> {
            inputs += InputIdentity.Membership(at)
            inputs += InputIdentity.Order(at)
            value.items.forEach { collectValueInputs(it.value, at.item(it.id), inputs) }
        }

        is DataValue.SetValueWrapper -> {
            inputs += InputIdentity.Membership(at)
            inputs += InputIdentity.Order(at)
            value.items.forEach { collectValueInputs(it.value, at.item(it.id), inputs) }
        }

        is DataValue.MapValueWrapper -> {
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
    ResourceValueMapper
        .discover(resources)
        .associateBy(LinkOccurrence::id)

private fun immutableResources(resources: Map<ResourceId, AuthoringRecord>): Map<ResourceId, AuthoringRecord> = resources.immutableMapCopy()

internal val RESOURCE_SELECTION_INPUT: InputIdentity = InputIdentity.Selection(SelectionId("realm.resources"))
