package com.typewritermc.formula.testing

import com.typewritermc.formula.graph.GraphKey
import com.typewritermc.formula.graph.GraphListener
import com.typewritermc.formula.graph.InputKey
import com.typewritermc.formula.graph.Query
import com.typewritermc.formula.graph.QueryReads
import com.typewritermc.formula.graph.TrackedGraph
import com.typewritermc.formula.graph.UntrackedEnvironment
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlin.random.Random

/** The environment of graph tests: named integer cells. A name that is absent reads as null. */
typealias Cells = Map<String, Int>

/** An input of the graph: one named cell. */
data class Cell(
    val name: String,
) : InputKey<Cells, Int?> {
    override fun read(environment: Cells): Int? = environment[name]
}

/** A query's own failure, as a provider would throw it. */
class ProbeFailure(
    message: String = "probe failed",
) : RuntimeException(message)

/**
 * Builds queries that count their own runs, so a test observes a rerun from outside the graph. Two queries of one
 * bench with the same name are the same key.
 */
class QueryBench {
    private val runs = ConcurrentHashMap<String, AtomicInteger>()

    fun <T> query(
        name: String,
        recovery: ((List<GraphKey<*>>) -> T)? = null,
        body: QueryReads<Cells>.() -> T,
    ): Query<Cells, T> = Probe(name, this, recovery, body)

    /** How often [query] ran its compute, in every graph and fork that read it. */
    fun runs(query: Query<Cells, *>): Int = runs[(query as Probe<*>).name]?.get() ?: 0

    /**
     * Queries `chain-0` to `chain-<length - 1>`: the first reads [bottom] (absent reads 0), each next one adds 1 to the
     * one before it. [step] runs inside each query before its read, so a test can give every level a cost of its own.
     */
    fun chain(
        length: Int,
        bottom: Cell,
        step: (Int) -> Unit = {},
    ): List<Query<Cells, Int>> {
        val chain = ArrayList<Query<Cells, Int>>(length)
        repeat(length) { level ->
            val below = chain.lastOrNull()
            chain +=
                query("chain-$level") {
                    step(level)
                    if (below == null) read(bottom) ?: 0 else read(below) + 1
                }
        }
        return chain
    }

    private class Probe<T>(
        val name: String,
        private val bench: QueryBench,
        private val recovery: ((List<GraphKey<*>>) -> T)?,
        private val body: QueryReads<Cells>.() -> T,
    ) : Query<Cells, T> {
        context(reads: QueryReads<Cells>)
        override fun compute(): T {
            bench.runs.computeIfAbsent(name) { AtomicInteger() }.incrementAndGet()
            return reads.body()
        }

        override fun onCycle(members: List<GraphKey<*>>): T = recovery?.invoke(members) ?: super.onCycle(members)

        override fun equals(other: Any?): Boolean = other is Probe<*> && other.name == name && other.bench === bench

        override fun hashCode(): Int = name.hashCode()

        override fun toString(): String = name
    }
}

/**
 * Reads [key], answering [fallback] when it fails with a [ProbeFailure], as the interpreter answers a provider's
 * failure. Graph control flow passes through.
 */
fun <T> QueryReads<Cells>.readOr(
    key: GraphKey<T>,
    fallback: T,
): T = runCatching { read(key) }.getOrElse { failure -> if (failure is ProbeFailure) fallback else throw failure }

fun cells(vararg values: Pair<String, Int>): Cells = mapOf(*values)

/** Reads [key] at the graph's current revision. */
fun <E, T> TrackedGraph<E>.read(key: GraphKey<T>): T = pin().read(key)

/** The cells the graph is at now. */
@OptIn(UntrackedEnvironment::class)
val TrackedGraph<Cells>.cells: Cells get() = pin().environment

/** Advances to the current cells with [values] applied; a null value removes the cell. */
fun TrackedGraph<Cells>.change(vararg values: Pair<String, Int?>) {
    advance(cells.with(*values), values.map { Cell(it.first) }.toSet())
}

/** A fork at the current cells with [values] applied as its overlay. */
fun TrackedGraph<Cells>.forkWith(vararg values: Pair<String, Int?>): TrackedGraph<Cells> =
    fork(cells.with(*values), values.map { Cell(it.first) }.toSet())

/** What [key] is at [environment], computed by a graph that has never seen anything else. */
fun <T> freshComputation(
    environment: Cells,
    key: GraphKey<T>,
): T = TrackedGraph(environment).read(key)

private fun Cells.with(vararg values: Pair<String, Int?>): Cells =
    toMutableMap().apply {
        values.forEach { (name, value) -> if (value == null) remove(name) else put(name, value) }
    }

/** Records what a graph reports, in order. */
class GraphLog : GraphListener {
    val computed: MutableList<GraphKey<*>> = CopyOnWriteArrayList()
    val evicted: MutableList<GraphKey<*>> = CopyOnWriteArrayList()

    override fun computed(key: GraphKey<*>) {
        computed += key
    }

    override fun evicted(key: GraphKey<*>) {
        evicted += key
    }
}

