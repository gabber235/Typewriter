package com.typewritermc.services.libs.communicator.transfer

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeTypeOf

class BoundedByteTransferTest {
    fun chunksAndHashesOneCompletePayload() {
        val encoder = BoundedByteTransferEncoder(BoundedTransferLimits(chunkSize = 3, maxChunks = 3)) { "transfer" }
        val ready = encoder.encode(byteArrayOf(1, 2, 3, 4, 5, 6, 7)).shouldBeTypeOf<BoundedTransferPlan.Ready>()

        ready.chunks.map { it.index } shouldBe listOf(0, 1, 2)
        ready.chunks.map { it.payload.size } shouldBe listOf(3, 3, 1)
        ready.chunks.map { it.transferId }.toSet() shouldBe setOf("transfer")
        ready.chunks.map { it.encodedSize }.toSet() shouldBe setOf(7L)
        ready.chunks
            .map { it.sha256 }
            .toSet()
            .size shouldBe 1
        ready.chunks.flatMap { it.payload.toByteArray().asIterable() }.toByteArray() shouldBe
            byteArrayOf(1, 2, 3, 4, 5, 6, 7)
    }

    fun rejectsBeforeProducingAnyChunkAboveTheBound() {
        val encoder = BoundedByteTransferEncoder(BoundedTransferLimits(chunkSize = 2, maxChunks = 2))
        val unavailable = encoder.encode(ByteArray(5)).shouldBeTypeOf<BoundedTransferPlan.Unavailable>()

        unavailable.encodedSize shouldBe 5L
        unavailable.maxEncodedSize shouldBe 4L
    }

    fun emptyPayloadStillHasOneVerifiableChunk() {
        val encoder = BoundedByteTransferEncoder(BoundedTransferLimits(chunkSize = 2, maxChunks = 2)) { "empty" }
        val ready = encoder.encode(byteArrayOf()).shouldBeTypeOf<BoundedTransferPlan.Ready>()

        ready.chunks.size shouldBe 1
        ready.chunks.single().encodedSize shouldBe 0L
        ready.chunks
            .single()
            .payload
            .toByteArray() shouldBe byteArrayOf()
    }
}

val BoundedByteTransferTestSuite by testSuite {
    test("chunksAndHashesOneCompletePayload") { BoundedByteTransferTest().chunksAndHashesOneCompletePayload() }
    test("rejectsBeforeProducingAnyChunkAboveTheBound") {
        BoundedByteTransferTest().rejectsBeforeProducingAnyChunkAboveTheBound()
    }
    test("emptyPayloadStillHasOneVerifiableChunk") { BoundedByteTransferTest().emptyPayloadStillHasOneVerifiableChunk() }
}
