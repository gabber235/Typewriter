package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ReadContext
import com.typewritermc.checking.InputIdentity
import com.typewritermc.formula.graph.GraphListener
import com.typewritermc.formula.graph.StaleRevision
import com.typewritermc.formula.graph.TrackedGraph
import com.typewritermc.realm.catalog.AuthoringCatalogLease
import com.typewritermc.realm.catalog.ViewCatalogLease
import com.typewritermc.realm.catalog.code
import com.typewritermc.realm.catalog.over
import com.typewritermc.services.libs.utils.closeAll
import com.typewritermc.types.catalog.contentTypesOf
import com.typewritermc.types.immutableMapCopy
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.SelectionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId
import java.util.IdentityHashMap
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

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
    /** Each resource's stored links. A view prepared from another shares every slice its change did not touch. */
    internal val linkSlices: Map<ResourceId, LinkSlice> = links.values.slices(),
    /** What names mean in this view; only a view of the realm's store can say. */
    internal val scopes: ViewScopes = ViewScopes.NONE,
) {
    internal val readContext = ReadContext(catalog.generation)
    private val judgements =
        JudgedSlices { resource ->
            CapturedAuthoringReads(AuthoredReadView.Original(this)).judge(resource, linkSlice(resource))
        }

    internal fun linkSlice(resource: ResourceId): LinkSlice = linkSlices[resource] ?: LinkSlice.EMPTY

    /** What binds compute over this view. */
    internal val binds by lazy { ViewBinds(AuthoredReadView.Original(this)) }

    /**
     * This view with [resources] in place of its own, sharing the links of every record it kept: what an operation or a
     * plan reads, and what binds compute over, before anything is saved.
     */
    internal fun staged(resources: Map<ResourceId, AuthoringRecord>): AuthoredReadView.Staged =
        AuthoredReadView.Staged(this, resources) {
            resources
                .flatMap { (id, record) ->
                    if (this.resources[id] === record) linkSlice(id).own else ResourceValueMapper.discover(mapOf(id to record))
                }.associateBy(LinkOccurrence::id)
        }

    /** [resource]'s slice judged once for this view with a plain reader over it. */
    internal fun judged(resource: ResourceId): ResourceProjection = judgements[resource]

    /** Every judged slice folded together; the planner, publication and relation reads read it, a check pass never does. */
    internal val projection by lazy { linkSlices.keys.map(::judged).fold() }

    internal val values by lazy {
        CapturedAuthoringValues(resources, { at, name -> scopes.nameAt(this, at, name) }) { id -> judged(id).projections }
    }

    /** Reads of a graph forked at this view, made on the first name judged here once it is no longer current. */
    internal val forkedReads = AtomicReference<RealmReads?>()
}

/** What a name means where a formula looks it up in a view, as the realm's graph answers it. */
internal fun interface ViewScopes {
    fun nameAt(
        view: AuthoringView,
        at: ValueLocation,
        name: String,
    ): List<ResourceId>

    companion object {
        val NONE = ViewScopes { _, _, _ -> throw IllegalStateException("Only a view of the realm's store can judge what a name means.") }
    }
}

/** Judgements of slices, each computed once on first read. */
private class JudgedSlices(
    private val judge: (ResourceId) -> ResourceProjection,
) {
    private val judged = ConcurrentHashMap<ResourceId, ResourceProjection>()

    // Not computeIfAbsent: judging reads the catalog, and a reader may ask this map again on the same thread.
    operator fun get(resource: ResourceId): ResourceProjection =
        judged[resource] ?: judge(resource).let { judged.putIfAbsent(resource, it) ?: it }
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

        internal fun linkSlice(resource: ResourceId) = original.linkSlice(resource)

        internal fun judged(resource: ResourceId) = original.judged(resource)

        internal val projection get() = original.projection

        internal val binds get() = original.binds
    }

    class Staged internal constructor(
        override val original: AuthoringView,
        override val resources: Map<ResourceId, AuthoringRecord>,
        findLinks: () -> Map<LinkOccurrenceId, LinkOccurrence>,
    ) : AuthoredReadView {
        override val links by lazy(findLinks)
        override val readContext = ReadContext(original.catalog.generation)
        internal val binds by lazy { ViewBinds(this) }

        /** What [resources] declare and what binds compute over them. */
        internal val content by lazy { contentTypesOf(resources::get, binds.origin) }

        /** The code catalog plus [content]. */
        internal val catalog by lazy { ViewCatalogLease(original.catalog.code, content) }
        private val slices by lazy { links.values.slices() }
        private val judgements = JudgedSlices { resource -> CapturedAuthoringReads(this).judge(resource, linkSlice(resource)) }

        internal fun linkSlice(resource: ResourceId) = slices[resource] ?: LinkSlice.EMPTY

        internal fun judged(resource: ResourceId) = judgements[resource]

        internal val projection by lazy { slices.keys.map(::judged).fold() }
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
        private var derived: Derived? = null
        private var revisionBinds: ViewBinds? = null

        /**
         * Counts the staged writes applied so far. A writer may replace the graph with the same map instance it
         * mutated, so readers caching derived facts key them on this counter rather than on map identity.
         */
        var revision: Long = 0
            private set

        internal fun linkSlice(resource: ResourceId) = derived().slices[resource] ?: LinkSlice.EMPTY

        internal fun judged(resource: ResourceId) = derived().judgements[resource]

        internal val projection: ProjectionResult get() = derived().projection

        /** What binds compute over this view at its current revision. */
        internal val binds: ViewBinds get() = revisionBinds ?: ViewBinds(this).also { revisionBinds = it }

        fun replace(next: Map<ResourceId, AuthoringRecord>) {
            resources = next
            cachedLinks = null
            derived = null
            revisionBinds = null
            revision++
        }

        private fun derived(): Derived = derived ?: Derived().also { derived = it }

        /** What this view derives from its links, built on first read after each replace. */
        private inner class Derived {
            val slices = links.values.slices()
            val judgements = JudgedSlices { resource -> CapturedAuthoringReads(this@Working).judge(resource, linkSlice(resource)) }
            val projection by lazy { slices.keys.map(::judged).fold() }
        }
    }
}

