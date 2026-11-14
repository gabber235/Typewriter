package com.typewritermc.playtest.client

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val PixelsTest by testSuite {
    val stone = 0xFF7F7F7F.toInt()
    val zombie = 0xFF2E5A3B.toInt()

    test("a frame drawn without a thing that changes no pixel leaves the thing no pixels") {
        val with = Pixels(3, 2, IntArray(6) { stone })
        val without = Pixels(3, 2, IntArray(6) { stone })

        with.differences(without) shouldBe 0
    }

    test("every pixel that shows another colour without the thing is the thing's own") {
        val with = Pixels(3, 2, intArrayOf(stone, zombie, zombie, stone, stone, zombie))
        val without = Pixels(3, 2, IntArray(6) { stone })

        with.differences(without) shouldBe 3
    }

    test("a colour off by one level in one channel is a different pixel") {
        val with = Pixels(2, 1, intArrayOf(stone, stone + 0x10000))
        val without = Pixels(2, 1, intArrayOf(stone, stone))

        with.differences(without) shouldBe 1
    }

    test("a pixel that differs only in alpha, which never reaches the screen, is no different") {
        val with = Pixels(2, 1, intArrayOf(stone, 0x307F7F7F))
        val without = Pixels(2, 1, intArrayOf(stone, stone))

        with.differences(without) shouldBe 0
    }

    test("frames of different sizes are refused") {
        shouldThrow<IllegalArgumentException> { Pixels(2, 1, IntArray(2)).differences(Pixels(1, 2, IntArray(2))) }
    }
}
