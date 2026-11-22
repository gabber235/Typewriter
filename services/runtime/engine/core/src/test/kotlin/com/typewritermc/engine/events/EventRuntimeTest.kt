package com.typewritermc.engine.events

import com.typewritermc.engine.events.testing.EventHarness
import com.typewritermc.engine.events.testing.GuardEntry
import com.typewritermc.engine.events.testing.Poke
import com.typewritermc.engine.events.testing.Shove
import com.typewritermc.engine.events.testing.StepEntry
import com.typewritermc.engine.events.testing.TestFields
import com.typewritermc.engine.events.testing.TestSource
import com.typewritermc.engine.events.testing.after
import com.typewritermc.engine.events.testing.protagonist
import com.typewritermc.engine.events.testing.published
import com.typewritermc.engine.events.testing.reason
import com.typewritermc.engine.events.testing.step
import com.typewritermc.engine.events.testing.verdict
import com.typewritermc.events.CancelableEvent
import com.typewritermc.events.Candidate
import com.typewritermc.events.Outcome
import com.typewritermc.events.Param
import com.typewritermc.events.Triggered
import com.typewritermc.events.allow
import com.typewritermc.events.deny
import com.typewritermc.events.emit
import com.typewritermc.events.pass
import com.typewritermc.identity.Protagonist
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.comparables.shouldBeGreaterThanOrEqualTo
import io.kotest.matchers.shouldBe

