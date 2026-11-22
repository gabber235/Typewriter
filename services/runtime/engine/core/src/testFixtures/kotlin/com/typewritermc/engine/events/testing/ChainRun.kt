package com.typewritermc.engine.events.testing

import com.typewritermc.elements.Entry
import com.typewritermc.events.EnginePart
import com.typewritermc.events.Param
import com.typewritermc.events.TriggeredEvent

/**
 * Chains that start at [entry], an extension's action, with its `Var` fields read as written: each [run] triggers it
 * for a protagonist and returns the names of the [steps] the chain reached, in order. [parts] are the handlers under
 * test, such as the entry's generated handler plan.
 */
class ChainRun(
    entry: Entry,
    steps: List<String>,
    vararg parts: EnginePart,
) {
    private val pokes = TestSource(Poke::class)
    private val reached = mutableListOf<String>()
    private val events =
        EventHarness(
            pokes,
            *parts,
            pokeTriggers(entry),
            after(TriggeredEvent::class, Param.Triggered(StepEntry::class)) { triggered, _ -> reached += triggered.entry.name },
        )

    init {
        events.publish(written(published(entry), *steps.map { step(it) }.toTypedArray()))
    }

    /** Triggers the entry once and returns the steps this chain reached. */
    suspend fun run(): List<String> {
        reached.clear()
        pokes.fire(Poke())
        events.tick()
        return reached.toList()
    }
}
