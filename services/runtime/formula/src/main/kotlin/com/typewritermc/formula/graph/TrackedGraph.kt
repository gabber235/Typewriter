package com.typewritermc.formula.graph

import java.util.concurrent.ConcurrentHashMap
import kotlin.coroutines.cancellation.CancellationException

/**
 * A key the graph answers: an [InputKey] it reads from the environment, or a [Query] it computes and memoizes.
 *
 * A key is the whole definition of what it answers, and the memo map keeps the first key equal to it, so a key holds
 * nothing with a lifetime: no connection, no realm, no session.
 */
sealed interface GraphKey<out T>

/** A fact of the environment. The graph stores no copy of it, only the revision at which it last changed. */
interface InputKey<E, out T> : GraphKey<T> {
    fun read(environment: E): T
}

/**
 * A computation over other keys. It must be pure over what it reads through [QueryReads]: a read that skips the graph
 * goes stale with no error.
 */
interface Query<E, out T> : GraphKey<T> {
    context(reads: QueryReads<E>)
    fun compute(): T

    /** The value of this query when it is a member of a cycle. The default rethrows, so a cycle is a programming error. */
    fun onCycle(members: List<GraphKey<*>>): T = throw QueryCycle(members)
}

/**
 * Reading the environment directly skips the graph, so the answer goes stale with no error. Only helpers that build
 * tracked readers opt in.
 */
@RequiresOptIn(level = RequiresOptIn.Level.ERROR)
@Retention(AnnotationRetention.BINARY)
@Target(AnnotationTarget.PROPERTY)
annotation class UntrackedEnvironment

/** Reads pinned to one revision. Inside a query, every read records a dependency of that query, also when it throws. */
interface QueryReads<E> {
    @UntrackedEnvironment
    val environment: E

    val revision: Long

    fun <T> read(key: GraphKey<T>): T

    /** Throws [StaleRevision] once a newer revision exists. Every read calls it; a long loop calls it too. */
    fun ensureCurrent()

    /**
     * Everything [key] reads at this revision, transitively, without entering a key [stopAt] names. It reads [key]
     * first, so its memos are current, and the caller depends on [key].
     */
    fun readsOf(
        key: Query<E, *>,
        stopAt: (GraphKey<*>) -> Boolean = { false },
    ): Set<GraphKey<*>>
}

/** Control flow of the graph. Code between a query and its caller, such as a provider boundary, rethrows it. */
sealed class QueryControl : CancellationException()

/** The revision a read is pinned to is no longer the newest. */
class StaleRevision : QueryControl()

/** Unwinds from the read that closed a cycle to its first member, the [head]. */
internal class CycleSignal(
    val head: GraphKey<*>,
    val members: List<GraphKey<*>>,
) : QueryControl()

/**
 * A read of a key whose current result is a cycle the reader is a member of: the reader takes its own recovery value
 * too, whichever member the graph entered first.
 */
internal class CycleMember(
    val members: List<GraphKey<*>>,
) : QueryControl()

/** A cycle whose members give no recovery value. */
class QueryCycle(
    val members: List<GraphKey<*>>,
) : IllegalStateException("Queries read each other in a cycle: $members")

data class GraphLimits(
    /** Above this many memos, the least recently used ones are forgotten. */
    val maxMemos: Int = 200_000,
) {
    init {
        require(maxMemos > 0) { "maxMemos must be positive, got $maxMemos" }
    }
}

/**
 * What the graph did, as it happens; Salsa's event callback is the precedent. It is called outside the graph's lock and
 * must not read the graph. A fork does not report.
 */
interface GraphListener {
    /** A query runs its compute, also when the result turns out equal to the last one. */
    fun computed(key: GraphKey<*>) {}

    /** A memo was forgotten to stay within [GraphLimits.maxMemos]. */
    fun evicted(key: GraphKey<*>) {}

    companion object {
        val NONE: GraphListener = object : GraphListener {}
    }
}

