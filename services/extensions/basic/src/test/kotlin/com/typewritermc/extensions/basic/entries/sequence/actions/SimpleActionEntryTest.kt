package com.typewritermc.extensions.basic.entries.sequence.actions

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.engine.events.testing.ChainRun
import com.typewritermc.engine.events.testing.links
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder

/** A simple action does nothing of its own and goes on through its links. */
val SimpleActionEntryTest by testSuite {
    test("a simple action fires all its links") {
        val steps = listOf("a", "b", "c")
        val action = SimpleActionEntry(Ref(ResourceId("sequence")), "action", GraphPlacement(), links(steps))

        ChainRun(action, steps, Triggered_proceedHandler()).run() shouldContainExactlyInAnyOrder steps
    }
}
