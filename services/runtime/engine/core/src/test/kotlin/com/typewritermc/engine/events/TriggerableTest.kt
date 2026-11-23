package com.typewritermc.engine.events

import com.typewritermc.engine.events.testing.EventHarness
import com.typewritermc.engine.events.testing.Poke
import com.typewritermc.engine.events.testing.StepEntry
import com.typewritermc.engine.events.testing.TestSource
import com.typewritermc.engine.events.testing.after
import com.typewritermc.engine.events.testing.links
import com.typewritermc.engine.events.testing.pokeTriggers
import com.typewritermc.engine.events.testing.protagonist
import com.typewritermc.engine.events.testing.published
import com.typewritermc.engine.events.testing.step
import com.typewritermc.engine.formula.testing.FormulaPublication
import com.typewritermc.engine.formula.testing.Said
import com.typewritermc.engine.formula.testing.book
import com.typewritermc.engine.formula.testing.saidEntry
import com.typewritermc.engine.formula.testing.sequencePage
import com.typewritermc.engine.reading.PublishedValues
import com.typewritermc.engine.reading.testing.LayeredValues
import com.typewritermc.engine.reading.testing.entry
import com.typewritermc.engine.reading.testing.locationOf
import com.typewritermc.events.Context
import com.typewritermc.events.EventContext
import com.typewritermc.events.Param
import com.typewritermc.events.Triggered
import com.typewritermc.events.TriggeredEvent
import com.typewritermc.formula.Var
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly

/** How an entry's links lead a chain on to the entries they point at. */
val TriggerableTest by testSuite {
    test("firing a chosen set of links starts only those entries, skipping one whose book does not apply") {
        val pokes = TestSource(Poke::class)
        val reached = mutableListOf<String>()
        val gate = step("gate", next = listOf("chosen", "passed over", "gated"))
        val events =
            EventHarness(
                pokes,
                pokeTriggers(gate.entry),
                after(TriggeredEvent::class, Param.Triggered(StepEntry::class)) { _, values ->
                    @Suppress("UNCHECKED_CAST")
                    val step = values.single() as Triggered<StepEntry>
                    reached += step.entry.name
                    step.triggers.filter { it.target.value != "passed over" }.fire(step.context, step.subject)
                },
            )
        events.publish(
            gate,
            step("chosen"),
            step("passed over"),
            published(StepEntry("gated"), appliesTo = { it == protagonist("sam") }),
        )

        pokes.fire(Poke(protagonist("alex")))
        events.tick()

        reached shouldContainExactly listOf("gate", "chosen")
    }

    test("firing one link three times in one call starts its entry three times") {
        val pokes = TestSource(Poke::class)
        val reached = mutableListOf<String>()
        val events =
            EventHarness(
                pokes,
                after(Poke::class) { poke, _ ->
                    val reward = links(listOf("reward")).single()
                    listOf(reward, reward, reward).fire(Context.EMPTY, poke.protagonist)
                },
                after(TriggeredEvent::class, Param.Triggered(StepEntry::class)) { triggered, _ -> reached += triggered.entry.name },
            )
        events.publish(step("reward"))

        pokes.fire(Poke())
        events.tick()

        reached shouldContainExactly listOf("reward", "reward", "reward")
    }

    test("three equal fires in one tick still start the entry once") {
        val pokes = TestSource(Poke::class)
        val reached = mutableListOf<String>()
        val events =
            EventHarness(
                pokes,
                after(Poke::class) { poke, _ -> links(listOf("reward")).fire(Context.EMPTY, poke.protagonist) },
                after(TriggeredEvent::class, Param.Triggered(StepEntry::class)) { triggered, _ -> reached += triggered.entry.name },
            )
        events.publish(step("reward"))

        repeat(3) { pokes.fire(Poke()) }
        events.tick()

        reached shouldContainExactly listOf("reward")
    }

    test("an entry fires and completes with the links stored at the seam, not the ones its Kotlin object holds") {
        val said = TestSource(Said::class)
        // Every entry here is an event entry about Said; only the start answers the event itself.
        val never = Var.Value<Boolean, EventContext<Said>>(false)
        val reached = mutableListOf<String>()
        val events =
            EventHarness(
                said,
                Event_startHandler(),
                after(TriggeredEvent::class, Param.Triggered(EventEntry::class)) { _, values ->
                    @Suppress("UNCHECKED_CAST")
                    val step = values.single() as Triggered<EventEntry<*>>
                    reached += step.entry.name
                    step.complete()
                },
            )
        val written =
            FormulaPublication(
                book("open", Var.Value(true)),
                sequencePage("sequence", book = "open"),
                saidEntry("start", next = listOf("written step")),
                saidEntry("written step", never, next = listOf("written end")),
                saidEntry("stored step", never, next = listOf("written end")),
                saidEntry("written end", never),
                saidEntry("stored end", never),
            )
        val stored =
            FormulaPublication(
                saidEntry("start", next = listOf("stored step")),
                saidEntry("stored step", never, next = listOf("stored end")),
            )
        val environment = written.environment()
        val startLinks = environment.locationOf(written.entry("start"), EventEntryFields.triggers)
        val stepLinks = environment.locationOf(written.entry("stored step"), EventEntryFields.triggers)
        val seam =
            LayeredValues(environment.published)
                .with(startLinks, PublishedValues(stored.graph).at(startLinks))
                .with(stepLinks, PublishedValues(stored.graph).at(stepLinks))
        events.publish(written.entries(environment, values = seam))

        said.fire(Said(protagonist("alex"), "hello"))
        events.tick()

        reached shouldContainExactly listOf("stored step", "stored end")
    }
}
