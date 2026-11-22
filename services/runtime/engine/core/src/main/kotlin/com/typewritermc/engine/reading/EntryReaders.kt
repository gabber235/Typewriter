package com.typewritermc.engine.reading

import com.typewritermc.engine.formula.EngineEvaluationEnvironment
import com.typewritermc.events.EntryReader
import com.typewritermc.events.EntryScope
import com.typewritermc.formula.graph.GraphListener
import com.typewritermc.formula.graph.InputKey
import com.typewritermc.formula.graph.Query
import com.typewritermc.formula.graph.QueryReads
import com.typewritermc.formula.graph.TrackedGraph
import com.typewritermc.formula.graph.UntrackedEnvironment
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ValuePath
import java.util.concurrent.ConcurrentHashMap

/**
 * The entry reader of a handler: it reads inline from [values], the stored values of [publication] unless a cascade
 * answers in their place, and evaluates each value for the scope through [publication]. A value that is not loaded
 * fails the read with [ValueNotLoaded], which fails the handler.
 */
class PublishedEntryReader(
    private val publication: EngineEvaluationEnvironment,
    private val values: StoredValues = publication.published,
) : EntryReader {
    override fun read(
        scope: EntryScope<*>,
        path: ValuePath,
    ): Any? {
        val location = publication.locationOf(scope.entry, path)
        return publication.valueAt(location, values.loaded(location), scope)
    }

    override fun has(
        scope: EntryScope<*>,
        path: ValuePath,
    ): Boolean = values.has(publication.locationOf(scope.entry, path))

    override fun items(
        scope: EntryScope<*>,
        path: ValuePath,
    ): List<ItemId> = values.loaded(publication.locationOf(scope.entry, path))?.itemIds().orEmpty()
}

/** What tracked entry reads read: one publication and the values stored for its entries, as one immutable snapshot. */
class EntryValues(
    val publication: EngineEvaluationEnvironment,
    val stored: StoredValues,
)

/** A graph input of what is stored at [location]: a derive that read it reruns once it reads differently. */
sealed interface StoredRead<out T> : InputKey<EntryValues, T> {
    val location: EntryLocation
}

/** The value stored at [location]: any change of the value reruns a derive that read it. */
data class StoredValueAt(
    override val location: EntryLocation,
) : StoredRead<DataValue?> {
    override fun read(environment: EntryValues): DataValue? = environment.stored.loaded(location)
}

/** Whether a value is stored at [location]: only a value appearing or going reruns a derive that read it. */
data class StoredPresenceAt(
    override val location: EntryLocation,
) : StoredRead<Boolean> {
    override fun read(environment: EntryValues): Boolean = environment.stored.has(location)
}

/**
 * The entry reader of a derive: every value it reads is a read of the running query, recorded in read order, so the
 * graph reruns the derive only when a value it actually read changes. A branch not taken was never read, and a value
 * that is not loaded is recorded before it fails, so the derive reruns once it loads.
 */
class TrackedEntryReader(
    private val reads: QueryReads<EntryValues>,
) : EntryReader {
    // The publication is fixed for the graph's life, a new publication builds a new graph, so reading it untracked
    // cannot go stale.
    @OptIn(UntrackedEnvironment::class)
    private val publication: EngineEvaluationEnvironment get() = reads.environment.publication

    override fun read(
        scope: EntryScope<*>,
        path: ValuePath,
    ): Any? {
        val location = publication.locationOf(scope.entry, path)
        val stored = reads.read(StoredValueAt(location))
        // TODO(node 6): a formula evaluated here reads the Definitions and fields it names straight from the
        //  publication, not through the graph, so a derive whose formula reads another resource does not rerun when
        //  that resource changes. This goes away once formula Definitions become graph inputs.
        return publication.valueAt(location, stored, scope)
    }

    override fun has(
        scope: EntryScope<*>,
        path: ValuePath,
    ): Boolean = reads.read(StoredPresenceAt(publication.locationOf(scope.entry, path)))

    override fun items(
        scope: EntryScope<*>,
        path: ValuePath,
    ): List<ItemId> = reads.read(StoredValueAt(publication.locationOf(scope.entry, path)))?.itemIds().orEmpty()
}

