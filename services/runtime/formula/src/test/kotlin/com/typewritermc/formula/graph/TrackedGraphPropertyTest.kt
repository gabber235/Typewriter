package com.typewritermc.formula.graph

import com.typewritermc.formula.testing.Cell
import com.typewritermc.formula.testing.GeneratedGraph
import com.typewritermc.formula.testing.QueryBench
import com.typewritermc.formula.testing.cells
import com.typewritermc.formula.testing.change
import com.typewritermc.formula.testing.forkWith
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.arbitrary.long
import io.kotest.property.checkAll
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread
import kotlin.random.Random

/**
 * The whole contract in one sentence: whatever the graph reused, it answers what a graph that has seen nothing else
 * would answer. The seed is fixed, so every run checks the same graphs; a failure this finds becomes an example in
 * TrackedGraphTest.
 */
val TrackedGraphPropertyTest by testSuite {
    /** Fixed, so every run checks the same cases; change it only on purpose. */
    val config = PropTestConfig(seed = 4_127_660_391L, iterations = 500)

    test("after any sequence of input changes, every query equals a fresh computation") {
        checkAll(config, Arb.long()) { seed ->
            val random = Random(seed)
            val generated = GeneratedGraph(random)
            val graph = TrackedGraph(generated.cells(random))
            generated.outcomes(graph) shouldBe generated.outcomes(TrackedGraph(graph.cells))
            repeat(12) {
                graph.change(*generated.changes(random).toTypedArray())
                generated.outcomes(graph) shouldBe generated.outcomes(TrackedGraph(graph.cells))
            }
        }
    }

    test("after any changes and any overlay, every fork query equals a fresh computation over the fork's environment") {
        checkAll(config, Arb.long()) { seed ->
            val random = Random(seed)
            val generated = GeneratedGraph(random)
            val base = TrackedGraph(generated.cells(random))
            repeat(random.nextInt(4)) {
                generated.outcomes(base)
                base.change(*generated.changes(random).toTypedArray())
            }
            generated.outcomes(base)
            val forked = base.forkWith(*generated.changes(random).toTypedArray())
            if (random.nextBoolean()) {
                base.change(*generated.changes(random).toTypedArray())
                generated.outcomes(base)
            }
            generated.outcomes(forked) shouldBe generated.outcomes(TrackedGraph(forked.cells))
            generated.outcomes(base) shouldBe generated.outcomes(TrackedGraph(base.cells))
        }
    }

    test("reads running on many threads during advances never see a mix of two revisions") {
        // left and right always hold the same value, so every answer of one revision is zero.
        val left = QueryBench().chain(40, Cell("left"))
        val right = QueryBench().chain(40, Cell("right"))
        val difference = QueryBench().query("difference") { read(left.last()) - read(right.last()) }
        val graph = TrackedGraph(cells("left" to 0, "right" to 0))
        val wrong = ConcurrentLinkedQueue<Result<Int>>()
        val advancing = AtomicBoolean(true)
        val readers =
            List(4) {
                thread {
                    while (advancing.get()) {
                        // A read overtaken by an advance gives no answer at all.
                        val outcome = runCatching { graph.pin().read(difference) }
                        if (outcome.getOrNull() != 0 && outcome.exceptionOrNull() !is StaleRevision) wrong += outcome
                    }
                }
            }
        repeat(500) { step -> graph.change("left" to step, "right" to step) }
        advancing.set(false)
        readers.forEach { it.join() }
        wrong.shouldBeEmpty()
    }
}