/** How the engine runs handlers for each occurrence a source reports, and how chains queue and end. */
val EventRuntimeTest by testSuite {
    test("a verdict handler that throws counts as a pass") {
        val pokes = TestSource(Poke::class)
        EventHarness(
            pokes,
            verdict(Poke::class) { _, _ -> error("broken rule") },
            verdict(Poke::class) { _, _ -> deny(reason("guarded")) },
        )
        pokes.fire(Poke()) shouldBe Outcome.Denied(Poke(), reason("guarded"))
    }

    test("after handlers see only allowed occurrences, unless they ask for the outcome") {
        val pokes = TestSource(Poke::class)
        val seen = mutableListOf<String>()
        val events =
            EventHarness(
                pokes,
                verdict(Poke::class) { poke, _ -> if (poke.strength > 1) deny(reason("too hard")) else allow() },
                after(Poke::class) { poke, _ -> seen += "allowed ${poke.strength}" },
                after(Poke::class, Param.Outcome) { _, values -> seen += "outcome ${(values.single() as Outcome<*>)::class.simpleName}" },
            )
        pokes.fire(Poke(strength = 1))
        pokes.fire(Poke(strength = 2))
        events.tick()
        seen shouldContainExactly listOf("allowed 1", "outcome Allowed", "outcome Denied")
    }

    test("a handler whose required parameter cannot be resolved does not run, an optional one runs with null") {
        val pokes = TestSource(Poke::class)
        val seen = mutableListOf<Any?>()
        val events =
            EventHarness(
                pokes,
                after(Poke::class, Param.Origin()) { _, values -> seen.addAll(values) },
                after(Poke::class, Param.Origin(optional = true), Param.Identity(Protagonist::class)) { _, values -> seen.addAll(values) },
            )
        pokes.fire(Poke(protagonist("sam")))
        events.tick()
        seen shouldContainExactly listOf(null, protagonist("sam"))
    }

    test("a rule entry decides only on the event it is about, with its page priority") {
        val pokes = TestSource(Poke::class)
        val events =
            EventHarness(
                pokes,
                verdict(CancelableEvent::class, Param.Candidate(GuardEntry::class, ofEvent = true)) { _, values ->
                    val guard = values.single() as Candidate<GuardEntry<*>>
                    if (guard.read(TestFields.cancel)) deny(reason(guard.entry.name)) else pass()
                },
                verdict(Poke::class) { _, _ -> allow() },
            )
        events.publish(published(GuardEntry<Shove>("about shoves"), about = Shove::class, priority = 5))
        pokes.fire(Poke()) shouldBe Outcome.Allowed(Poke())
        events.publish(published(GuardEntry<Poke>("about pokes"), about = Poke::class, priority = 5))
        pokes.fire(Poke()) shouldBe Outcome.Denied(Poke(), reason("about pokes"))
    }

    test("an entry whose book does not apply to the subject takes no part") {
        val pokes = TestSource(Poke::class)
        val events =
            EventHarness(
                pokes,
                verdict(CancelableEvent::class, Param.Candidate(GuardEntry::class, ofEvent = true)) { _, _ -> deny(reason("guarded")) },
            )
        events.publish(published(GuardEntry<Poke>(), about = Poke::class, appliesTo = { it == protagonist("sam") }))
        pokes.fire(Poke(protagonist("alex"))) shouldBe Outcome.Allowed(Poke(protagonist("alex")))
        pokes.fire(Poke(protagonist("sam"))) shouldBe Outcome.Denied(Poke(protagonist("sam")), reason("guarded"))
    }

    test("a source is open while a handler could run for its events, across republishes") {
        val pokes = TestSource(Poke::class)
        val events =
            EventHarness(
                pokes,
                verdict(CancelableEvent::class, Param.Candidate(GuardEntry::class, ofEvent = true)) { _, _ -> deny(reason("guarded")) },
            )
        pokes.open shouldBe false
        events.publish(published(GuardEntry<Poke>(), about = Poke::class))
        pokes.open shouldBe true
        events.publish(published(GuardEntry<Poke>("renamed"), about = Poke::class))
        pokes.opens shouldBe 1
        events.publish()
        pokes.open shouldBe false
    }

    test("a chain runs from entry to entry and identical starts within one tick run once") {
        val pokes = TestSource(Poke::class)
        val sent = mutableListOf<String>()
        val first = step("first", next = listOf("second"))
        val events =
            EventHarness(
                pokes,
                after(
                    Poke::class,
                ) { poke, _ -> repeat(2) { emit(Triggered(first.entry, poke.protagonist, com.typewritermc.events.Context.EMPTY)) } },
                after(Triggered::class, Param.Field(TestFields.message), entry = StepEntry::class) { triggered, values ->
                    sent += values.single() as String
                    (triggered as Triggered<StepEntry>).complete()
                },
            )
        events.publish(first, step("second"))
        pokes.fire(Poke())
        events.tick()
        sent shouldContainExactly listOf("first", "second")
    }

    test("a protagonist is busy from the moment a chain is queued until it ends, and a wipe drops its queued chains") {
        val pokes = TestSource(Poke::class)
        val sent = mutableListOf<String>()
        val first = step("first", next = listOf("second"))
        val events =
            EventHarness(
                pokes,
                after(Poke::class) { poke, _ -> emit(Triggered(first.entry, poke.protagonist, com.typewritermc.events.Context.EMPTY)) },
                after(Triggered::class, Param.Field(TestFields.message), entry = StepEntry::class) { triggered, values ->
                    sent += values.single() as String
                    (triggered as Triggered<StepEntry>).complete()
                },
            )
        events.publish(first, step("second"))
        pokes.fire(Poke(protagonist("alex")))
        pokes.fire(Poke(protagonist("sam")))
        events.work.busy(protagonist("alex")) shouldBe 1
        events.wipe(protagonist("sam"))
        events.work.busy(protagonist("sam")) shouldBe 0
        events.tick()
        sent shouldContainExactly listOf("first", "second")
        events.work
            .history(protagonist("alex"))
            .dropLast(1)
            .contains(0) shouldBe false
        events.work.busy(protagonist("alex")) shouldBe 0
    }

    test("every handler run's time is recorded in the engine's handler duration histogram, per event") {
        val pokes = TestSource(Poke::class)
        val events = EventHarness(pokes, after(Poke::class) { _, _ -> Thread.sleep(2) }, verdict(Poke::class) { _, _ -> pass() })

        repeat(3) { pokes.fire(Poke()) }
        events.tick()
        val recorded = events.telemetry.histograms("typewriter.event.handler.duration", "typewriter.event").getValue("Poke")
        recorded.count shouldBe 6
        recorded.sum shouldBeGreaterThanOrEqualTo 0.006
    }
}
