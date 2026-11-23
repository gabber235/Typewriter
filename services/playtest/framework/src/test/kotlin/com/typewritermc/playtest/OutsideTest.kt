package com.typewritermc.playtest

import com.typewritermc.playtest.wire.chatLine
import com.typewritermc.playtest.wire.text
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.coroutineScope
import skirout.harness.v1.wire.Perception

val OutsideTest by testSuite {
    test("a window after a stimulus from outside Paper counts from the tick that last ended on Paper before it started") {
        val game = StandInGame()

        val ended =
            game.attempt.outcome {
                coroutineScope {
                    outside("a panel tab emits") {}
                    within(10.ticks) { player sees chat("Hello") }
                }
            }

        ended.shouldBeInstanceOf<WindowMissed>().report shouldContain "within 10 ticks (ticks 101 to 110)"
    }

    test("what a stimulus from outside Paper causes passes the window, and its result comes once its action ends") {
        val game = StandInGame()
        game.shows = Perception.partial().copy(texts = listOf(text("chat", "Hello")), chat = listOf(chatLine(103, "Hello")))
        var result: String? = null

        val ended =
            game.attempt.outcome {
                coroutineScope {
                    val emitted = outside("a panel tab emits") { "done" }
                    within(10.ticks) { player sees chat("Hello") }
                    result = emitted.await()
                }
            }

        ended shouldBe null
        result shouldBe "done"
    }

    test("a stimulus from outside Paper is a step of the attempt, named by what it says") {
        val game = StandInGame()

        game.attempt.outcome { coroutineScope { outside("a panel tab emits") {}.await() } }

        game.attempt.steps.map { it.says } shouldContain "outside: a panel tab emits"
    }
}
