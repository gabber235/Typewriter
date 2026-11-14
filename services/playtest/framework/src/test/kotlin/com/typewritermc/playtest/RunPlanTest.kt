package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.AttemptPolicy
import com.typewritermc.playtest.wire.Message.AttemptPolicy.Kind.EXACTLY
import com.typewritermc.playtest.wire.Message.AttemptPolicy.Kind.RERUN_FAILURES
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val RunPlanTest by testSuite {
    test("a run that names no requirement runs every one; one that names some runs only those, by id or by test id") {
        val everything = RunPlan.of(mapOf())
        val named = RunPlan.of(mapOf("playtest.only" to "PROBE-1,HUNG-1 work still running fails the attempt"))

        everything.runs("PROBE-2", "PROBE-2 the first input after a far teleport acts there") shouldBe true
        named.runs("PROBE-1", "PROBE-1 a chat line the probe sends reaches the player") shouldBe true
        named.runs("HUNG-1", "HUNG-1 work still running fails the attempt") shouldBe true
        named.runs("PROBE-2", "PROBE-2 the first input after a far teleport acts there") shouldBe false
        named.runs("PROBE-10", "PROBE-10 a requirement whose id starts like a named one") shouldBe false
    }

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
}
