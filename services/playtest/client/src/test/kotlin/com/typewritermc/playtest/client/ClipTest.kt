package com.typewritermc.playtest.client

import com.typewritermc.playtest.client.ClipSchedule.Pass
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import java.io.ByteArrayOutputStream
import java.io.IOException

val ClipTest by testSuite {
    test("a clip draws 30 frames for every second of game time") {
        val schedule = ClipSchedule()

        val drawn = (1..20).sumOf { schedule.ticked().count { it.frame() >= 0 } }

        drawn shouldBe 30
        schedule.frames() shouldBe 30
    }

    test("frames fall between ticks where their time falls, and every tick still ends with its own record") {
        val schedule = ClipSchedule()

        List(4) { schedule.ticked() } shouldBe
            listOf(
                listOf(Pass(2f / 3, 0), Pass(1f, -1)),
                listOf(Pass(1f / 3, 1), Pass(1f, 2)),
                listOf(Pass(2f / 3, 3), Pass(1f, -1)),
                listOf(Pass(1f / 3, 4), Pass(1f, 5)),
            )
    }

    test("the encoder gets every frame in the order drawn, and the finished clip counts them") {
        val encoder = ByteArrayOutputStream()
        val writer = ClipWriter(encoder) { 0 }

        listOf(byteArrayOf(1, 2), byteArrayOf(3, 4), byteArrayOf(5, 6)).forEach(writer::add)

        writer.finish() shouldBe 3
        encoder.toByteArray().toList() shouldBe listOf<Byte>(1, 2, 3, 4, 5, 6)
    }

    test("an encoder that fails fails the clip with its exit code") {
        val writer = ClipWriter(ByteArrayOutputStream()) { 1 }
        writer.add(byteArrayOf(1))

        shouldThrow<IOException> { writer.finish() }.message shouldContain "exited with code 1"
    }
}
