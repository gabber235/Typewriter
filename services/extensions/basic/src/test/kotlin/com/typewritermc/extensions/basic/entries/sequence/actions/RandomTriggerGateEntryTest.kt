package com.typewritermc.extensions.basic.entries.sequence.actions

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.engine.events.testing.ChainRun
import com.typewritermc.engine.events.testing.links
import com.typewritermc.formula.Var
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeIn
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.collections.shouldNotContainDuplicates

/** A random gate goes on through a random choice of its links, as the legacy random trigger gate did. */
val RandomTriggerGateEntryTest by testSuite {
    test("a random gate fires exactly amount of its links") {
        val steps = listOf("a", "b", "c", "d")
        val gate = RandomTriggerGateEntry(Ref(ResourceId("sequence")), "gate", GraphPlacement(), links(steps), Var.Value(2))
        val chains = ChainRun(gate, steps, Triggered_pickLinksHandler())

        repeat(20) {
            val reached = chains.run()

            reached shouldHaveSize 2
            reached.shouldNotContainDuplicates()
            reached.forEach { it shouldBeIn steps }
        }
    }

    test("a random gate fires every link once when amount exceeds its links") {
        val steps = listOf("a", "b", "c")
        val gate = RandomTriggerGateEntry(Ref(ResourceId("sequence")), "gate", GraphPlacement(), links(steps), Var.Value(5))

        ChainRun(gate, steps, Triggered_pickLinksHandler()).run() shouldContainExactlyInAnyOrder steps
    }
}
