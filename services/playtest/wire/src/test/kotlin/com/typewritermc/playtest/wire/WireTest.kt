package com.typewritermc.playtest.wire

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import skirout.harness.v1.wire.Message
import skirout.harness.v1.wire.StepAck
import skirout.harness.v1.wire.Watch

val WireTest by testSuite {
    test("every message and every payload reads back as it was written, whatever variants the wire declares") {
        val messages = samples(Message.typeDescriptor)

        messages.map { it.kind } shouldContainAll Message.Kind.entries - Message.Kind.UNKNOWN
        messages.forEach { framed(it).readFrames() shouldBe listOf(it) }
        samples(Watch.typeDescriptor).forEach { Payload.watch(Payload.body(it)) shouldBe it }
        samples(StepAck.typeDescriptor).forEach { Payload.stepAck(Payload.body(it)) shouldBe it }
    }

    test("a frame longer than the limit is refused before its bytes are read") {
        val failure = shouldThrow<WireException> { handFrame(byteArrayOf(), length = Wire.MAX_FRAME + 1).readFrames() }

        failure.message shouldContain "${Wire.MAX_FRAME + 1} bytes"
    }

    test("a frame that holds no message is refused") {
        shouldThrow<WireException> { handFrame(byteArrayOf(), length = 0).readFrames() }
        shouldThrow<WireException> { handFrame("skir".toByteArray() + byteArrayOf(-1, -1, -1)).readFrames() }
    }

    test("a stream that ends inside a frame is refused as cut off") {
        val whole = framed(Message.READY)

        shouldThrow<WireException> { whole.copyOf(whole.size - 2).readFrames() }
        shouldThrow<WireException> { whole.copyOf(2).readFrames() }
    }

    test("a stream that ends between frames is the end of the messages") {
        framed(Message.READY, Message.RESET).readFrames() shouldBe listOf(Message.READY, Message.RESET)
        byteArrayOf().readFrames() shouldBe listOf()
    }
}
