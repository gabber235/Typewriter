package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.assertions.withClue
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeSameInstanceAs
import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.test_run.Conclusion
import skirout.harness.v1.test_run.LossCause
import skirout.harness.v1.test_run.Pacing
import skirout.harness.v1.test_run.WindowEnd
import skirout.harness.v1.wire.ClientLoss

val VerdictTest by testSuite {
    val retries = AttemptPolicy.RerunFailuresWrapper(4)
    val thrice = AttemptPolicy.ExactlyWrapper(3)
    val missed = AssertionError("gv-1 did not see chat \"Hello\" within 5 ticks")
    val lost =
        ClientLost(
            "gv-1",
            ClientLoss(cause = LossCause.ExitedWrapper(137), detail = "its process exited with code 137", log = "client-gv-1/lost-1.log"),
        )
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

    test("every window holds at the same tick in every passing run of a requirement, or it is unsteady") {
        fun held(
            tick: Int?,
            afterWallClock: Boolean = false,
        ) = WindowEnd(at = "ToastRequirements.kt:42", length = 20, heldAt = tick, afterWallClock = afterWallClock)

        fun ran(
            pace: Int,
            failure: Throwable?,
            vararg windows: WindowEnd,
        ) = PoolSession.AttemptEnd(failure, windows = windows.toList(), paceMillis = pace)
        // The attempts, the paced attempts, and whether the requirement is unsteady.
        val table =
            listOf(
                Triple(listOf(ran(0, null, held(3))), listOf(), false),
                Triple(listOf(ran(0, null, held(3))), listOf(ran(5, null, held(3)), ran(50, null, held(3))), false),
                Triple(listOf(ran(0, null, held(3))), listOf(ran(5, null, held(3)), ran(50, null, held(4))), true),
                Triple(listOf(ran(0, missed, held(9)), ran(0, null, held(3))), listOf(), false),
                Triple(listOf(ran(0, null, held(3)), ran(0, null, held(4))), listOf(), true),
                Triple(listOf(ran(0, null, held(3))), listOf(ran(50, missed, held(null))), true),
                Triple(listOf(ran(0, null, held(3), held(2, afterWallClock = true))), listOf(ran(50, null, held(3), held(7))), false),
                Triple(listOf(ran(0, null, held(3), held(2))), listOf(ran(50, null, held(3))), true),
            )
        for ((row, case) in table.withIndex()) {
            val (attempts, paced, unsteady) = case

            val verdict = Verdict.Passed.steadied(attempts, paced, Pacing.GATES)

            withClue("row $row") { (verdict is Verdict.Unsteady) shouldBe unsteady }
        }
    }

    test("an unsteady requirement names the tick of each window in each run, and fails its test only when its pacing gates") {
        fun ran(
            pace: Int,
            tick: Int?,
            failure: Throwable? = null,
        ) = PoolSession.AttemptEnd(
            failure,
            windows = listOf(WindowEnd(at = "ToastRequirements.kt:42", length = 20, heldAt = tick, afterWallClock = false)),
            paceMillis = pace,
        )
        val attempts = listOf(ran(0, 10))
        val paced = listOf(ran(5, 10), ran(50, null, missed))

        val unsteady =
            shouldThrow<RequirementUnsteady> {
                Verdict.Passed.steadied(attempts, paced, Pacing.GATES).conclude(RequirementCode.of {})
            }

        unsteady.message shouldBe
            "unsteady: a window holds at another tick at another pace; attempt 1 at 0 ms held ToastRequirements.kt:42 at tick 10; " +
            "at 5 ms held ToastRequirements.kt:42 at tick 10; at 50 ms missed ToastRequirements.kt:42 (failed: ${missed.message})"
        Verdict.Passed.steadied(attempts, paced, Pacing.REPORTS).conclude(RequirementCode.of {})
        Verdict.Flaky(listOf(missed), 2).steadied(attempts, paced, Pacing.GATES) shouldBe Verdict.Flaky(listOf(missed), 2)
    }

    test("the run file carries what the session concluded of each requirement, an unsteady one with the tick of each window in each run") {
        val ticks = "attempt 1 at 0 ms held ToastRequirements.kt:42 at tick 10; at 50 ms held ToastRequirements.kt:42 at tick 11"

        listOf(
            Verdict.Passed,
            Verdict.Flaky(listOf(missed), 2),
            Verdict.Failed(listOf(missed), 1),
            Verdict.Quarantined(listOf(missed), 1),
            Verdict.Unsteady(ticks, gates = false),
        ).map { it.conclusion } shouldBe
            listOf(Conclusion.PASSED, Conclusion.FLAKY, Conclusion.FAILED, Conclusion.QUARANTINED, Conclusion.UnsteadyWrapper(ticks))
    }
}
