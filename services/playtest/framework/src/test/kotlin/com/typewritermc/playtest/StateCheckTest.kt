package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf

val StateCheckTest by testSuite {
    test("a state that comes to hold passes the window at that tick, and Paper runs no tick beyond it") {
        val game = StandInGame()
        var asked = 0

        val failure =
            game.attempt.outcome {
                probe.chat(player, "Hello")
                within(40.ticks) {
                    state("the third tick ran") {
                        asked++
                        game.ranTo >= 103
                    }
                }
            }

        failure shouldBe null
        game.ranTo shouldBe 103
        asked shouldBe 3
    }

    test("a state that never holds misses the window and names the state") {
        val game = StandInGame()

        val failure =
            game.attempt.outcome {
                probe.chat(player, "Hello")
                within(5.ticks) { state("Steve's session listed") { false } }
            }

        val missed = failure.shouldBeInstanceOf<WindowMissed>()
        missed.message shouldContain "Steve's session listed did not hold within 5 ticks"
        game.ranTo shouldBe 105
    }

    test("a state check next to a perception check waits for both") {
        val game = StandInGame()

        val failure =
            game.attempt.outcome {
                probe.chat(player, "Hello")
                within(10.ticks) {
                    player sees anyChat()
                    state("the second tick ran") { game.ranTo >= 102 }
                }
            }

        failure.shouldBeInstanceOf<WindowMissed>().message shouldContain "did not see"
    }

    test("a state check that held is a positive check, and a bare read of the same state is refused") {
        val held = StandInGame().attempt.outcome {
            probe.chat(player, "Hello")
            within(5.ticks) { state("listed") { true } }
        }
        val read = StandInGame().attempt.outcome {
            probe.chat(player, "Hello")
            check(true)
        }

        held shouldBe null
        read.shouldBeInstanceOf<RequirementRefused>()
    }

    test("a never state that stays false keeps the window open for all its ticks, and its positive check passes it") {
        val game = StandInGame()

        val failure =
            game.attempt.outcome {
                probe.chat(player, "Hello")
                within(8.ticks) {
                    state("listed") { true }
                    never.state("Steve's session gone") { false }
                }
            }

        failure shouldBe null
        game.ranTo shouldBe 108
    }

    test("a never state that turns true misses the window at that tick and names the state") {
        val game = StandInGame()

        val failure =
            game.attempt.outcome {
                probe.chat(player, "Hello")
                within(8.ticks) {
                    state("listed") { true }
                    never.state("Steve's session gone") { game.ranTo >= 104 }
                }
            }

        val missed = failure.shouldBeInstanceOf<WindowMissed>()
        missed.message shouldContain "Steve's session gone held at tick 4 of the 8 tick window"
        game.ranTo shouldBe 104
    }
}

