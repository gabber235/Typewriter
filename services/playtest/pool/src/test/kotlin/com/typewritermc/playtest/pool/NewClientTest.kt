package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.harness.v1.test_run.LossCause
import skirout.harness.v1.test_run.MemoryKill

val NewClientTest by testSuite {
    test("a new client that exits, is killed for memory, closes its pool connection or drops off its Paper before it steps is lost too") {
        listOf(
            LossCause.ExitedWrapper(1),
            LossCause.KilledForMemoryWrapper(MemoryKill.OWN_LIMIT),
            LossCause.LeftWrapper("its connection to the pool closed"),
            LossCause.DroppedWrapper("it could not join paper"),
        ).map { it.losesNewClient } shouldBe listOf(true, true, true, true)
    }

    test("Paper seeing the player leave or stall before its new client steps tells of the lost client, not the new one") {
        listOf(LossCause.LeftPaperWrapper("Disconnected"), LossCause.STALLED).map { it.losesNewClient } shouldBe listOf(false, false)
    }
}