/** Loads values an engine does not hold yet, such as a protagonist's stored facts, in one round per call. */
fun interface ValueLoader {
    /** What is stored at each of [locations]. */
    suspend fun load(locations: Set<EntryLocation>): Map<EntryLocation, Stored>
}

/**
 * The tracked graph derives read entry values through, and how their values load. A derive is a [Query] whose scope
 * reads through a [TrackedEntryReader]. Before a derive runs, every value its previous run read that is not loaded
 * loads in one round, so a steady state needs one load round, not one per value it reads in turn. A read that still
 * meets a value not loaded fails with [ValueNotLoaded]; the derive's owner [load]s its location and reads again, and
 * the derive reruns.
 *
 * Loads and [change]s both write onto the latest values, so a change that arrives while a load waits survives it, and
 * a loaded value never replaces one a change set in the meantime. A change at a location replaces everything below it
 * too, so a derive that read below it reruns when that value now reads differently.
 */
class TrackedEntryReads(
    initial: EntryValues,
    private val loader: ValueLoader,
    listener: GraphListener = GraphListener.NONE,
) {
    private val graph = TrackedGraph(initial, listener = listener)
    private val lock = Any()

    @Volatile
    private var values: EntryValues = initial

    @Volatile
    private var stored: ChangedValues = ChangedValues(initial.stored, emptyMap())

    /** The locations each derive's last run read, the last failing location included. */
    private val lastReads = ConcurrentHashMap<Query<EntryValues, *>, Set<EntryLocation>>()

    /** The value of [derive] at the current values, after loading what its previous run read. */
    suspend fun <T> read(derive: Query<EntryValues, T>): T {
        load(lastReads[derive].orEmpty())
        val reads = graph.pin()
        return try {
            reads.read(derive).also {
                lastReads[derive] = reads.readsOf(derive).mapNotNullTo(linkedSetOf()) { (it as? StoredRead<*>)?.location }
            }
        } catch (missing: ValueNotLoaded) {
            lastReads.merge(derive, setOf(missing.location)) { previous, failed -> previous + failed }
            throw missing
        }
    }

    /** Loads every value at [locations] that is not loaded yet, in one round, and starts a revision where they read loaded. */
    suspend fun load(locations: Set<EntryLocation>) {
        val missing = locations.filterTo(linkedSetOf()) { stored.at(it) == Stored.NotLoaded }
        if (missing.isEmpty()) return
        val loaded = loader.load(missing)
        synchronized(lock) { apply(loaded.filterKeys { stored.at(it) == Stored.NotLoaded }) }
    }

    /** Starts a revision where each location of [changes] stores what it maps to, and everything else reads as before. */
    fun change(changes: Map<EntryLocation, Stored>) {
        synchronized(lock) { apply(changes) }
    }

    private fun apply(changes: Map<EntryLocation, Stored>) {
        if (changes.isEmpty()) return
        val kept = stored.changes.filterKeys { earlier -> changes.keys.none { earlier != it && earlier.isWithin(it) } }
        stored = ChangedValues(stored.base, kept + changes)
        values = EntryValues(values.publication, stored)
        val read = lastReads.values.flatten()
        val touched = changes.keys.flatMapTo(linkedSetOf()) { changed -> read.filter { it.isWithin(changed) } + changed }
        graph.advance(values, touched.flatMapTo(linkedSetOf()) { listOf(StoredValueAt(it), StoredPresenceAt(it)) })
    }

    /**
     * [base] with each location of [changes] answered by what it maps to, and each location below a changed one by what
     * the nearest changed location above it stores there.
     */
    private class ChangedValues(
        val base: StoredValues,
        val changes: Map<EntryLocation, Stored>,
    ) : StoredValues {
        override fun at(location: EntryLocation): Stored {
            val segments = location.path.segments
            for (depth in segments.size downTo 0) {
                val above = EntryLocation(location.resource, ValuePath(segments = segments.subList(0, depth)))
                changes[above]?.let { return it.below(location.below(above)) }
            }
            return base.at(location)
        }
    }
}
