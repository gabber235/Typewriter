package com.typewritermc.extensions.basic.entries.sequence.actions

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.engine.events.testing.ChainRun
import com.typewritermc.formula.Var
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldNotContain

/** A weighted gate goes on through links drawn by their weights, as the legacy weighted random trigger gate did. */
val WeightedRandomTriggerGateEntryTest by testSuite {
    test("a weighted gate never fires a zero weight link") {
        val weights = mapOf("never" to 0, "common" to 5, "rare" to 1)
        val links = weights.map { (step, weight) -> WeightedLink(Ref(ResourceId(step)), weight) }
        val gate = WeightedRandomTriggerGateEntry(Ref(ResourceId("sequence")), "gate", GraphPlacement(), links, Var.Value(3))
        val chains = ChainRun(gate, weights.keys.toList(), Triggered_pickWeightedHandler())

        repeat(50) { chains.run() shouldNotContain "never" }
    }

    test("a weighted gate whose only weighted link sits among zero weights fires that link") {
        val weights = mapOf("first" to 0, "chosen" to 2, "last" to 0)
        val links = weights.map { (step, weight) -> WeightedLink(Ref(ResourceId(step)), weight) }
        val gate = WeightedRandomTriggerGateEntry(Ref(ResourceId("sequence")), "gate", GraphPlacement(), links, Var.Value(1))

        ChainRun(gate, weights.keys.toList(), Triggered_pickWeightedHandler()).run() shouldContainExactly listOf("chosen")
    }

    test("a weighted gate draws with replacement, so one weighted link fires once per draw") {
        val gate =
            WeightedRandomTriggerGateEntry(
                Ref(ResourceId("sequence")),
                "gate",
                GraphPlacement(),
                listOf(WeightedLink(Ref(ResourceId("loot")))),
                Var.Value(3),
            )

        ChainRun(gate, listOf("loot"), Triggered_pickWeightedHandler()).run() shouldContainExactly listOf("loot", "loot", "loot")
    }
}
