package com.typewritermc.formula.graph

import com.typewritermc.formula.testing.Cell
import com.typewritermc.formula.testing.Cells
import com.typewritermc.formula.testing.Gate
import com.typewritermc.formula.testing.GraphLog
import com.typewritermc.formula.testing.ProbeFailure
import com.typewritermc.formula.testing.QueryBench
import com.typewritermc.formula.testing.cells
import com.typewritermc.formula.testing.change
import com.typewritermc.formula.testing.forkWith
import com.typewritermc.formula.testing.freshComputation
import com.typewritermc.formula.testing.onThread
import com.typewritermc.formula.testing.read
import com.typewritermc.formula.testing.readOr
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.matchers.types.shouldBeSameInstanceAs

val TrackedGraphTest by testSuite {
    test("a query computes from an input") {
        val bench = QueryBench()
        val doubled = bench.query("doubled") { (read(Cell("a")) ?: 0) * 2 }
        TrackedGraph(cells("a" to 21)).read(doubled) shouldBe 42
    }

    test("a second read at one revision does not rerun") {
        val bench = QueryBench()
        val onA = bench.query("onA") { read(Cell("a")) }
        val graph = TrackedGraph(cells("a" to 1))
        graph.read(onA)
        graph.read(onA) shouldBe 1
        bench.runs(onA) shouldBe 1
    }

    test("changing an input reruns its readers and no one else") {
        val bench = QueryBench()
        val onA = bench.query("onA") { read(Cell("a")) }
        val onB = bench.query("onB") { read(Cell("b")) }
        val graph = TrackedGraph(cells("a" to 1, "b" to 1))
        graph.read(onA)
        graph.read(onB)
        graph.change("a" to 2)
        graph.read(onA) shouldBe 2
        graph.read(onB) shouldBe 1
        bench.runs(onA) shouldBe 2
        bench.runs(onB) shouldBe 1
    }

    test("setting an input to an equal value reruns nothing") {
        val bench = QueryBench()
        val onA = bench.query("onA") { read(Cell("a")) }
        val graph = TrackedGraph(cells("a" to 1))
        graph.read(onA)
        graph.change("a" to 1)
        graph.read(onA) shouldBe 1
        bench.runs(onA) shouldBe 1
    }

    test("a rerun with an equal result stops propagation") {
        val bench = QueryBench()
        val parity = bench.query("parity") { (read(Cell("a")) ?: 0) % 2 }
        val topParity = bench.query("topParity") { if (read(parity) == 0) "even" else "odd" }
        val graph = TrackedGraph(cells("a" to 2))
        graph.read(topParity)
        graph.change("a" to 4)
        graph.read(topParity) shouldBe "even"
        bench.runs(parity) shouldBe 2
        bench.runs(topParity) shouldBe 1
    }

    test("a query that stopped reading an input no longer reruns on it") {
        val bench = QueryBench()
        val chosen = bench.query("chosen") { if (read(Cell("useA")) == 1) read(Cell("a")) else read(Cell("b")) }
        val graph = TrackedGraph(cells("useA" to 1, "a" to 1, "b" to 2))
        graph.read(chosen)
        graph.change("useA" to 0)
        graph.read(chosen) shouldBe 2
        graph.change("a" to 5)
        graph.read(chosen) shouldBe 2
        bench.runs(chosen) shouldBe 2
    }

    test("a reader of a missing input reruns when it appears") {
        val bench = QueryBench()
        val onC = bench.query("onC") { read(Cell("c")) ?: 0 }
        val graph = TrackedGraph(cells())
        graph.read(onC) shouldBe 0
        graph.change("c" to 3)
        graph.read(onC) shouldBe 3
    }

    test("a pinned read throws once a newer revision exists") {
        val bench = QueryBench()
        val onA = bench.query("onA") { read(Cell("a")) }
        val graph = TrackedGraph(cells("a" to 1))
        val pinned = graph.pin()
        graph.change("a" to 2)
        shouldThrow<StaleRevision> { pinned.read(onA) }
        shouldThrow<StaleRevision> { pinned.read(Cell("a")) }
    }

    test("a run overtaken by a new revision leaves no result behind") {
        val bench = QueryBench()
        val gate = Gate()
        lateinit var held: Query<Cells, Int>
        held =
            bench.query("held") {
                val value = read(Cell("a")) ?: 0
                if (bench.runs(held) == 1) gate.hold()
                value
            }
        val graph = TrackedGraph(cells("a" to 1))
        var outcome: Result<Int>? = null
        val reader = Thread { outcome = runCatching { graph.read(held) } }
        reader.start()
        gate.awaitHeld()
        graph.change("a" to 2)
        graph.read(held) shouldBe 2
        gate.open()
        reader.join()
        checkNotNull(outcome).exceptionOrNull().shouldBeInstanceOf<StaleRevision>()
        graph.read(held) shouldBe 2
        bench.runs(held) shouldBe 2
    }

    test("a throwing query is not memoized, and the next read tries again") {
        val bench = QueryBench()
        var attempts = 0
        val flaky =
            bench.query("flaky") {
                attempts += 1
                if (attempts == 1) throw ProbeFailure() else 1
            }
        val graph = TrackedGraph(cells())
        shouldThrow<ProbeFailure> { graph.read(flaky) }
        graph.read(flaky) shouldBe 1
    }

    test("a caller that catches a read's failure reruns once that read succeeds") {
        val bench = QueryBench()
        val failing = bench.query("failing") { if ((read(Cell("a")) ?: 0) == 0) throw ProbeFailure() else 1 }
        val caller = bench.query("caller") { if (readOr(failing, fallback = -1) == -1) "failed" else "ok" }
        val graph = TrackedGraph(cells("a" to 0))
        graph.read(caller) shouldBe "failed"
        graph.change("a" to 1)
        graph.read(caller) shouldBe "ok"
    }

    test("a caller that caught a read's failure reruns when that read returns to its earlier value") {
        val bench = QueryBench()
        val failing = bench.query("failing") { if ((read(Cell("a")) ?: 0) >= 2) throw ProbeFailure() else 1 }
        val caller = bench.query("caller") { readOr(failing, fallback = -1) }
        val graph = TrackedGraph(cells("a" to 0))
        graph.read(caller) shouldBe 1
        graph.change("a" to 2)
        graph.read(caller) shouldBe -1
        graph.change("a" to 0)
        graph.read(caller) shouldBe 1
    }

    test("a caller that catches a read's failure keeps its answer stable while the failure stays") {
        val bench = QueryBench()
        val failing = bench.query("failing") { if ((read(Cell("a")) ?: 0) <= 0) throw ProbeFailure() else 1 }
        val caller = bench.query("caller") { if (readOr(failing, fallback = -1) == -1) "failed" else "ok" }
        val top = bench.query("top") { read(caller).uppercase() }
        val graph = TrackedGraph(cells("a" to 0))
        graph.read(top) shouldBe "FAILED"
        graph.change("a" to -1)
        graph.read(top) shouldBe "FAILED"
        bench.runs(top) shouldBe 1
    }

    test("a cycle gives each member its recovery value and leaves other queries working") {
        val bench = QueryBench()
        lateinit var second: Query<Cells, Int>
        val first = bench.query("first", recovery = { -1 }) { read(second) + 1 }
        second = bench.query("second", recovery = { -2 }) { read(first) + 1 }
        val reader = bench.query("reader") { read(first) * 10 }
        val other = bench.query("other") { read(Cell("a")) }
        val graph = TrackedGraph(cells("a" to 7))
        graph.read(reader) shouldBe -10
        graph.read(first) shouldBe -1
        graph.read(second) shouldBe -2
        graph.read(other) shouldBe 7
    }

    test("breaking a cycle clears the recovery values of every member") {
        val bench = QueryBench()
        lateinit var second: Query<Cells, Int>
        val first = bench.query("first", recovery = { -1 }) { read(second) + 1 }
        second =
            bench.query("second", recovery = { -2 }) {
                if (read(Cell("loop")) == 1) read(first) + 1 else read(Cell("a")) ?: 0
            }
        val graph = TrackedGraph(cells("loop" to 1, "a" to 5))
        graph.read(first) shouldBe -1
        graph.read(second) shouldBe -2
        graph.change("loop" to 0)
        graph.read(first) shouldBe 6
        graph.read(second) shouldBe 5
    }

    test("a cycle kept across many advances stays stable") {
        val bench = QueryBench()
        lateinit var second: Query<Cells, Int>
        val first = bench.query("first", recovery = { -1 }) { read(second) + (read(Cell("a")) ?: 0) }
        second = bench.query("second", recovery = { -2 }) { read(first) + 1 }
        val graph = TrackedGraph(cells("a" to 0))
        repeat(50) { step ->
            graph.change("a" to step % 3, "unrelated" to step)
            graph.read(second) shouldBe -2
            graph.read(first) shouldBe -1
        }
    }

    test("a dependency that turns into a cycle during verification recovers") {
        val bench = QueryBench()
        lateinit var first: Query<Cells, Int>
        val second =
            bench.query("second", recovery = { -2 }) { if (read(Cell("loop")) == 1) read(first) + 1 else 0 }
        first = bench.query("first", recovery = { -1 }) { read(second) + 1 }
        val graph = TrackedGraph(cells("loop" to 0))
        graph.read(first) shouldBe 1
        graph.change("loop" to 1)
        graph.read(first) shouldBe -1
        graph.read(second) shouldBe -2
    }

    test("a cycle without a recovery value throws a cycle naming its members") {
        val bench = QueryBench()
        lateinit var second: Query<Cells, Int>
        val first = bench.query("first") { read(second) }
        second = bench.query("second") { read(first) }
        val reader = bench.query("reader") { read(first) }
        val cycle = shouldThrow<QueryCycle> { TrackedGraph(cells()).read(reader) }
        cycle.members shouldContainExactlyInAnyOrder listOf(first, second)
    }

    test("readsOf includes reads made through a memo hit") {
        val bench = QueryBench()
        val inner = bench.query("inner") { read(Cell("a")) }
        val outer = bench.query("outer") { (read(inner) ?: 0) + (read(Cell("b")) ?: 0) }
        val graph = TrackedGraph(cells("a" to 1, "b" to 2))
        graph.read(inner)
        graph.pin().readsOf(outer) shouldBe setOf(inner, Cell("a"), Cell("b"))
    }

    test("readsOf does not enter a key its stop rule names") {
        val bench = QueryBench()
        val inner = bench.query("inner") { read(Cell("a")) }
        val outer = bench.query("outer") { (read(inner) ?: 0) + (read(Cell("b")) ?: 0) }
        val graph = TrackedGraph(cells("a" to 1, "b" to 2))
        graph.pin().readsOf(outer, stopAt = { it == inner }) shouldBe setOf(inner, Cell("b"))
    }

    test("readsOf reports the current reads of a query below a parent that did not rerun") {
        val bench = QueryBench()
        val child = bench.query("child") { if (read(Cell("useA")) == 1) read(Cell("a")) else read(Cell("b")) }
        val parent = bench.query("parent") { read(child) }
        val graph = TrackedGraph(cells("useA" to 1, "a" to 5, "b" to 5))
        graph.read(parent)
        graph.change("useA" to 0)
        graph.pin().readsOf(parent) shouldBe setOf(child, Cell("useA"), Cell("b"))
        bench.runs(parent) shouldBe 1
    }

    test("the listener sees an equal rerun as a computation") {
        val bench = QueryBench()
        val parity = bench.query("parity") { (read(Cell("a")) ?: 0) % 2 }
        val log = GraphLog()
        val graph = TrackedGraph(cells("a" to 2), listener = log)
        graph.read(parity)
        graph.change("a" to 4)
        graph.read(parity) shouldBe 0
        log.computed shouldBe listOf(parity, parity)
    }

    test("a run overtaken by a new revision and then an undo leaves no wrong answer") {
        val bench = QueryBench()
        val gate = Gate()
        lateinit var child: Query<Cells, Int>
        child =
            bench.query("child") {
                val value = (read(Cell("a")) ?: 0) % 2
                if (bench.runs(child) == 1) gate.hold()
                value
            }
        val parent = bench.query("parent") { read(child) * 100 }
        val graph = TrackedGraph(cells("a" to 1))
        var overtaken: Result<Int>? = null
        val reader = Thread { overtaken = runCatching { graph.read(parent) } }
        reader.start()
        gate.awaitHeld()
        graph.change("a" to 2)
        graph.read(parent) shouldBe 0
        graph.change("a" to 1)
        gate.open()
        reader.join()
        checkNotNull(overtaken).exceptionOrNull().shouldBeInstanceOf<StaleRevision>()
        graph.read(parent) shouldBe freshComputation(cells("a" to 1), parent)
    }

    test("a chain of 10,000 queries computes, and gives the same answer from a cold and a warm graph") {
        val chain = QueryBench().chain(10_000, Cell("a"))
        TrackedGraph(cells("a" to 1)).read(chain.last()) shouldBe 10_000

        val warm = TrackedGraph(cells("a" to 1))
        warm.read(chain[5_000]) shouldBe 5_001
        warm.read(chain.last()) shouldBe 10_000
        warm.change("a" to 2)
        warm.read(chain.last()) shouldBe 10_001
        warm.change("unrelated" to 1)
        warm.read(chain.last()) shouldBe 10_001
    }

    test("a query's own failure crosses a fresh stack unchanged, and so does a stale revision") {
        val bench = QueryBench()
        val failure = ProbeFailure("deep failure")
        val failing = bench.chain(1_000, Cell("a")) { level -> if (level == 0) throw failure }
        val thrown = shouldThrow<ProbeFailure> { TrackedGraph(cells()).read(failing.last()) }
        thrown shouldBeSameInstanceAs failure

        lateinit var graph: TrackedGraph<Cells>
        val overtaking = QueryBench().chain(1_000, Cell("a")) { level -> if (level == 0) graph.change("a" to 9) }
        graph = TrackedGraph(cells())
        shouldThrow<StaleRevision> { graph.read(overtaking.last()) }
    }

    test("a read started on a thread outside the pool still has the full depth") {
        // Each level spends a large share of the caller's small stack, so the chain only completes when no level
        // runs on the caller's thread.
        fun spend(frames: Int): Int = if (frames == 0) 0 else 1 + spend(frames - 1)
        val chain = QueryBench().chain(200, Cell("a")) { spend(4_000) }
        val outcome = onThread(stackBytes = 256L * 1024) { TrackedGraph(cells("a" to 1)).read(chain.last()) }
        outcome.getOrThrow() shouldBe 200
    }

    test("a fork sees its overlay, and the base does not") {
        val bench = QueryBench()
        val onA = bench.query("onA") { read(Cell("a")) }
        val base = TrackedGraph(cells("a" to 1))
        val forked = base.forkWith("a" to 2)
        forked.read(onA) shouldBe 2
        base.read(onA) shouldBe 1
    }

    test("a fork reuses results that exclude the overlay") {
        val bench = QueryBench()
        val onB = bench.query("onB") { read(Cell("b")) }
        val base = TrackedGraph(cells("a" to 1, "b" to 1))
        base.read(onB)
        base.forkWith("a" to 2).read(onB) shouldBe 1
        bench.runs(onB) shouldBe 1
    }

    test("a fork recomputes results that read the overlay") {
        val bench = QueryBench()
        val onA = bench.query("onA") { (read(Cell("a")) ?: 0) * 10 }
        val base = TrackedGraph(cells("a" to 1))
        base.read(onA)
        base.forkWith("a" to 2).read(onA) shouldBe 20
        bench.runs(onA) shouldBe 2
    }

    test("a fork stops propagation at a rerun with an equal result") {
        val bench = QueryBench()
        val parity = bench.query("parity") { (read(Cell("a")) ?: 0) % 2 }
        val topParity = bench.query("topParity") { if (read(parity) == 0) "even" else "odd" }
        val base = TrackedGraph(cells("a" to 2))
        base.read(topParity)
        base.forkWith("a" to 4).read(topParity) shouldBe "even"
        bench.runs(parity) shouldBe 2
        bench.runs(topParity) shouldBe 1
    }

    test("a fork keeps answering with its own state after the base moves on") {
        val bench = QueryBench()
        val shared = bench.query("shared") { read(Cell("a")) ?: 0 }
        val top = bench.query("top") { read(shared) + 1 }
        val otherReader = bench.query("otherReader") { read(shared) * 10 }
        val base = TrackedGraph(cells("a" to 1))
        base.read(top)
        val forked = base.forkWith("a" to 2)
        forked.read(top) shouldBe 3
        base.change("a" to 3)
        base.read(shared) shouldBe 3
        forked.read(otherReader) shouldBe 20
    }

    test("a fork's results never reach the base") {
        val bench = QueryBench()
        val onA = bench.query("onA") { read(Cell("a")) }
        val fresh = bench.query("fresh") { read(Cell("a")) }
        val base = TrackedGraph(cells("a" to 1))
        base.read(onA)
        val forked = base.forkWith("a" to 2)
        forked.read(onA) shouldBe 2
        forked.read(fresh) shouldBe 2
        base.read(onA) shouldBe 1
        base.read(fresh) shouldBe 1
        base.change("b" to 1)
        base.read(onA) shouldBe 1
        base.read(fresh) shouldBe 1
    }

    test("evicting a memo costs a rerun and never a wrong value") {
        val bench = QueryBench()
        val onA = bench.query("onA") { read(Cell("a")) ?: 0 }
        val top = bench.query("top") { read(onA) + 1 }
        val others = List(3) { index -> bench.query("other$index") { read(Cell("b")) ?: index } }
        val log = GraphLog()
        val graph = TrackedGraph(cells("a" to 1), GraphLimits(maxMemos = 2), log)
        graph.read(top) shouldBe 2
        others.forEach { graph.read(it) }
        graph.change("a" to 5)
        graph.read(top) shouldBe 6
        graph.read(onA) shouldBe 5
        bench.runs(onA) shouldBe 2
        log.evicted shouldContain onA
    }

    test("reset forgets every memo") {
        val bench = QueryBench()
        val onA = bench.query("onA") { read(Cell("a")) }
        val graph = TrackedGraph(cells("a" to 1))
        graph.read(onA)
        graph.reset(cells("a" to 1))
        graph.read(onA) shouldBe 1
        bench.runs(onA) shouldBe 2
    }
}