/**
 * Inputs, memoized queries, recorded reads and early cutoff over an environment [E], after Salsa and Adapton.
 *
 * Every read a query makes is an edge that remembers the revision at which what it read last changed. An [advance]
 * marks the edges that read a changed input dirty, and the edges that read their readers, up to the first edge already
 * dirty; nothing else is touched. A read of a result without dirty edges returns it as it is. A read of a result with
 * dirty edges cleans them in read order: it brings each dependency up to date and compares the revision it last changed
 * at with the one the edge saw, and reruns the query at the first difference. A rerun with an equal result keeps the
 * revision it last changed at, so propagation stops there.
 *
 * Queries run with no lock of the graph held; two threads may compute one query at once, and a run overtaken by a newer
 * revision is thrown away. A chain of any depth runs on [DeepStacks].
 */
class TrackedGraph<E> private constructor(
    initial: Snapshot<E>,
    private val limits: GraphLimits,
    private val listener: GraphListener,
    /** The graph this one was forked from, read through for what the fork's overlay does not reach; null for a root. */
    private val base: ForkBase<E>?,
) {
    constructor(
        environment: E,
        limits: GraphLimits = GraphLimits(),
        listener: GraphListener = GraphListener.NONE,
    ) : this(Snapshot(FIRST_REVISION, environment), limits, listener, null)

    /** Every result and the edges it read, by key. A fork holds only its own. */
    private val memos = HashMap<GraphKey<*>, Memo>()

    /** The keys whose memo holds a value, least recently used first; only these count against the limit. */
    private val held = LinkedHashMap<GraphKey<*>, Unit>(16, 0.75f, true)

    /** The edges that read each key, so an advance finds what a change reaches without looking at anything else. */
    private val readers = HashMap<GraphKey<*>, MutableSet<Edge>>()

    /** How many dirty edges each key has; a key missing here has none. */
    private val dirty = HashMap<GraphKey<*>, Int>()

    /** Results that are rerun at every revision a reader needs them: failures and members of a cycle. */
    private val volatiles = HashSet<GraphKey<*>>()

    /** The revision at which each input last read differently; an input missing here never changed, or for a fork, did not change in it. */
    private val inputChangedAt = HashMap<InputKey<E, *>, Long>()

    /** Rises with every memo stored or cleaned, so a fork tells results it saw when it was made from later ones. */
    private var sequence = 0L

    /** Guards every map above, [sequence], and every swap of [state] and [resets]. Never held while a query runs. */
    private val maps = Any()

    /** How often this graph was reset, so a fork knows when what it started from is gone. */
    @Volatile
    private var resets = 0L

    /** The revision and its environment, swapped together, so a pinned read sees one consistent state. */
    @Volatile
    private var state: Snapshot<E> = initial

    val revision: Long get() = state.revision

    /** True for a fork whose base moved on or was reset: every read of it throws [StaleRevision]. */
    val isStale: Boolean get() = base?.moved == true

    /**
     * Starts a revision at [environment]. Of [candidates], only keys that read differently from before count as changed,
     * and the edges that reach them are marked on [work]. A fork does not advance; fork the base again instead.
     */
    fun advance(
        environment: E,
        candidates: Set<InputKey<E, *>>,
        work: GraphWork = GraphWork(),
    ) {
        check(base == null) { "A fork does not advance; fork its base again" }
        synchronized(maps) {
            val previous = state
            val next = previous.revision + 1
            for (key in changedInputs(previous.environment, environment, candidates)) {
                inputChangedAt[key] = next
                markReadersOf(key, work)
            }
            markVolatiles(work)
            state = Snapshot(next, environment)
        }
    }

    /** Forgets every memo, for a change that makes all of them meaningless, such as a new catalog. */
    fun reset(environment: E) {
        synchronized(maps) {
            memos.clear()
            held.clear()
            readers.clear()
            dirty.clear()
            volatiles.clear()
            inputChangedAt.clear()
            resets++
            // The revision keeps rising, so a run that started before the reset can never store.
            state = Snapshot(state.revision + 1, environment)
        }
    }

    /**
     * Reads pinned to the current revision. They throw [StaleRevision] once a newer revision exists. What they compute,
     * clean and walk is counted on [work].
     */
    fun pin(work: GraphWork): QueryReads<E> = Pinned(state, work)

    /**
     * A separate graph at [environment], one revision past this one's current, valid only while this graph stays at that
     * revision: once this graph advances or is reset, every read of the fork throws [StaleRevision], and a caller that
     * still needs [environment] forks again. It copies nothing. Making it marks, on [work], the results of this graph
     * that read the changed inputs; every other result of this graph it reads as it is. Nothing it computes reaches
     * this graph unless this graph [merge]s it. It does not report to the listener.
     */
    fun fork(
        environment: E,
        candidates: Set<InputKey<E, *>>,
        work: GraphWork = GraphWork(),
    ): TrackedGraph<E> =
        synchronized(maps) {
            check(base == null) { "A fork is not forked again; fork its base" }
            val current = state
            val changed = changedInputs(current.environment, environment, candidates)
            val next = Snapshot(current.revision + 1, environment)
            val forked =
                TrackedGraph(
                    next,
                    limits,
                    GraphListener.NONE,
                    ForkBase(this, current.revision, resets, sequence, changed, coneOf(changed, work)),
                )
            changed.forEach { forked.inputChangedAt[it] = next.revision }
            forked
        }

    /**
     * Makes [fork]'s revision this graph's next one, keeping every result it computed, when this graph is still at the
     * revision [fork] started from and was not reset since; the listener hears each computation the fork ran. So work done
     * on a fork of what becomes this graph's next state is not done again. Returns false, changing nothing, when [fork] is
     * not a fork of this graph or this graph moved on; the caller then advances as usual. The edges the fork's changes
     * reach are marked on [work], as an advance marks them.
     */
    fun merge(
        fork: TrackedGraph<E>,
        work: GraphWork = GraphWork(),
    ): Boolean {
        val from = fork.base ?: return false
        if (from.graph !== this) return false
        val (computed, evicted) =
            synchronized(maps) {
                if (state.revision != from.revision || resets != from.resets) return false
                val (next, own) = synchronized(fork.maps) { fork.state to HashMap(fork.memos) }
                for (key in from.changed) {
                    inputChangedAt[key] = next.revision
                    markReadersOf(key, work)
                }
                markVolatiles(work)
                for ((key, memo) in own) install(key, memo, memo.edges.count { it.dirty })
                state = next
                own.filterValues { it.computedAt > from.revision }.keys to evictOverLimit()
            }
        computed.forEach(listener::computed)
        evicted.forEach(listener::evicted)
        return true
    }

    /** The keys of [candidates] that read differently at [after] than at [before]; a failing read counts as changed. */
    private fun changedInputs(
        before: E,
        after: E,
        candidates: Set<InputKey<E, *>>,
    ): Set<InputKey<E, *>> = candidates.filterTo(LinkedHashSet()) { runCatching { it.read(before) } != runCatching { it.read(after) } }

    /**
     * Marks every edge that reads [key] dirty, and through each reader that had no dirty edge yet, the edges that read
     * that reader. A reader already dirty has dirty readers, so marking stops there. Called under the lock.
     */
    private fun markReadersOf(
        key: GraphKey<*>,
        work: GraphWork,
    ) {
        val pending = ArrayDeque<GraphKey<*>>(listOf(key))
        while (pending.isNotEmpty()) {
            for (edge in readers[pending.removeLast()].orEmpty()) {
                if (edge.dirty) continue
                edge.dirty = true
                work.dirtied()
                if (dirty.merge(edge.reader, 1, Int::plus) == 1) pending += edge.reader
            }
        }
    }

    /** Marks the readers of every failure and cycle member, which rerun at each revision. Called under the lock. */
    private fun markVolatiles(work: GraphWork) = volatiles.forEach { markReadersOf(it, work) }

    /** Every key whose result read one of [changed], directly or through other results, at this graph's revision. Called under the lock. */
    private fun coneOf(
        changed: Set<InputKey<E, *>>,
        work: GraphWork,
    ): Set<GraphKey<*>> {
        val cone = HashSet<GraphKey<*>>()
        val pending = ArrayDeque<GraphKey<*>>(changed)
        while (pending.isNotEmpty()) {
            for (edge in readers[pending.removeLast()].orEmpty()) {
                if (cone.add(edge.reader)) {
                    work.dirtied()
                    pending += edge.reader
                }
            }
        }
        return cone
    }

    private fun <T> fetch(
        key: GraphKey<T>,
        frame: Frame,
    ): T {
        frame.ensureCurrent()
        // Recorded before the read: a caller that catches the read's failure must rerun once the failure clears.
        frame.record(key)
        try {
            @Suppress("UNCHECKED_CAST")
            return when (key) {
                is InputKey<*, *> -> (key as InputKey<E, T>).read(frame.snapshot.environment)
                is Query<*, *> -> fetchQuery(key as Query<E, T>, frame)
            }
        } finally {
            frame.saw(key)
        }
    }

    private fun <T> fetchQuery(
        query: Query<E, T>,
        frame: Frame,
    ): T {
        frame.stack.indexOf(query)?.let { index -> throw CycleSignal(query, frame.stack.keysFrom(index)) }

        val found = lookup(query, frame.revision)
        if (found?.current == true) {
            frame.joinCycle(found.memo.cycle)
            @Suppress("UNCHECKED_CAST")
            return found.memo.value as T
        }

        // Pushed before cleaning too, so a dependency that reads back while it is cleaned is a cycle, never an unbounded
        // recursion.
        val running = frame.push(query)
        try {
            // Cleaning recurses as deep as computing, so both run on a sufficient stack.
            return onSufficientStack(running.depth) { cleanOrCompute(query, found?.memo, running) }
        } catch (cycle: CycleSignal) {
            if (query !in cycle.members) throw cycle
            val recovered = recover(query, cycle.members, found?.memo, running, frame)
            if (cycle.head != query) throw cycle
            return recovered
        } catch (member: CycleMember) {
            if (query !in member.members) throw member
            val recovered = recover(query, member.members, found?.memo, running, frame)
            frame.joinCycle(member.members)
            return recovered
        } finally {
            frame.pop()
        }
    }

    /**
     * Stores the recovery value of [query] as a member of the cycle of [members], with the reads it made so far. An equal
     * recovery value keeps the revision it last changed at, so readers outside the cycle stop there.
     */
    private fun <T> recover(
        query: Query<E, T>,
        members: List<GraphKey<*>>,
        before: Memo?,
        running: Frame,
        frame: Frame,
    ): T {
        val recovered = failing(query, running) { query.onCycle(members) }
        val changedAt = if (before != null && before.cycle != null && before.value == recovered) before.changedAt else frame.revision
        store(query, Memo(recovered, running.edges(query), members, changedAt, frame.revision), frame)
        return recovered
    }

    private fun <T> cleanOrCompute(
        query: Query<E, T>,
        memo: Memo?,
        running: Frame,
    ): T {
        if (memo != null && !memo.isVolatile && clean(memo, running)) {
            if (memo.value !== EVICTED) {
                // Two reads may clean one memo at once; only the one that clears its marks counts, so counts are repeatable.
                if (storeCleaned(query, memo, running)) running.work.cleaned()
                @Suppress("UNCHECKED_CAST")
                return memo.value as T
            }
            // Nothing it read changed, so the query, being pure, gives its forgotten value again.
            return compute(query, memo.changedAt, running)
        }
        return compute(query, null, running)
    }

    /**
     * Runs [query]'s compute and stores what it gives. It keeps [unchangedAt] when given, the revision a forgotten value
     * last changed at, and otherwise the revision of an equal earlier value.
     */
    private fun <T> compute(
        query: Query<E, T>,
        unchangedAt: Long?,
        running: Frame,
    ): T {
        val before = memoOf(query)
        listener.computed(query)
        running.work.computed()
        val value = failing(query, running) { context(running) { query.compute() } }
        val changedAt =
            unchangedAt
                ?: before?.takeIf { !it.isVolatile && it.value !== EVICTED && it.value == value }?.changedAt
                ?: running.revision
        store(query, Memo(value, running.edges(query), null, changedAt, running.revision), running)
        return value
    }

    /**
     * True when no dirty edge of [memo] reads a dependency that changed since the edge saw it. Dirty edges are cleaned in
     * read order, as compute reads, so a branch the query no longer takes is never brought up to date for nothing. A
     * dependency that fails counts as changed, so the caller recomputes and meets the failure itself.
     */
    private fun clean(
        memo: Memo,
        frame: Frame,
    ): Boolean {
        val marked = synchronized(maps) { memo.edges.filter { it.dirty } }
        for (edge in marked) {
            val dependency = edge.dependency
            // Cleaning is not reading, so it records nothing on the running query.
            if (dependency is Query<*, *> && attempt { fetch(dependency, frame.withoutRecording()) } != null) return false
            if (changedAtOf(dependency) != edge.seen) return false
        }
        return true
    }

    /** The revision at which [key] last changed, as far as this graph knows it now. */
    @Suppress("UNCHECKED_CAST")
    private fun changedAtOf(key: GraphKey<*>): Long =
        when (key) {
            is InputKey<*, *> -> inputChangedAtOf(key as InputKey<E, *>)
            is Query<*, *> -> memoOf(key)?.changedAt ?: NEVER_CHANGED
        }

    private fun readsOf(
        key: Query<E, *>,
        stopAt: (GraphKey<*>) -> Boolean,
        frame: Frame,
    ): Set<GraphKey<*>> {
        fetch(key, frame)
        val found = LinkedHashSet<GraphKey<*>>()
        val pending = ArrayDeque<Query<E, *>>(listOf(key))
        while (pending.isNotEmpty()) {
            for (dependency in currentDependencies(pending.removeLast(), frame)) {
                @Suppress("UNCHECKED_CAST")
                if (!found.add(dependency)) continue
                frame.work.walked()
                if (dependency is Query<*, *> && !stopAt(dependency)) pending += dependency as Query<E, *>
            }
        }
        return found
    }

    /**
     * The direct dependencies of [query] at the frame's revision. A query that fails keeps the reads it made before it
     * failed.
     */
    private fun currentDependencies(
        query: Query<E, *>,
        frame: Frame,
    ): List<GraphKey<*>> {
        frame.ensureCurrent()
        lookup(query, frame.revision)?.takeIf { it.current }?.let { found -> return found.memo.edges.map { it.dependency } }
        attempt { fetch(query, frame.walking()) }
        return memoOf(query)?.edges?.map { it.dependency }.orEmpty()
    }

    /**
     * The memo of [key] and whether it is current at [revision]: a value that is not forgotten, no dirty edge, and for a
     * failure or a cycle member, computed at [revision]. A failure is never current, so a read tries again. A fork finds
     * its own memo, or one of its base's it can use as it is, or copies the base's with the edges its overlay reaches
     * marked dirty.
     */
    private fun lookup(
        key: Query<E, *>,
        revision: Long,
    ): Found? {
        val fork = base
        synchronized(maps) {
            ensureCurrent(revision)
            memos[key]?.let { memo -> return Found(memo, isCurrent(key, memo, revision)) }
        }
        if (fork == null) return null
        val shared = fork.memoOf(key) ?: return null
        if (fork.usable(key)) return Found(shared, shared.value !== EVICTED)
        val copy = fork.copyOf(key) ?: return null
        synchronized(maps) {
            ensureCurrent(revision)
            memos[key]?.let { memo -> return Found(memo, isCurrent(key, memo, revision)) }
            install(key, copy, copy.edges.count { it.dirty })
            return Found(copy, false)
        }
    }

    /** Called under the lock. */
    private fun isCurrent(
        key: GraphKey<*>,
        memo: Memo,
        revision: Long,
    ): Boolean {
        if (memo.value === EVICTED || memo.value === FAILED || key in dirty) return false
        if (memo.isVolatile && memo.computedAt != revision) return false
        held[key]
        return true
    }

    /** The memo of [key] this graph reads: its own, or for a fork, its base's when the fork can use it as it is. */
    private fun memoOf(key: GraphKey<*>): Memo? = synchronized(maps) { memos[key] } ?: base?.takeIf { it.usable(key) }?.memoOf(key)

    private fun inputChangedAtOf(key: InputKey<E, *>): Long =
        synchronized(maps) { inputChangedAt[key] } ?: base?.inputChangedAt(key) ?: NEVER_CHANGED

    /**
     * Clears the marks of [memo] found unchanged at the frame's revision. advance and reset swap the revision under the
     * same lock, so a clean overtaken by an advance never clears a mark of the newer revision. Returns whether it cleared
     * any.
     */
    private fun storeCleaned(
        key: GraphKey<*>,
        memo: Memo,
        frame: Frame,
    ): Boolean =
        synchronized(maps) {
            ensureCurrent(frame.revision)
            if (memos[key] !== memo) return false
            memo.edges.forEach { it.dirty = false }
            memos[key] = memo.copy(sequence = ++sequence)
            held[key]
            dirty.remove(key) != null
        }

    /** The only write of a computed memo. advance and reset swap the revision under the same lock, so a stale run never stores. */
    private fun store(
        key: GraphKey<*>,
        memo: Memo,
        frame: Frame,
    ) {
        val evicted =
            synchronized(maps) {
                ensureCurrent(frame.revision)
                install(key, memo, 0)
                evictOverLimit()
            }
        evicted.forEach(listener::evicted)
    }

    /** Puts [memo] in place of whatever [key] held, with [dirtyEdges] of its edges marked. Called under the lock. */
    private fun install(
        key: GraphKey<*>,
        memo: Memo,
        dirtyEdges: Int,
    ) {
        val before = memos.put(key, memo.copy(sequence = ++sequence))
        if (before?.edges !== memo.edges) {
            before?.edges?.forEach { readers[it.dependency]?.remove(it) }
            memo.edges.forEach { readers.getOrPut(it.dependency) { LinkedHashSet() } += it }
        }
        if (dirtyEdges > 0) dirty[key] = dirtyEdges else dirty.remove(key)
        if (memo.isVolatile) volatiles += key else volatiles -= key
        if (memo.value === EVICTED || memo.value === FAILED) held.remove(key) else held[key] = Unit
    }

    /**
     * Runs [body], and stores [query] as failed when [body] fails with a failure of its own: never current, so the next
     * read tries again, and changed at this revision, so a reader that saw it reruns once it clears, even when the value it
     * returns to equals the old one. The failure keeps the reads it made, so an advance still reaches it.
     */
    private inline fun <T> failing(
        query: Query<E, *>,
        running: Frame,
        body: () -> T,
    ): T =
        runCatching(body).getOrElse { failure ->
            if (failure !is QueryControl) {
                synchronized(maps) {
                    if (state.revision == running.revision && base?.moved != true) {
                        install(query, Memo(FAILED, running.edges(query), null, running.revision, running.revision), 0)
                    }
                }
            }
            throw failure
        }

    /**
     * Forgets the values of the least recently used memos above the limit, and returns their keys. A memo keeps its edges
     * and the revision it last changed at, so an advance still reaches it and its readers stay clean. It keeps them also
     * when nothing reads it yet: a query still running may have read it and store its edge later. Called under the lock.
     */
    private fun evictOverLimit(): List<GraphKey<*>> {
        if (held.size <= limits.maxMemos) return emptyList()
        val evicted = ArrayList<GraphKey<*>>(held.size - limits.maxMemos)
        val eldest = held.keys.iterator()
        while (held.size > limits.maxMemos) {
            val key = eldest.next()
            eldest.remove()
            evicted += key
            memos[key]?.let { memo -> memos[key] = memo.copy(value = EVICTED) }
        }
        return evicted
    }

    private fun ensureCurrent(revision: Long) {
        if (state.revision != revision || base?.moved == true) throw StaleRevision()
    }

    /** Every [STACK_SEGMENT] nested queries, and at the first query on a thread outside the pool, the next one runs on a fresh large stack. */
    private inline fun <T> onSufficientStack(
        depth: Int,
        crossinline body: () -> T,
    ): T = if (depth % STACK_SEGMENT != 0 && DeepStacks.isCurrent()) body() else DeepStacks.run { body() }

    /**
     * What a fork knows of the graph it was forked from at [revision]: the inputs its overlay changed, and the [cone] of
     * results that read them when it was made. The base cannot advance while the fork is valid, so each of its results is
     * a true statement about the fork's revision too, unless it reads the overlay. A result the base had no dirty edge on
     * when the fork was made and has not touched since reads the overlay exactly when it is in the cone; one the base
     * stored or cleaned since is judged by its dependencies, since its edges are what it reads now.
     */
    private class ForkBase<E>(
        val graph: TrackedGraph<E>,
        val revision: Long,
        val resets: Long,
        val sequence: Long,
        val changed: Set<InputKey<E, *>>,
        val cone: Set<GraphKey<*>>,
    ) {
        private val usable = ConcurrentHashMap<GraphKey<*>, Boolean>()

        val moved: Boolean get() = graph.state.revision != revision || graph.resets != resets

        fun memoOf(key: GraphKey<*>): Memo? = synchronized(graph.maps) { graph.memos[key] }

        fun inputChangedAt(key: InputKey<E, *>): Long = synchronized(graph.maps) { graph.inputChangedAt[key] } ?: NEVER_CHANGED

        /** The base's memo of [key] for the fork, with fresh edges marked dirty where the base marked them or the overlay reaches. */
        fun copyOf(key: GraphKey<*>): Memo? =
            synchronized(graph.maps) {
                graph.memos[key]?.copyFor(key) { edge -> edge.dirty || !usableDependency(edge.dependency) }
            }

        fun usableDependency(key: GraphKey<*>): Boolean = if (key is InputKey<*, *>) key !in changed else usable(key)

        /** True when the base's result of [key] is the fork's result too, so the fork reads it as it is. */
        fun usable(key: GraphKey<*>): Boolean {
            usable[key]?.let { return it }
            // Depth first, dependencies before the result that read them, without recursion, so a long chain fits.
            val pending = ArrayDeque<GraphKey<*>>(listOf(key))
            while (pending.isNotEmpty()) {
                val next = pending.last()
                if (usable.containsKey(next)) {
                    pending.removeLast()
                    continue
                }
                val judged = judge(next)
                if (judged != null) {
                    usable[next] = judged
                    pending.removeLast()
                    continue
                }
                val dependencies =
                    memoOf(next)
                        ?.edges
                        ?.map { it.dependency }
                        .orEmpty()
                        .filter { it is Query<*, *> }
                val unjudged = dependencies.filter { !usable.containsKey(it) }
                if (unjudged.isEmpty()) {
                    usable[next] =
                        dependencies.all { usable.getValue(it) } && memoOf(next)?.edges.orEmpty().all { usableDependency(it.dependency) }
                    pending.removeLast()
                } else {
                    pending += unjudged
                }
            }
            return usable.getValue(key)
        }

        /** The answer for [key] that needs no look at its dependencies, or null when they decide. */
        private fun judge(key: GraphKey<*>): Boolean? =
            synchronized(graph.maps) {
                val memo = graph.memos[key] ?: return@synchronized false
                when {
                    memo.isVolatile || memo.value === FAILED || key in graph.dirty -> false
                    memo.sequence <= sequence -> key !in cone
                    else -> null
                }
            }
    }

    /** What a pinned [QueryReads] hands out: each read starts with an empty stack of running queries. */
    private inner class Pinned(
        private val snapshot: Snapshot<E>,
        private val work: GraphWork,
    ) : QueryReads<E> {
        @UntrackedEnvironment
        override val environment: E get() = snapshot.environment

        override val revision: Long get() = snapshot.revision

        override fun <T> read(key: GraphKey<T>): T {
            work.read()
            return fetch(key, Frame(snapshot, RunningQueries(), null, work, null))
        }

        override fun ensureCurrent() = ensureCurrent(snapshot.revision)

        override fun readsOf(
            key: Query<E, *>,
            stopAt: (GraphKey<*>) -> Boolean,
        ): Set<GraphKey<*>> = readsOf(key, stopAt, Frame(snapshot, RunningQueries(), null, work, null))
    }

    /**
     * One step of a read: the queries running above it, where the running query records its reads and what each one saw,
     * if it does, and the query whose direct read this is, if any.
     */
    private inner class Frame(
        val snapshot: Snapshot<E>,
        val stack: RunningQueries,
        private val recorded: LinkedHashMap<GraphKey<*>, Long>?,
        val work: GraphWork,
        private val reader: Query<E, *>?,
    ) : QueryReads<E> {
        @UntrackedEnvironment
        override val environment: E get() = snapshot.environment

        override val revision: Long get() = snapshot.revision

        val depth: Int get() = stack.size

        override fun <T> read(key: GraphKey<T>): T {
            work.read()
            return fetch(key, this)
        }

        override fun ensureCurrent() = ensureCurrent(snapshot.revision)

        override fun readsOf(
            key: Query<E, *>,
            stopAt: (GraphKey<*>) -> Boolean,
        ): Set<GraphKey<*>> = readsOf(key, stopAt, this)

        fun record(key: GraphKey<*>) {
            recorded?.putIfAbsent(key, NEVER_CHANGED)
        }

        /** Remembers the revision at which [key] last changed, as the read just met it. */
        fun saw(key: GraphKey<*>) {
            if (recorded != null) recorded[key] = changedAtOf(key)
        }

        /** The edges of [query]'s reads, in read order, each with what it saw. */
        fun edges(query: Query<E, *>): List<Edge> = recorded?.map { (key, seen) -> Edge(query, key, seen) }.orEmpty()

        /** The frame of [query] running on top of this one. */
        fun push(query: Query<E, *>): Frame {
            stack.push(query)
            return Frame(snapshot, stack, LinkedHashMap(), work, query)
        }

        fun pop() = stack.pop()

        /** The same reader, recording nothing: cleaning a dependency is not reading it. */
        fun withoutRecording(): Frame = Frame(snapshot, stack, null, work, reader)

        /** No reader: a walk of what a query read visits keys that query did not read directly. */
        fun walking(): Frame = Frame(snapshot, stack, null, work, null)

        /** A reader that is a member of [cycle] takes its own recovery value too. */
        fun joinCycle(cycle: List<GraphKey<*>>?) {
            val reader = reader ?: return
            if (cycle != null && reader in cycle) throw CycleMember(cycle)
        }
    }

    private companion object {
        const val FIRST_REVISION = 1L
        const val NEVER_CHANGED = 0L
        const val STACK_SEGMENT = 32
    }
}

