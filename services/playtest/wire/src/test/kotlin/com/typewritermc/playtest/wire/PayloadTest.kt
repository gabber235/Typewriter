package com.typewritermc.playtest.wire

import com.typewritermc.playtest.wire.Message.BlockPos
import com.typewritermc.playtest.wire.Payload.StepAck
import com.typewritermc.playtest.wire.Payload.Watch
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import java.util.UUID

val PayloadTest by testSuite {
    test("every payload reads back as the payload that was written") {
        val watch = Watch(listOf(BlockPos(0, 101, 2), BlockPos(-3, -64, 7)), listOf(UUID(3, 4), UUID(-1, 5)))
        val ack = StepAck(1_220, true)

        Watch.read(watch.body()) shouldBe watch
        StepAck.read(ack.body()) shouldBe ack
    }

    test("a payload body longer than its payload is refused") {
        val failure = shouldThrow<WireException> { StepAck.read(StepAck(7, false).body() + byteArrayOf(1, 2)) }

        failure.message shouldContain "2 bytes"
    }

    test("a payload body that ends early is refused") {
        shouldThrow<WireException> { Watch.read(Watch(listOf(BlockPos(1, 2, 3)), listOf()).body().copyOf(6)) }
    }
}
