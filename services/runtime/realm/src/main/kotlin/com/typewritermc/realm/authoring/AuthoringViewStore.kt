package com.typewritermc.realm.authoring

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
import com.typewritermc.authoring.definitionFor
import com.typewritermc.authoring.immutableAuthoringCopy
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.ListItem
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.RelationContract
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.immutableMapCopy
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
    val resources: List<AuthoringResourceDefinition>
    val initialization: List<InitializationDescriptor>
        get() = emptyList()
    val configuration: List<ConfigurationRecipe>
        get() = emptyList()

    fun retain(): AuthoringCatalogLease
}

@ConsistentCopyVisibility
data class AuthoringView internal constructor(
    val catalog: AuthoringCatalogLease,
    val resources: Map<ResourceId, AuthoringRecord>,
    val resourceDefinitions: Map<ResourceId, ResourceDefinitionId>,
    val links: Map<LinkOccurrenceId, LinkOccurrence>,
) {
    internal val readContext = ReadContext(catalog.generation)
    internal val graphIndexes = ConcurrentHashMap<RelationSelection, CapturedGraphIndex>()
    internal val values by lazy {
        com.typewritermc.realm.repository.CapturedAuthoringValues(
            resources,
            com.typewritermc.realm.repository.ResourceValueMapper
                .project(
                    links.values,
                    resources,
                    catalog.relations,
                    catalog.checked,
                ).projections,
        )
    }
}

data class AuthoringViewDelta(
    val upsertedResources: Map<ResourceId, AuthoringRecord> = emptyMap(),
    val removedResources: Set<ResourceId> = emptySet(),
    val catalog: AuthoringCatalogLease? = null,
    val resourceDefinitions: Map<ResourceId, ResourceDefinitionId> = emptyMap(),
)

data class AuthoringSeed(
    val resources: Map<ResourceId, AuthoringRecord>,
    val resourceDefinitions: Map<ResourceId, ResourceDefinitionId> = emptyMap(),
)

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
}

internal fun AuthoredReadView.graphIndex(selection: RelationSelection): CapturedGraphIndex =
    when (this) {
        is AuthoredReadView.Original -> original.graphIndexes.computeIfAbsent(selection) { CapturedGraphIndex(this, selection) }
        is AuthoredReadView.Staged -> graphIndexes.computeIfAbsent(selection) { CapturedGraphIndex(this, selection) }
    }

/** Serializes current view installation and admission while leases preserve original read values. */
interface AuthoringViewStore : AutoCloseable {
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
    private val roots = java.util.IdentityHashMap<ReadContext, RootRetention>()
    private var closed = false
    private var reload: (() -> AuthoringSeed)? = null
    private var current = createRoot(catalog, seed.resources, seed.resourceDefinitions).also { roots[it.root.readContext] = it }

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
            val definitions = before.resourceDefinitions + delta.resourceDefinitions - delta.removedResources
            createRoot(catalog.retain(), resources, definitions).root
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
        }

    private fun ensureCurrent() {
        val loader = reload ?: return
        val seed = loader()
        val replacement = createRoot(current.root.catalog.retain(), seed.resources, seed.resourceDefinitions)
        install(replacement.root)
        reload = null
    }

    private fun createRoot(
        catalog: AuthoringCatalogLease,
        resources: Map<ResourceId, AuthoringRecord>,
        definitions: Map<ResourceId, ResourceDefinitionId>,
    ): RootRetention {
        try {
            val immutable = immutableResources(resources)
            val resolved =
                immutable.mapValues { (id, record) ->
                    definitions[id] ?: catalog.resources.definitionFor(record.configuration, catalog.checked).id
                }
            return RootRetention(
                AuthoringView(
                    catalog,
                    immutable,
                    resolved.immutableMapCopy(),
                    discoverLinks(immutable).immutableMapCopy(),
                ),
            )
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
            add(InputIdentity.Form(ValueLocation(id, ValuePath())))
            collectValueInputs(DataValue.Record(record.fields), ValueLocation(id, ValuePath()), this)
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
    com.typewritermc.realm.repository.ResourceValueMapper
        .discover(resources)
        .associateBy(LinkOccurrence::id)

private fun immutableResources(resources: Map<ResourceId, AuthoringRecord>): Map<ResourceId, AuthoringRecord> =
    resources.immutableAuthoringCopy()

private fun TypeSelection.definition(): com.typewritermc.types.TypeDefinitionId =
    when (this) {
        is TypeSelection.Complete -> use.definition
        is TypeSelection.Pending -> definition
    }

private fun ValueLocation.field(name: String): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.Field(name)))

private fun ValueLocation.item(id: ItemId): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.Item(id)))

private fun ValueLocation.mapKey(): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.MapKey))

private fun ValueLocation.mapValue(): ValueLocation = copy(path = ValuePath(path.segments + PathSegment.MapValue))

internal val RESOURCE_SELECTION_INPUT: InputIdentity = InputIdentity.Selection(SelectionId("realm.resources"))
