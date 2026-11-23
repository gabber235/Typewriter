package com.typewritermc.engine.events

import com.typewritermc.engine.events.testing.Poke
import com.typewritermc.engine.events.testing.reason
import com.typewritermc.events.Outcome
import com.typewritermc.events.PassOn
import com.typewritermc.events.allow
import com.typewritermc.events.change
import com.typewritermc.events.deny
import com.typewritermc.events.pass
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

/** How the verdicts on one occurrence become its outcome and which follow ups run. */
val VerdictMergeTest by testSuite {
    test("an occurrence nobody decides on is allowed") {
        merge(Poke(), emptyList()).outcome shouldBe Outcome.Allowed(Poke())
    }

    test("a pass never overrides a lower decision") {
        merge(Poke(), listOf(Ranked(deny(reason("low")), 1), Ranked(pass(), 9))).outcome shouldBe Outcome.Denied(Poke(), reason("low"))
    }

    test("the highest priority wins between allow and deny") {
        merge(Poke(), listOf(Ranked(deny(reason("low")), 1), Ranked(allow(), 5))).outcome shouldBe Outcome.Allowed(Poke())
        merge(Poke(), listOf(Ranked(allow(), 1), Ranked(deny(reason("high")), 5))).outcome shouldBe Outcome.Denied(Poke(), reason("high"))
    }

    test("a tie between allow and deny denies") {
        merge(Poke(), listOf(Ranked(allow(), 3), Ranked(deny(reason("tie")), 3))).outcome shouldBe Outcome.Denied(Poke(), reason("tie"))
    }

    test("changes apply from low to high priority, each seeing the one before") {
        val doubled = change<Poke> { it.copy(strength = it.strength * 2) }
        val plusOne = change<Poke> { it.copy(strength = it.strength + 1) }
        merge(Poke(strength = 1), listOf(Ranked(plusOne, 9), Ranked(doubled, 1))).outcome shouldBe Outcome.Allowed(Poke(strength = 3))
    }

    test("follow ups run only for the outcome their verdict matches") {
        val ran = mutableListOf<String>()
        val verdicts =
            listOf(
                Ranked(deny(reason("no")) { ran += "deny" }, 5),
                Ranked(allow { ran += "allow" }, 1),
                Ranked(pass { ran += "pass on allowed" }, 0),
                Ranked(pass(on = PassOn.Denied) { ran += "pass on denied" }, 0),
                Ranked(pass(on = PassOn.Any) { ran += "pass on any" }, 0),
            )
        val decision = merge(Poke(), verdicts)
        decision.followUps.forEach { it() }
        ran shouldBe listOf("deny", "pass on denied", "pass on any")
    }
}
