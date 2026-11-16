package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.AttemptPolicy
import com.typewritermc.playtest.wire.Message.AttemptPolicy.Kind.EXACTLY
import com.typewritermc.playtest.wire.Message.AttemptPolicy.Kind.RERUN_FAILURES
import com.typewritermc.playtest.wire.Message.CoveredClass
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val RunPlanTest by testSuite {
    test("a run reruns failed attempts up to 4 in total, unless it repeats every requirement an exact number of times") {
        RunPlan.of(mapOf()).policy shouldBe AttemptPolicy(RERUN_FAILURES, 4)
        RunPlan.of(mapOf("playtest.repeat" to "1")).policy shouldBe AttemptPolicy(RERUN_FAILURES, 4)
        RunPlan.of(mapOf("playtest.repeat" to "5")).policy shouldBe AttemptPolicy(EXACTLY, 5)
        shouldThrow<IllegalArgumentException> { RunPlan.of(mapOf("playtest.repeat" to "0")) }
    }

    test("the quarantine holds a requirement it names by id or by test id, and no other") {
        val quarantine = RunPlan.of(mapOf("playtest.quarantine" to "LEAK-1,TOAST-1 an attempt shows no toast"))

        quarantine.quarantines("LEAK-1", "LEAK-1 hung work that ends after its attempt never reaches the next") shouldBe true
        quarantine.quarantines("TOAST-1", "TOAST-1 an attempt shows no toast") shouldBe true
        quarantine.quarantines("PROBE-1", "PROBE-1 a chat line the probe sends reaches the player") shouldBe false
        RunPlan.of(mapOf()).quarantines("LEAK-1", "LEAK-1 hung work") shouldBe false
    }

    test("a requirement runs once more in demo mode when it failed or the change touched code it covered, and only then") {
        val changed = mapOf("playtest.touched" to "/repo/build/touched.txt")
        val plan = RunPlan.of(changed) { "com/typewritermc/playtest/plugin/Probes.java 12\n" }
        val probes = listOf(CoveredClass("com/typewritermc/playtest/plugin/Probes", "com/typewritermc/playtest/plugin/Probes.java", listOf(12)))
        val wipe = listOf(CoveredClass("com/typewritermc/playtest/plugin/Wipe", "com/typewritermc/playtest/plugin/Wipe.java", listOf(12)))
        val failed = AssertionError("the toast never showed")

        plan.demos(Verdict.Passed, probes) shouldBe true
        plan.demos(Verdict.Passed, wipe) shouldBe false
        plan.demos(Verdict.Failed(listOf(failed), 4), wipe) shouldBe true
        plan.demos(Verdict.Flaky(listOf(failed), 2), wipe) shouldBe true
        plan.demos(Verdict.Quarantined(listOf(failed), 1), wipe) shouldBe true
        RunPlan.of(mapOf()).demos(Verdict.Passed, probes) shouldBe false
    }

    test("a requirement the pool refused, or whose game broke, runs no demo: it would end the same way") {
        val plan = RunPlan.of(mapOf())

        plan.demos(Verdict.Failed(listOf(RequirementRefused("a window without a positive check")), 1), listOf()) shouldBe false
        plan.demos(Verdict.Failed(listOf(GameUnavailable("Paper stopped while starting")), 1), listOf()) shouldBe false
    }
}
