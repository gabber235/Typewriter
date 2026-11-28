package com.typewritermc.playtest.client

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val OncePerTickTest by testSuite {
    test("work vanilla runs every frame runs once per tick, in the first frame after it, however many frames run between ticks") {
        val gate = OncePerTick()
        // Wall clock decides how many frames run between two ticks: here 3, then 1, then none before a tick.
        val frames = listOf(3, 1, 0, 2)

        val ran =
            frames.map { between ->
                gate.ticked()
                val afterTick = gate.runs()
                afterTick to List(between) { gate.runs() }.count { it }
            }

        ran shouldBe listOf(true to 0, true to 0, true to 0, true to 0)
    }

    test("a frame before any tick, or after the client left its Paper, runs none of it") {
        val gate = OncePerTick()
        gate.runs() shouldBe false

        gate.ticked()
        gate.reset()

        gate.runs() shouldBe false
    }
}
