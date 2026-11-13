package com.typewritermc.playtest.wire

import com.typewritermc.playtest.wire.Message.BarrierSeen
import com.typewritermc.playtest.wire.Message.Connect
import com.typewritermc.playtest.wire.Message.End
import com.typewritermc.playtest.wire.Message.Ended
import com.typewritermc.playtest.wire.Message.Hello
import com.typewritermc.playtest.wire.Message.Lease
import com.typewritermc.playtest.wire.Message.Perceived
import com.typewritermc.playtest.wire.Message.Perception
import com.typewritermc.playtest.wire.Message.Player
import com.typewritermc.playtest.wire.Message.ProbeChat
import com.typewritermc.playtest.wire.Message.ProbeDone
import com.typewritermc.playtest.wire.Message.Ready
import com.typewritermc.playtest.wire.Message.Refused
import com.typewritermc.playtest.wire.Message.Reset
import com.typewritermc.playtest.wire.Message.ResetDone
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Role
import com.typewritermc.playtest.wire.Message.StepUntil
import com.typewritermc.playtest.wire.Message.Stepping
import com.typewritermc.playtest.wire.Message.StopStepping
import com.typewritermc.playtest.wire.Message.Submit
import com.typewritermc.playtest.wire.Message.Text
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.arbitrary.codepoints
import io.kotest.property.arbitrary.filterNot
import io.kotest.property.arbitrary.int
import io.kotest.property.arbitrary.list
import io.kotest.property.arbitrary.string
import io.kotest.property.checkAll
import java.util.UUID

val WireTest by testSuite {
    val player = UUID.fromString("5b3a7f43-37a8-3e9a-8f0e-61c1d7c3a1b2")

    test("every message reads back as the message that was written") {
        val messages =
            listOf<Message>(
                Hello(Role.CLIENT, "gv-1"),
                Refused("Paper stopped while starting; see pool/paper/logs/latest.log"),
                Submit(7, "PROBE-1 a chat line the probe sends reaches the player", "PROBE-1", 1),
                Lease(7, listOf(Player("gv-1", player), Player("gv-2", UUID(1, 2)))),
                Result(7, 1_250, null, null),
                Result(8, 90, "gv-1 did not see chat \"Hello\"", "ProbeRequirements.kt:14"),
                End("run-1", "/tmp/results/test_run.json"),
                Ended(),
                ProbeChat(3, player, "Hello"),
                ProbeDone(3, 1_204),
                StepUntil(player, 1_214, 5),
                StopStepping(player),
                Stepping(),
                Connect("127.0.0.1", 25_565),
                Ready(),
                Reset(),
                ResetDone(),
                Perceived("gv-1", Perception(1_205, listOf(Text("chat", "Hello"), Text("other", "")))),
                Perceived("gv-1", Perception(0, listOf())),
                BarrierSeen("gv-1", 5),
            )

        framed(*messages.toTypedArray()).readFrames() shouldBe messages
    }

    test("text in any script and of any length reads back unchanged") {
        val text = Arb.string(0..2_000, Arb.codepoints().filterNot { it.value in Char.MIN_SURROGATE.code..Char.MAX_SURROGATE.code })
        checkAll(PropTestConfig(seed = 2_611_131_947L, iterations = 200), Arb.list(text, 0..5), Arb.int(0..1_000_000)) { texts, tick ->
            val perceived = Perceived("gv-1", Perception(tick, texts.map { Text("chat", it) }))

            framed(perceived).readFrames() shouldBe listOf(perceived)
        }
    }

    test("a text longer than 64 KB reads back unchanged") {
        val perceived = Perceived("gv-1", Perception(1, listOf(Text("chat", "é".repeat(40_000)))))

        framed(perceived).readFrames() shouldBe listOf(perceived)
    }

    test("a frame longer than the limit is refused before its body is read") {
        val failure = shouldThrow<WireException> { handFrame(type = 0, body = byteArrayOf(), length = Wire.MAX_FRAME + 1).readFrames() }

        failure.message shouldContain "${Wire.MAX_FRAME + 1} bytes"
    }

    test("a frame without even a type byte is refused") {
        shouldThrow<WireException> { handFrame(type = 0, body = byteArrayOf(), length = 0).readFrames() }
    }

    test("an unknown type is refused and named") {
        val failure = shouldThrow<WireException> { handFrame(type = 99, body = byteArrayOf()).readFrames() }

        failure.message shouldContain "type 99"
    }

    test("a body longer than its message is refused") {
        val ready = framed(Ready())
        val padded = handFrame(type = ready[4].toInt(), body = byteArrayOf(1, 2, 3))

        val failure = shouldThrow<WireException> { padded.readFrames() }

        failure.message shouldContain "3 bytes"
    }

    test("a stream that ends inside a frame is refused as cut off") {
        val whole = framed(Perceived("gv-1", Perception(4, listOf(Text("chat", "Hello")))))

        shouldThrow<WireException> { whole.copyOf(whole.size - 2).readFrames() }
        shouldThrow<WireException> { whole.copyOf(2).readFrames() }
    }

    test("a stream that ends between frames is the end of the messages") {
        framed(Ready(), Reset()).readFrames() shouldBe listOf(Ready(), Reset())
        byteArrayOf().readFrames() shouldBe listOf()
    }
}
