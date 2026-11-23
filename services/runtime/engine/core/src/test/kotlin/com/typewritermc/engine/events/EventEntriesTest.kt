package com.typewritermc.engine.events

import com.typewritermc.engine.events.testing.EventHarness
import com.typewritermc.engine.events.testing.Poke
import com.typewritermc.engine.events.testing.StepEntry
import com.typewritermc.engine.events.testing.TestSource
import com.typewritermc.engine.events.testing.after
import com.typewritermc.engine.events.testing.cancelableEntry
import com.typewritermc.engine.events.testing.eventEntry
import com.typewritermc.engine.events.testing.step
import com.typewritermc.events.Outcome
import com.typewritermc.events.Param
import com.typewritermc.events.TriggeredEvent
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

/** The entries every engine ships: an event entry starts a chain, a cancelable event entry also decides the event. */
val EventEntriesTest by testSuite {
    test("an event entry starts its chain only while its condition holds") {
        val pokes = TestSource(Poke::class)
        val reached = mutableListOf<String>()
        val events =
            EventHarness(
                pokes,
                Event_startHandler(),
                after(TriggeredEvent::class, Param.Triggered(StepEntry::class)) { triggered, _ -> reached += triggered.entry.name },
            )
        events.publish(eventEntry<Poke>("on poke", next = listOf("reward"), condition = false), step("reward"))
        pokes.fire(Poke())
        events.tick()
        reached shouldBe emptyList()

        events.publish(eventEntry<Poke>("on poke", next = listOf("reward"), condition = true), step("reward"))
        pokes.fire(Poke())
        events.tick()
        reached shouldContainExactly listOf("reward")
    }

    test("a cancelable event entry denies its event while cancel holds and starts its chain either way") {
        val pokes = TestSource(Poke::class)
        val reached = mutableListOf<String>()
        val events =
            EventHarness(
                pokes,
                CancelableEvent_ruleHandler(),
                after(TriggeredEvent::class, Param.Triggered(StepEntry::class)) { triggered, _ -> reached += triggered.entry.name },
            )
        events.publish(cancelableEntry<Poke>("guard", next = listOf("warning"), cancel = true), step("warning"))
        pokes.fire(Poke()).shouldBeInstanceOf<Outcome.Denied<Poke>>()
        events.tick()

        events.publish(cancelableEntry<Poke>("guard", next = listOf("warning"), cancel = false), step("warning"))
        pokes.fire(Poke()) shouldBe Outcome.Allowed(Poke())
        events.tick()
        reached shouldContainExactly listOf("warning", "warning")
    }

    test("a cancelable event entry whose condition fails neither decides nor starts its chain") {
        val pokes = TestSource(Poke::class)
        val reached = mutableListOf<String>()
        val events =
            EventHarness(
                pokes,
                CancelableEvent_ruleHandler(),
                after(TriggeredEvent::class, Param.Triggered(StepEntry::class)) { triggered, _ -> reached += triggered.entry.name },
            )
        events.publish(cancelableEntry<Poke>("guard", next = listOf("warning"), condition = false, cancel = true), step("warning"))
        pokes.fire(Poke()) shouldBe Outcome.Allowed(Poke())
        events.tick()
        reached shouldBe emptyList()
    }
}