/** [resource]'s stored links in this view. */
internal fun AuthoredReadView.linkSlice(resource: ResourceId): LinkSlice =
    when (this) {
        is AuthoredReadView.Original -> linkSlice(resource)
        is AuthoredReadView.Staged -> linkSlice(resource)
        is AuthoredReadView.Working -> linkSlice(resource)
    }

/** What binds compute over this view. */
internal val AuthoredReadView.binds: ViewBinds
    get() =
        when (this) {
            is AuthoredReadView.Original -> binds
            is AuthoredReadView.Staged -> binds
            is AuthoredReadView.Working -> binds
        }

/** [resource]'s slice judged once per view with a plain reader over it. */
internal fun AuthoredReadView.judged(resource: ResourceId): ResourceProjection =
    when (this) {
        is AuthoredReadView.Original -> judged(resource)
        is AuthoredReadView.Staged -> judged(resource)
        is AuthoredReadView.Working -> judged(resource)
    }

/** Every judged slice of this view folded together, built lazily. */
internal val AuthoredReadView.projection: ProjectionResult
    get() =
        when (this) {
            is AuthoredReadView.Original -> projection
            is AuthoredReadView.Staged -> projection
            is AuthoredReadView.Working -> projection
        }

/**
 * Owns the current saved authoring view and retains retired views while readers still lease them.
 *
 * Repository admission prepares and installs replacement views here after coordinating persistent writes.
 * [changes] is an invalidation signal, so consumers capture current state rather than treating its counter
 * as a database revision. Invalidated storage reloads on the next read or capture. Store operations are
 * serialized internally; the repository owns serialization across a complete edit admission and persistence.
 *
 * The store owns the [graph] realm queries run on, and advances it inside [install], so an installed view and the
 * graph's revision change together.
 */
interface AuthoringViewStore : AutoCloseable {
    /** Signals installed or invalidated saved input. Readers still capture a retained view. */
    val changes: StateFlow<Long>

    /** The query graph over the current view. */
    val graph: AuthoringGraph

    fun <T> read(block: (AuthoringView) -> T): T

    fun capture(): AuthoringLease

    fun retain(context: ReadContext): AuthoringLease

    /** A lease on the current view and graph reads pinned to it, taken together. The view's catalog stays open with the lease. */
    fun pin(): PinnedReads

    /** A graph that reads exactly [view], starting from the live graph's results where it can. */
    fun forkAt(view: AuthoringView): AuthoringGraph

    fun prepare(delta: AuthoringViewDelta): AuthoringView

    fun install(view: AuthoringView)

    fun invalidate(reload: () -> AuthoringSeed)
}

/**
 * The view store of one realm. [services] are what every query reads besides the view, and [listener] hears what the
 * live graph computes; a fork reports to no one.
 */
