package com.typewritermc.services.libs.communicator.transfer

import com.typewritermc.services.libs.communicator.transport.Payload
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
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
    test("assembles out of order and accepts identical duplicates") {
        val limits = BoundedTransferLimits(3, 3)
        val bytes = byteArrayOf(1, 2, 3, 4, 5, 6, 7)
        val chunks = (BoundedByteTransferEncoder(limits) { "request" }.encode(bytes) as BoundedTransferPlan.Ready).chunks
        val assembler = BoundedByteTransferAssembler("request", limits)
        assembler.accept(chunks[2]) shouldBe null
        assembler.accept(chunks[2]) shouldBe null
        assembler.accept(chunks[0]) shouldBe null
        assembler.accept(chunks[1]) shouldBe bytes
    }
    test("rejects another request and changed transfer metadata") {
        val limits = BoundedTransferLimits(2, 2)
        val chunks = (BoundedByteTransferEncoder(limits) { "request" }.encode(byteArrayOf(1, 2, 3)) as BoundedTransferPlan.Ready).chunks
        val assembler = BoundedByteTransferAssembler("request", limits)
        shouldThrow<IllegalArgumentException> { assembler.accept(chunks[0].copy(transferId = "other")) }
        assembler.accept(chunks[0]) shouldBe null
        shouldThrow<IllegalArgumentException> { assembler.accept(chunks[1].copy(sha256 = "bad")) }
        shouldThrow<IllegalArgumentException> { assembler.accept(chunks[0].copy(payload = Payload.copyOf(byteArrayOf(2, 1)))) }
    }
    test("rejects oversized parts and corrupt complete payloads") {
        val limits = BoundedTransferLimits(2, 2)
        val chunk =
            (
                BoundedByteTransferEncoder(
                    limits,
                ) { "request" }.encode(byteArrayOf(1, 2)) as BoundedTransferPlan.Ready
            ).chunks.single()
        shouldThrow<IllegalArgumentException> { BoundedByteTransferAssembler("request", limits).accept(chunk.copy(encodedSize = 5)) }
        shouldThrow<IllegalArgumentException> {
            BoundedByteTransferAssembler("request", limits).accept(chunk.copy(payload = Payload.copyOf(byteArrayOf(2, 1))))
        }
        shouldThrow<IllegalArgumentException> { BoundedByteTransferAssembler("request", limits).accept(chunk.copy(index = 1)) }
    }
    test("chunksAndHashesOneCompletePayload") { BoundedByteTransferTest().chunksAndHashesOneCompletePayload() }
    test("rejectsBeforeProducingAnyChunkAboveTheBound") {
        BoundedByteTransferTest().rejectsBeforeProducingAnyChunkAboveTheBound()
    }
    test("emptyPayloadStillHasOneVerifiableChunk") { BoundedByteTransferTest().emptyPayloadStillHasOneVerifiableChunk() }
}
