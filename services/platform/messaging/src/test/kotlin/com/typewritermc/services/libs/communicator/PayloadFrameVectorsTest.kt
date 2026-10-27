package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.testing.base64
import com.typewritermc.services.libs.communicator.testing.frameLimits
import com.typewritermc.services.libs.communicator.testing.frameVectorCases
import com.typewritermc.services.libs.communicator.testing.vectorMessage
import com.typewritermc.services.libs.communicator.testing.wireName
import com.typewritermc.services.libs.communicator.transfer.Assembly
import com.typewritermc.services.libs.communicator.transfer.PayloadAssembler
import com.typewritermc.services.libs.communicator.transfer.TransferRejected
import com.typewritermc.services.libs.communicator.transport.Payload
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long

/**
 * The shared frame vectors, which the backend framer writes to `skir-src/transport/v1/fixtures/frames.json` through
 * `cargo xtask generate`. Every message of a case but the last leaves the assembler waiting; the last one produces the
 * case's expected outcome, the same one the backend and panel assemblers reach.
 */
val PayloadFrameVectorsTest by testSuite {
    for (case in frameVectorCases()) {
        val name = case.getValue("name").jsonPrimitive.content
        test(name) {
            val maxBytes = case.getValue("maxBytes").jsonPrimitive.long
            val assembler = PayloadAssembler(frameLimits(case.getValue("chunkBytes").jsonPrimitive.int, maxBytes), maxBytes)
            val messages = case.getValue("frames").jsonArray.map { it.jsonObject.vectorMessage() }
            messages.dropLast(1).forEach { assembler.accept(it) shouldBe Assembly.Waiting }

            val expect = case.getValue("expect").jsonObject
            val last = messages.last()
            when {
                "bytes" in expect -> {
                    val complete = assembler.accept(last).shouldBeInstanceOf<Assembly.Complete>()
                    complete.message.payload shouldBe Payload.copyOf(expect.base64("bytes"))
                }

                "pending" in expect -> {
                    assembler.accept(last) shouldBe Assembly.Waiting
                }

                "rejected" in expect -> {
                    val rejected = runCatching { assembler.accept(last) }.exceptionOrNull()
                    rejected.shouldBeInstanceOf<TransferRejected>()
                }

                else -> {
                    val failed = assembler.accept(last).shouldBeInstanceOf<Assembly.Failed>()
                    failed.failure.wireName() shouldBe expect.getValue("failure").jsonPrimitive.content
                }
            }
        }
    }
}