/** A revision and the environment it reads. */
private class Snapshot<E>(
    val revision: Long,
    val environment: E,
)

/** The value of a memo whose value the limit forgot; its edges and the revision it last changed at stay. */
private object EVICTED

/** The value of a memo whose query failed with a failure of its own. */
private object FAILED

/** The result of a lookup: a memo, and whether it is current at the revision asked about. */
private class Found(
    val memo: Memo,
    val current: Boolean,
)

/**
 * One read a query made: of [dependency], which last changed at revision [seen] when [reader] read it. [dirty] says an
 * advance reached it since; only the graph's lock reads or writes it.
 */
private class Edge(
    val reader: GraphKey<*>,
    val dependency: GraphKey<*>,
    val seen: Long,
) {
    var dirty = false
}

/** Immutable apart from its edges' marks, and stamped with its own revisions. */
private data class Memo(
    val value: Any?,
    /** Direct, in read order. */
    val edges: List<Edge>,
    /** The members of the cycle this result recovered from, in the order the graph met them; null when it is no cycle's. */
    val cycle: List<GraphKey<*>>?,
    val changedAt: Long,
    /** The revision its value and edges were last computed at. */
    val computedAt: Long,
    /** The graph's sequence when it was stored or last cleaned. */
    val sequence: Long = 0,
) {
    /** A failure or a cycle member, rerun at every revision a reader needs it. */
    val isVolatile: Boolean get() = value === FAILED || cycle != null

    /** A copy for a fork, read by [reader], with fresh edges marked dirty where [marked] says. */
    fun copyFor(
        reader: GraphKey<*>,
        marked: (Edge) -> Boolean,
    ): Memo = copy(edges = edges.map { edge -> Edge(reader, edge.dependency, edge.seen).also { it.dirty = marked(edge) } })
}

/**
 * The queries running in one read, innermost last, with an index for cycle checks. A read moves between threads only
 * by handing off and waiting, so it needs no lock.
 */
private class RunningQueries {
    private val keys = ArrayList<GraphKey<*>>()
    private val positions = HashMap<GraphKey<*>, Int>()

    val size: Int get() = keys.size

    fun indexOf(key: GraphKey<*>): Int? = positions[key]

    fun keysFrom(index: Int): List<GraphKey<*>> = keys.subList(index, keys.size).toList()

    fun push(key: GraphKey<*>) {
        positions[key] = keys.size
        keys += key
    }

    fun pop() {
        positions.remove(keys.removeLast())
    }
}

/**
 * Runs [body] and returns its failure, or null when it succeeded. Graph control flow, cancellation, interruption and
 * errors are rethrown; only a query's own failure is returned.
 */
private inline fun attempt(body: () -> Unit): Exception? {
    val failure = runCatching(body).exceptionOrNull() ?: return null
    if (failure !is Exception || failure is CancellationException || failure is InterruptedException) throw failure
    return failure
}
