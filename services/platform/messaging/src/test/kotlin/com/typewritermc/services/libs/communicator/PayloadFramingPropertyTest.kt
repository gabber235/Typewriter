package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.testing.frameLimits
import com.typewritermc.services.libs.communicator.testing.framedReply
import com.typewritermc.services.libs.communicator.testing.seededBytes
import com.typewritermc.services.libs.communicator.testing.toInbound
import com.typewritermc.services.libs.communicator.transfer.Assembly
import com.typewritermc.services.libs.communicator.transfer.PayloadAssembler
import com.typewritermc.services.libs.communicator.transfer.PayloadPlan
import com.typewritermc.services.libs.communicator.transfer.TransferRejected
import com.typewritermc.services.libs.communicator.transfer.planPayload
import com.typewritermc.services.libs.communicator.transport.Payload
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.arbitrary.int
import io.kotest.property.arbitrary.long
import io.kotest.property.checkAll
import kotlin.random.Random

/**
 * Framing invariants over generated payload sizes, chunk sizes and arrival orders. The seed is fixed, so every run
 * checks the same cases; a failure this finds becomes an example in PayloadFramingTest.
 */
val PayloadFramingPropertyTest by testSuite {
    /** Fixed, so every run checks the same cases; change it only on purpose. */
    val config = PropTestConfig(seed = 5_235_178_041L, iterations = 300)

    test("every payload split at any chunk size reassembles to the same bytes in any arrival order") {
        checkAll(config, Arb.int(1..MAX_CHUNK), Arb.int(0..MAX_BYTES), Arb.long()) { chunk, size, seed ->
            val limits = frameLimits(chunk, MAX_BYTES.toLong())
            val payload = seededBytes(size, seed)

            when (val plan = limits.planPayload(Payload.copyOf(payload), MAX_BYTES.toLong())) {
                PayloadPlan.Single -> {
                    (size <= chunk) shouldBe true
                }

                is PayloadPlan.Framed -> {
                    val assembler = PayloadAssembler(limits, MAX_BYTES.toLong())
                    val results = plan.frames.shuffled(Random(seed)).map { assembler.accept(it.toInbound()) }

                    results.dropLast(1).forEach { it shouldBe Assembly.Waiting }
                    val complete = results.last().shouldBeInstanceOf<Assembly.Complete>()
                    complete.message.payload shouldBe Payload.copyOf(payload)
                    complete.message.headers.first("Typewriter-Payload") shouldBe null
                }

                is PayloadPlan.TooLarge -> {
                    throw AssertionError("A payload within the ceiling was planned too large")
                }
            }
        }
    }

    test("a frame whose bytes changed on the way is refused instead of assembled") {
        checkAll(config, Arb.int(1..MAX_CHUNK), Arb.int(MAX_CHUNK + 1..MAX_BYTES), Arb.long()) { chunk, size, seed ->
            val limits = frameLimits(chunk, MAX_BYTES.toLong())
            val plan = limits.planPayload(Payload.copyOf(seededBytes(size, seed)), MAX_BYTES.toLong()) as PayloadPlan.Framed
            val random = Random(seed)
            val damaged = random.nextInt(plan.frames.size)
            val messages =
                plan.frames.map { frame ->
                    val message = frame.toInbound()
                    if (frame.index != damaged) return@map message
                    val bytes = message.payload.toByteArray()
                    bytes[random.nextInt(bytes.size)]++
                    message.copy(payload = Payload.copyOf(bytes))
                }
            val assembler = PayloadAssembler(limits, MAX_BYTES.toLong())

            shouldThrow<TransferRejected> { messages.forEach { assembler.accept(it) } }
        }
    }

    test("a window end after a missing frame is answered incomplete") {
        checkAll(config, Arb.int(1..MAX_CHUNK), Arb.int(MAX_CHUNK + 1..MAX_BYTES), Arb.long()) { chunk, size, seed ->
            val limits = frameLimits(chunk, MAX_BYTES.toLong())
            val plan = limits.planPayload(Payload.copyOf(seededBytes(size, seed)), MAX_BYTES.toLong()) as PayloadPlan.Framed
            val missing = Random(seed).nextInt(plan.frames.size - 1)
            val assembler = PayloadAssembler(limits, MAX_BYTES.toLong())
            val delivered = plan.frames.filter { it.index != missing }

            delivered.dropLast(1).forEach { assembler.accept(it.toInbound()) shouldBe Assembly.Waiting }
            val windowEnd = assembler.accept(delivered.last().toInbound().copy(replyTo = framedReply))

            windowEnd.shouldBeInstanceOf<Assembly.Answer>().headers.first("Typewriter-Transfer-Failure") shouldBe "incomplete"
        }
    }
}

private const val MAX_CHUNK = 64

private const val MAX_BYTES = MAX_CHUNK * 16
