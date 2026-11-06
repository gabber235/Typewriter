package com.typewritermc.formula.graph

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
 * Inputs, memoized queries, recorded reads and early cutoff over an environment [E], after Salsa.
 *
 * Each [advance] starts a revision. A memo is reused when none of its direct dependencies changed since it was last
 * verified, and a rerun with an equal result does not count as a change, so propagation stops there. Queries run with
 * no lock of the graph held; two threads may compute one query at once, and a run overtaken by a newer revision is
 * thrown away. A chain of any depth runs on [DeepStacks].
 */
class TrackedGraph<E> private constructor(
    initial: Snapshot<E>,
    /** In access order, so the eldest entry is the least recently used memo. */
    private val memos: LinkedHashMap<GraphKey<*>, Memo>,
    /** The revision at which each input last read differently; an input missing here never changed. */
    private val inputChangedAt: HashMap<InputKey<E, *>, Long>,
    private val limits: GraphLimits,
    private val listener: GraphListener,
) {
    constructor(
        environment: E,
        limits: GraphLimits = GraphLimits(),
        listener: GraphListener = GraphListener.NONE,
    ) : this(Snapshot(FIRST_REVISION, environment), accessOrdered(emptyMap()), HashMap(), limits, listener)

    /** Guards [memos] and [inputChangedAt], and every swap of [state]. Never held while a query runs. */
    private val maps = Any()

    /** The revision and its environment, swapped together, so a pinned read sees one consistent state. */
    @Volatile
    private var state: Snapshot<E> = initial

    val revision: Long get() = state.revision

    /** Starts a revision at [environment]. Of [candidates], only keys that read differently from before count as changed. */
    fun advance(
        environment: E,
        candidates: Set<InputKey<E, *>>,
    ) {
        synchronized(maps) {
            val previous = state
            val next = previous.revision + 1
            for (key in candidates) {
                // A read that fails counts as changed, since no failure equals another.
                if (runCatching { key.read(previous.environment) } != runCatching { key.read(environment) }) {
                    inputChangedAt[key] = next
                }
            }
            state = Snapshot(next, environment)
        }
    }

    /** Forgets every memo, for a change that makes all of them meaningless, such as a new catalog. */
    fun reset(environment: E) {
        synchronized(maps) {
            memos.clear()
            inputChangedAt.clear()
            // The revision keeps rising, so a run that started before the reset can never store.
            state = Snapshot(state.revision + 1, environment)
        }
    }

    /** Reads pinned to the current revision. They throw [StaleRevision] once a newer revision exists. */
    fun pin(): QueryReads<E> = Pinned(state)

    /**
     * A separate graph: a copy of this one's memos and change times, advanced to [environment]. It never looks back,
     * so the base moving on does not change its answers, and nothing it computes reaches the base. It does not report
     * to the listener.
     */
    fun fork(
        environment: E,
        candidates: Set<InputKey<E, *>>,
    ): TrackedGraph<E> {
        val copy =
            synchronized(maps) {
                TrackedGraph(state, accessOrdered(memos), HashMap(inputChangedAt), limits, GraphListener.NONE)
            }
        copy.advance(environment, candidates)
        return copy
    }

    private fun <T> fetch(
        key: GraphKey<T>,
        frame: Frame,
    ): T {
        frame.ensureCurrent()
        // Recorded before the read: a caller that catches the read's failure must rerun once the failure clears.
        frame.record(key)
        @Suppress("UNCHECKED_CAST")
        when (key) {
            is InputKey<*, *> -> return (key as InputKey<E, T>).read(frame.snapshot.environment)
            is Query<*, *> -> return fetchQuery(key as Query<E, T>, frame)
        }
    }

    private fun <T> fetchQuery(
        query: Query<E, T>,
        frame: Frame,
    ): T {
        frame.stack.indexOf(query)?.let { index -> throw CycleSignal(query, frame.stack.keysFrom(index)) }

        val memo = memoOf(query)
        @Suppress("UNCHECKED_CAST")
        if (memo != null && memo.verifiedAt == frame.revision) return memo.value as T

        // Pushed before verifying too, so a dependency that reads back during verification is a cycle, never an
        // unbounded recursion.
        val running = frame.push(query)
        try {
            // Verifying recurses as deep as computing, so both run on a sufficient stack.
            return onSufficientStack(running.depth) { verifyOrCompute(query, memo, running) }
        } catch (cycle: CycleSignal) {
            if (query !in cycle.members) throw cycle
            val recovered = failing(query, frame) { query.onCycle(cycle.members) }
            store(query, Memo(recovered, running.dependencies(), true, frame.revision, frame.revision), frame)
            if (cycle.head != query) throw cycle
            return recovered
        } finally {
            frame.pop()
        }
    }

    private fun <T> verifyOrCompute(
        query: Query<E, T>,
        memo: Memo?,
        running: Frame,
    ): T {
        if (memo != null && !memo.inCycle && verify(memo, running)) {
            store(query, memo.copy(verifiedAt = running.revision), running)
            @Suppress("UNCHECKED_CAST")
            return memo.value as T
        }
        listener.computed(query)
        val value = failing(query, running) { context(running) { query.compute() } }
        val changedAt = if (memo != null && memo.value == value) memo.changedAt else running.revision
        store(query, Memo(value, running.dependencies(), false, running.revision, changedAt), running)
        return value
    }

    /** True when no direct dependency of [memo] changed since it was verified. Checked in read order, as compute reads. */
    private fun verify(
        memo: Memo,
        frame: Frame,
    ): Boolean =
        memo.dependencies.all { dependency ->
            @Suppress("UNCHECKED_CAST")
            when (dependency) {
                is InputKey<*, *> -> changedAtOf(dependency as InputKey<E, *>) <= memo.verifiedAt
                is Query<*, *> -> unchangedSince(dependency as Query<E, *>, memo.verifiedAt, frame)
            }
        }

    /** A dependency that fails or has no memo counts as changed, so the caller recomputes and meets the failure itself. */
    private fun unchangedSince(
        dependency: Query<E, *>,
        since: Long,
        frame: Frame,
    ): Boolean {
        // Verifying is not reading, so it records nothing on the running query.
        if (attempt { fetch(dependency, frame.withoutRecording()) } != null) return false
        return memoOf(dependency)?.let { it.changedAt <= since } ?: false
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
                if (found.add(dependency) && dependency is Query<*, *> && !stopAt(dependency)) {
                    pending += dependency as Query<E, *>
                }
            }
        }
        return found
    }

    /**
     * The direct dependencies of [query] at the frame's revision. Below a read every memo is current, unless it was
     * evicted since; a query that fails keeps no memo, so its reads are unknown.
     */
    private fun currentDependencies(
        query: Query<E, *>,
        frame: Frame,
    ): List<GraphKey<*>> {
        frame.ensureCurrent()
        val memo = memoOf(query)?.takeIf { it.verifiedAt == frame.revision }
        if (memo != null) return memo.dependencies
        attempt { fetch(query, frame.withoutRecording()) }
        return memoOf(query)?.takeIf { it.verifiedAt == frame.revision }?.dependencies.orEmpty()
    }

    /** The only write of a memo. advance and reset swap the revision under the same lock, so a stale run never stores. */
    private fun store(
        key: GraphKey<*>,
        memo: Memo,
        frame: Frame,
    ) {
        val evicted =
            synchronized(maps) {
                if (state.revision != frame.revision) throw StaleRevision()
                memos[key] = memo
                evictOverLimit()
            }
        evicted.forEach(listener::evicted)
    }

    /**
     * Runs [body], and forgets the memo of [query] when [body] fails with a failure of its own. A failure is never a
     * value, and a reader that saw it must rerun once it clears, even when the value it returns to equals the old one.
     */
    private inline fun <T> failing(
        query: Query<E, *>,
        frame: Frame,
        body: () -> T,
    ): T =
        runCatching(body).getOrElse { failure ->
            if (failure !is QueryControl) {
                synchronized(maps) { if (state.revision == frame.revision) memos.remove(query) }
            }
            throw failure
        }

    /** Forgets the least recently used memos above the limit, and returns their keys. Called under the lock. */
    private fun evictOverLimit(): List<GraphKey<*>> {
        if (memos.size <= limits.maxMemos) return emptyList()
        val evicted = ArrayList<GraphKey<*>>(memos.size - limits.maxMemos)
        val eldest = memos.keys.iterator()
        while (memos.size > limits.maxMemos) {
            evicted += eldest.next()
            eldest.remove()
        }
        return evicted
    }

    private fun memoOf(key: GraphKey<*>): Memo? = synchronized(maps) { memos[key] }

    private fun changedAtOf(key: InputKey<E, *>): Long = synchronized(maps) { inputChangedAt[key] ?: NEVER_CHANGED }

    private fun ensureCurrent(revision: Long) {
        if (state.revision != revision) throw StaleRevision()
    }

    /** Every [STACK_SEGMENT] nested queries, and at the first query on a thread outside the pool, the next one runs on a fresh large stack. */
    private inline fun <T> onSufficientStack(
        depth: Int,
        crossinline body: () -> T,
    ): T = if (depth % STACK_SEGMENT != 0 && DeepStacks.isCurrent()) body() else DeepStacks.run { body() }

    /** What a pinned [QueryReads] hands out: each read starts with an empty stack of running queries. */
    private inner class Pinned(
        private val snapshot: Snapshot<E>,
    ) : QueryReads<E> {
        @UntrackedEnvironment
        override val environment: E get() = snapshot.environment

        override val revision: Long get() = snapshot.revision

        override fun <T> read(key: GraphKey<T>): T = fetch(key, Frame(snapshot, RunningQueries(), null))

        override fun ensureCurrent() = ensureCurrent(snapshot.revision)

        override fun readsOf(
            key: Query<E, *>,
            stopAt: (GraphKey<*>) -> Boolean,
        ): Set<GraphKey<*>> = readsOf(key, stopAt, Frame(snapshot, RunningQueries(), null))
    }

    /** One step of a read: the queries running above it, and where the running query records its reads, if it does. */
    private inner class Frame(
        val snapshot: Snapshot<E>,
        val stack: RunningQueries,
        private val recorded: LinkedHashSet<GraphKey<*>>?,
    ) : QueryReads<E> {
        @UntrackedEnvironment
        override val environment: E get() = snapshot.environment

        override val revision: Long get() = snapshot.revision

        val depth: Int get() = stack.size

        override fun <T> read(key: GraphKey<T>): T = fetch(key, this)

        override fun ensureCurrent() = ensureCurrent(snapshot.revision)

        override fun readsOf(
            key: Query<E, *>,
            stopAt: (GraphKey<*>) -> Boolean,
        ): Set<GraphKey<*>> = readsOf(key, stopAt, this)

        fun record(key: GraphKey<*>) {
            recorded?.add(key)
        }

        fun dependencies(): List<GraphKey<*>> = recorded?.toList().orEmpty()

        /** The frame of [query] running on top of this one. */
        fun push(query: Query<E, *>): Frame {
            stack.push(query)
            return Frame(snapshot, stack, LinkedHashSet())
        }

        fun pop() = stack.pop()

        fun withoutRecording(): Frame = Frame(snapshot, stack, null)
    }

    private companion object {
        const val FIRST_REVISION = 1L
        const val NEVER_CHANGED = 0L
        const val STACK_SEGMENT = 32

        fun accessOrdered(memos: Map<GraphKey<*>, Memo>): LinkedHashMap<GraphKey<*>, Memo> =
            LinkedHashMap<GraphKey<*>, Memo>(maxOf(memos.size * 2, 16), 0.75f, true).apply { putAll(memos) }
    }
}

/** A revision and the environment it reads. */
private class Snapshot<E>(
    val revision: Long,
    val environment: E,
)

/** Immutable and stamped with its own revisions, so any memo stays a true statement about the revision it names. */
private data class Memo(
    val value: Any?,
    /** Direct, in read order. */
    val dependencies: List<GraphKey<*>>,
    val inCycle: Boolean,
    val verifiedAt: Long,
    val changedAt: Long,
)

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
