package com.typewritermc.engine.events

import com.typewritermc.engine.events.testing.EventHarness
import com.typewritermc.engine.events.testing.Poke
import com.typewritermc.engine.events.testing.StepEntry
import com.typewritermc.engine.events.testing.TestSource
import com.typewritermc.engine.events.testing.after
import com.typewritermc.engine.events.testing.links
import com.typewritermc.engine.events.testing.protagonist
import com.typewritermc.engine.events.testing.published
import com.typewritermc.engine.events.testing.step
import com.typewritermc.events.Context
import com.typewritermc.events.Triggered
import com.typewritermc.events.emit
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
                after(Poke::class) { poke, _ -> emit(Triggered(gate.entry, poke.protagonist, Context.EMPTY)) },
                after(Triggered::class, entry = StepEntry::class) { triggered, _ ->
                    reached += triggered.entry.name
                    val entry = triggered.entry as StepEntry
                    entry.triggers.filter { it.target.value != "passed over" }.fire(triggered.context, triggered.subject)
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
                after(Triggered::class, entry = StepEntry::class) { triggered, _ -> reached += triggered.entry.name },
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
                after(Triggered::class, entry = StepEntry::class) { triggered, _ -> reached += triggered.entry.name },
            )
        events.publish(step("reward"))

        repeat(3) { pokes.fire(Poke()) }
        events.tick()

        reached shouldContainExactly listOf("reward")
    }
}
