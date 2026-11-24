package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.test_run.CoveredClass
import skirout.harness.v1.test_run.Pacing

val RunPlanTest by testSuite {
    test("a run reruns failed attempts up to 4 in total, unless it repeats every requirement an exact number of times") {
        RunPlan.of(mapOf()).policy shouldBe AttemptPolicy.RerunFailuresWrapper(4)
        RunPlan.of(mapOf("playtest.repeat" to "1")).policy shouldBe AttemptPolicy.RerunFailuresWrapper(4)
        RunPlan.of(mapOf("playtest.repeat" to "5")).policy shouldBe AttemptPolicy.ExactlyWrapper(5)
        shouldThrow<IllegalArgumentException> { RunPlan.of(mapOf("playtest.repeat" to "0")) }
    }

    test("the quarantine holds a requirement it names by id or by test id, and no other") {
        val quarantine = RunPlan.of(mapOf("playtest.quarantine" to "LEAK-1,TOAST-1 an attempt shows no toast"))

        quarantine.quarantines("LEAK-1", "LEAK-1 hung work that ends after its attempt never reaches the next") shouldBe true
        quarantine.quarantines("TOAST-1", "TOAST-1 an attempt shows no toast") shouldBe true
        quarantine.quarantines("PROBE-1", "PROBE-1 a chat line the probe sends reaches the player") shouldBe false
        RunPlan.of(mapOf()).quarantines("LEAK-1", "LEAK-1 hung work") shouldBe false
    }

    test("a requirement is touched when the change added a line in its own code or its last attempt ran an added line") {
        val plan =
            RunPlan.of(mapOf("playtest.touched" to "/repo/build/touched.txt")) {
                "com/typewritermc/playtest/plugin/Probes.java 12\ncom/typewritermc/playtest/ToastRequirements.kt 44\n"
            }
        val toast = RequirementLines("com/typewritermc/playtest/ToastRequirements.kt", 40..52)
        val chat = RequirementLines("com/typewritermc/playtest/ToastRequirements.kt", 53..70)
        val probes =
            listOf(
                CoveredClass(
                    name = "com/typewritermc/playtest/plugin/Probes",
                    source = "com/typewritermc/playtest/plugin/Probes.java",
                    lines = listOf(12),
                ),
            )

        plan.touches(toast, listOf()) shouldBe true
        plan.touches(chat, listOf()) shouldBe false
        plan.touches(chat, probes) shouldBe true
        RunPlan.of(mapOf()).touches(toast, probes) shouldBe false
    }

    test("a run paces attempts only at the paces it names, and a window held at another tick gates unless it asks to report") {
        RunPlan.of(mapOf()).paces shouldBe listOf()
        RunPlan.of(mapOf("playtest.paces" to "5, 50")).paces shouldBe listOf(5, 50)
        RunPlan.of(mapOf()).pacing shouldBe Pacing.GATES
        RunPlan.of(mapOf("playtest.pacing" to "reports")).pacing shouldBe Pacing.REPORTS
        shouldThrow<IllegalArgumentException> { RunPlan.of(mapOf("playtest.pacing" to "warns")) }
        shouldThrow<IllegalArgumentException> { RunPlan.of(mapOf("playtest.paces" to "0")) }
    }

    test("a demo run runs each requirement once, its clients recording clips; any other run records none") {
        RunPlan.of(mapOf("playtest.demo" to "true")).demo shouldBe true
        RunPlan.of(mapOf()).demo shouldBe false
    }
}
