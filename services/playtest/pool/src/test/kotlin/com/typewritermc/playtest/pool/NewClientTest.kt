package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.harness.v1.wire.ClientLossKind

val NewClientTest by testSuite {
    test("a new client that exits, closes its pool connection or drops off its Paper before it steps is lost too") {
        listOf(ClientLossKind.EXITED, ClientLossKind.LEFT_POOL, ClientLossKind.DROPPED).map { it.losesNewClient } shouldBe
            listOf(true, true, true)
    }

    test("Paper seeing the player leave or stall before its new client steps tells of the lost client, not the new one") {
        listOf(ClientLossKind.LEFT_PAPER, ClientLossKind.STALLED).map { it.losesNewClient } shouldBe listOf(false, false)
    }
}