/**
 * Holds one thread at a point until the test opens it, so a test can change the graph while a run is in flight. Every
 * wait gives up after ten seconds, so a broken graph fails the test instead of hanging it.
 */
class Gate {
    private val reached = CountDownLatch(1)
    private val opened = CountDownLatch(1)

    /** Called by the held thread: marks the point as reached and waits until the gate opens. */
    fun hold() {
        reached.countDown()
        check(opened.await(WAIT_SECONDS, TimeUnit.SECONDS)) { "The gate was never opened" }
    }

    fun awaitHeld() {
        check(reached.await(WAIT_SECONDS, TimeUnit.SECONDS)) { "No thread reached the gate" }
    }

    fun open() {
        opened.countDown()
    }

    private companion object {
        const val WAIT_SECONDS = 10L
    }
}

/** Runs [body] on a new thread with [stackBytes] of stack and returns its outcome, failures included. */
fun <T> onThread(
    stackBytes: Long = 0,
    body: () -> T,
): Result<T> {
    var outcome: Result<T>? = null
    val thread = Thread(null, { outcome = runCatching(body) }, "graph-test", stackBytes)
    thread.start()
    thread.join(TimeUnit.MINUTES.toMillis(1))
    check(!thread.isAlive) { "The thread did not finish within a minute" }
    return checkNotNull(outcome)
}

/**
 * A generated graph for properties: [queryCount] queries over [cellCount] cells. A query adds up what it reads: cells,
 * any query (so cycles come and go), reads that only happen while a cell is high, failures while a cell is high, and
 * reads of a query whose failure it catches. A cycle member recovers with a value of its own.
 */
class GeneratedGraph(
    random: Random,
    queryCount: Int = 8,
    cellCount: Int = 4,
) {
    private val bench = QueryBench()
    private val names = List(cellCount) { "c$it" }

    val queries: List<Query<Cells, Int>>

    init {
        val built = ArrayList<Query<Cells, Int>>(queryCount)
        val plans = List(queryCount) { index -> List(random.nextInt(1, 4)) { step(random, index, queryCount) } }
        plans.forEachIndexed { index, steps ->
            built +=
                bench.query("q$index", recovery = { -1_000 - index }) {
                    steps.sumOf { step -> step.run(this, built) }
                }
        }
        queries = built
    }

    /** Cells with random values, some of them absent. */
    fun cells(random: Random): Cells = names.filter { random.nextInt(4) != 0 }.associateWith { random.nextInt(4) }

    /** One to three random changes, some of them removing a cell. */
    fun changes(random: Random): List<Pair<String, Int?>> =
        List(random.nextInt(1, 4)) { names.random(random) to random.nextInt(-1, 4).takeIf { it >= 0 } }

    /** What each query gives at the graph's revision, a failure as its class. */
    fun outcomes(graph: TrackedGraph<Cells>): List<Any?> =
        queries.map { query -> runCatching { graph.read(query) }.fold({ it }, { it::class }) }

    private fun step(
        random: Random,
        index: Int,
        queryCount: Int,
    ): Step {
        val cell = Cell(names.random(random))
        // Mostly lower queries, so most graphs are deep; sometimes any query, which closes cycles.
        val target = if (index > 0 && random.nextInt(3) != 0) random.nextInt(index) else random.nextInt(queryCount)
        return when (random.nextInt(5)) {
            0 -> Step.ReadCell(cell)
            1 -> Step.ReadQuery(target)
            2 -> Step.ReadWhileHigh(cell, target)
            3 -> Step.FailWhileHigh(cell)
            else -> Step.CatchFailure(target)
        }
    }

    private sealed interface Step {
        fun run(
            reads: QueryReads<Cells>,
            queries: List<Query<Cells, Int>>,
        ): Int

        data class ReadCell(
            val cell: Cell,
        ) : Step {
            override fun run(
                reads: QueryReads<Cells>,
                queries: List<Query<Cells, Int>>,
            ): Int = reads.read(cell) ?: 0
        }

        data class ReadQuery(
            val target: Int,
        ) : Step {
            override fun run(
                reads: QueryReads<Cells>,
                queries: List<Query<Cells, Int>>,
            ): Int = reads.read(queries[target])
        }

        data class ReadWhileHigh(
            val cell: Cell,
            val target: Int,
        ) : Step {
            override fun run(
                reads: QueryReads<Cells>,
                queries: List<Query<Cells, Int>>,
            ): Int = if ((reads.read(cell) ?: 0) >= 2) reads.read(queries[target]) else 0
        }

        data class FailWhileHigh(
            val cell: Cell,
        ) : Step {
            override fun run(
                reads: QueryReads<Cells>,
                queries: List<Query<Cells, Int>>,
            ): Int = if ((reads.read(cell) ?: 0) >= 2) throw ProbeFailure() else 1
        }

        data class CatchFailure(
            val target: Int,
        ) : Step {
            override fun run(
                reads: QueryReads<Cells>,
                queries: List<Query<Cells, Int>>,
            ): Int = reads.readOr(queries[target], fallback = -1)
        }
    }
}