class InMemoryAuthoringViewStore(
    catalog: AuthoringCatalogLease,
    seed: AuthoringSeed,
    private val services: RealmServices = RealmServices(),
    listener: GraphListener = GraphListener.NONE,
) : AuthoringViewStore {
    private val lock = Any()
    private val changed = MutableStateFlow(0L)
    override val changes: StateFlow<Long> = changed.asStateFlow()
    private val roots = IdentityHashMap<ReadContext, RootRetention>()
    private var closed = false
    private var reload: (() -> AuthoringSeed)? = null

    /** Names in the current view come from the live graph, and in any other view from one fork made for it. */
    private val scopes =
        ViewScopes { view, at, name ->
            val query = services.names.at(at, name)
            val live = synchronized(lock) { graph.pin().takeIf { current.root === view } }
            live?.let { reads -> runCatching { reads.read(query) }.getOrElse { if (it is StaleRevision) null else throw it } }
                ?: view.forkedReads
                    .updateAndGet { it ?: forkAt(view).pin() }!!
                    .read(query)
        }
    private var current = createRoot(catalog, seed.resources).also { roots[it.root.readContext] = it }
    override val graph: AuthoringGraph = TrackedGraph(RealmEnvironment(current.root, services), listener = listener)

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

    override fun pin(): PinnedReads =
        synchronized(lock) {
            ensureOpen()
            ensureCurrent()
            PinnedReads(retain(current), graph.pin())
        }

    override fun forkAt(view: AuthoringView): AuthoringGraph =
        synchronized(lock) {
            val environment = RealmEnvironment(view, services)
            if (view.catalog.generation != current.root.catalog.generation) {
                // Another generation shares nothing with the live graph.
                TrackedGraph(environment)
            } else {
                graph.fork(environment, view.changesFrom(current.root))
            }
        }

    override fun prepare(delta: AuthoringViewDelta): AuthoringView =
        read { before ->
            require(
                delta.upsertedResources.keys
                    .intersect(delta.removedResources)
                    .isEmpty(),
            )
            val resources = before.resources + delta.upsertedResources - delta.removedResources
            if (delta.catalog != null) {
                createRoot(delta.catalog.retain(), resources).root
            } else {
                derive(before, delta, resources)
            }
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
            val environment = RealmEnvironment(view, services)
            if (view.catalog.generation != before.root.catalog.generation) {
                graph.reset(environment)
            } else {
                graph.advance(environment, view.changesFrom(before.root))
            }
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

    /**
     * The view [before] becomes with [delta]: its links and slices follow from [before]'s, so every record and slice
     * the change did not touch keeps its identity, which is how install finds what changed.
     */
    private fun derive(
        before: AuthoringView,
        delta: AuthoringViewDelta,
        merged: Map<ResourceId, AuthoringRecord>,
    ): AuthoringView {
        val holders = delta.upsertedResources.keys + delta.removedResources
        val dropped = holders.flatMap { before.linkSlice(it).own }
        val added = ResourceValueMapper.discover(delta.upsertedResources)
        val links = (before.links - dropped.map(LinkOccurrence::id).toSet() + added.associateBy(LinkOccurrence::id)).immutableMapCopy()
        val slices = before.linkSlices.after(holders, added)
        val catalog = before.catalog.retain()
        try {
            val immutable = merged.immutableMapCopy()
            return viewOver(catalog, immutable) { viewCatalog ->
                AuthoringView(viewCatalog, immutable, links, linkSlices = slices.immutableMapCopy(), scopes = scopes)
            }
        } catch (failure: Throwable) {
            catalog.closeAfter(failure)
            throw failure
        }
    }

    private fun createRoot(
        catalog: AuthoringCatalogLease,
        resources: Map<ResourceId, AuthoringRecord>,
    ): RootRetention {
        try {
            val immutable = immutableResources(resources)
            return RootRetention(
                viewOver(catalog, immutable) { viewCatalog ->
                    AuthoringView(viewCatalog, immutable, discoverLinks(immutable).immutableMapCopy(), scopes = scopes)
                },
            )
        } catch (failure: Throwable) {
            catalog.closeAfter(failure)
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

private fun AuthoringCatalogLease.closeAfter(failure: Throwable) = listOf(this).closeAll(failure)

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
        return AuthoredReadView.Staged(root, resources) { discoverLinks(resources).immutableMapCopy() }
    }

    override fun close() {
        if (closed.compareAndSet(false, true)) release()
    }
}

/**
 * The view [build] makes from a catalog over [resources] whose binds are that same view's. A view needs its catalog to
 * exist, and its binds need the view, so the catalog asks for the view only when a bind first runs.
 */
private fun viewOver(
    catalog: AuthoringCatalogLease,
    resources: Map<ResourceId, AuthoringRecord>,
    build: (ViewCatalogLease) -> AuthoringView,
): AuthoringView {
    lateinit var view: AuthoringView
    view = build(catalog.over(resources) { owner, key -> view.binds.origin.derived(owner, key) })
    return view
}

private fun discoverLinks(resources: Map<ResourceId, AuthoringRecord>): Map<LinkOccurrenceId, LinkOccurrence> =
    ResourceValueMapper
        .discover(resources)
        .associateBy(LinkOccurrence::id)

private fun immutableResources(resources: Map<ResourceId, AuthoringRecord>): Map<ResourceId, AuthoringRecord> = resources.immutableMapCopy()

internal val RESOURCE_SELECTION_INPUT: InputIdentity = InputIdentity.Selection(SelectionId(value = "realm.resources"))
