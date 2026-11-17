package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.assertions.withClue
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeSameInstanceAs
import skirout.harness.v1.test_run.AttemptPolicy

val VerdictTest by testSuite {
    val retries = AttemptPolicy.RerunFailuresWrapper(4)
    val thrice = AttemptPolicy.ExactlyWrapper(3)
    val missed = AssertionError("gv-1 did not see chat \"Hello\" within 5 ticks")
    val lost = ClientLost("gv-1", "its process exited with code 137; see client-gv-1/lost-1.log")
    val declined = RequirementDeclined("GROUP-1 cannot run here: a requirement claims 3 players, but the pool holds 1")
    val refused = RequirementRefused("a window needs a positive check: without one it could never fail")
    val broken = GameUnavailable("the game pool broke the connection before the run ended; see pool.log")

    test("each policy makes the attempts its rules ask for, and the verdict follows what they showed") {
        // The policy and whether the quarantine holds the requirement; each attempt's failure, null for a
        // pass; the verdict and how many attempts ran.
        val table =
            listOf(
                Triple(retries to false, listOf(null), Verdict.Passed::class to 1),
                Triple(retries to false, listOf(missed, null), Verdict.Flaky::class to 2),
                Triple(retries to false, listOf(missed, missed, missed, null), Verdict.Flaky::class to 4),
                Triple(retries to false, listOf(missed, missed, missed, missed), Verdict.Failed::class to 4),
                Triple(retries to false, listOf(lost, null), Verdict.Flaky::class to 2),
                Triple(retries to false, listOf(declined), Verdict.Failed::class to 1),
                Triple(retries to false, listOf(refused), Verdict.Failed::class to 1),
                Triple(retries to false, listOf(broken), Verdict.Failed::class to 1),
                Triple(retries to true, listOf(missed), Verdict.Quarantined::class to 1),
                Triple(retries to true, listOf(null), Verdict.Passed::class to 1),
                Triple(thrice to false, listOf(null, null, null), Verdict.Passed::class to 3),
                Triple(thrice to false, listOf(null, missed, null), Verdict.Failed::class to 3),
                Triple(thrice to false, listOf(declined), Verdict.Failed::class to 1),
            )
        for ((row, case) in table.withIndex()) {
            val (setup, failures, expected) = case
            val (policy, quarantined) = setup
            var ran = 0

            val verdict = policy.attempt(quarantined) { number -> failures[number - 1].also { ran = number } }

            withClue("row $row") { (verdict::class to ran) shouldBe expected }
        }
    }

    test("a flaky requirement fails its test, naming its failed and passed attempts, with the body's line first") {
        val first = runCatching { "tick".toInt() }.exceptionOrNull()!!

        val flaky = shouldThrow<RequirementFlaky> { Verdict.Flaky(listOf(first), attempts = 2).conclude(RequirementCode.of {}) }

        flaky.message shouldBe
            "flaky: attempt 1 of 2 failed and attempt 2 passed; a flaky requirement blocks like a failure.\n" +
            "Attempt 1: java.lang.NumberFormatException: For input string: \"tick\""
        flaky.stackTrace.first().fileName shouldBe "VerdictTest.kt"
        flaky.cause shouldBeSameInstanceAs first
    }

    test("a requirement that failed every attempt fails its test with the last failure, the earlier ones suppressed") {
        val failures = listOf(AssertionError("attempt 1 missed"), AssertionError("attempt 2 missed"))

        val failed = shouldThrow<AssertionError> { Verdict.Failed(failures, attempts = 2).conclude(RequirementCode.of {}) }

        failed shouldBeSameInstanceAs failures[1]
        failed.suppressed.toList() shouldBe listOf(failures[0])
    }

    test("a quarantined requirement that failed does not fail its test, nor does one that passed") {
        Verdict.Quarantined(listOf(missed), attempts = 1).conclude(RequirementCode.of {})
        Verdict.Passed.conclude(RequirementCode.of {})
    }

    test("a demo that ends otherwise than the requirement's last attempt fails it, and one that ends the same way does not") {
        demoDiffers(last = null, demo = null) shouldBe null
        demoDiffers(last = missed, demo = AssertionError("gv-1 did not see chat \"Hello\" within 5 ticks, in the demo")) shouldBe null

        val failedDemo = demoDiffers(last = null, demo = missed)
        failedDemo?.message shouldBe "the demo failed where the last attempt passed: ${missed.message}"
        failedDemo?.cause shouldBeSameInstanceAs missed
        demoDiffers(last = missed, demo = null)?.message shouldBe
            "the demo passed where the last attempt failed: ${missed.message}"
    }
}
