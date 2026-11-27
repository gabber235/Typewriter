package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.harness.v1.wire.KeyboardKey

val AwayTest by testSuite {
    test("a window that checks a player who quit is refused, naming the player, and runs no tick for it") {
        val game = StandInGame()

        val refused =
            game.attempt.outcome {
                player.quit()
                within(10.ticks) { player sees chat("Hello") }
            }

        refused.shouldBeInstanceOf<RequirementRefused>().message shouldContain
            "${game.player.name} quit and is not on Paper; rejoin it before a window checks it"
        game.stepped shouldBe false
    }

    test("an input or a frame of a player who quit is refused instead of waiting for a client that is not on Paper") {
        val pressed =
            StandInGame().attempt.outcome {
                player.quit()
                player.press(KeyboardKey.E)
            }
        val framed =
            StandInGame().attempt.outcome {
                player.quit()
                player.capture("scene")
            }

        pressed.shouldBeInstanceOf<RequirementRefused>().message shouldContain "quit and is not on Paper"
        framed.shouldBeInstanceOf<RequirementRefused>().message shouldContain "quit and is not on Paper"
    }

    test("a player who quit cannot quit again, and a player on Paper cannot rejoin") {
        val twice =
            StandInGame().attempt.outcome {
                player.quit()
                player.quit()
            }
        val unquit = StandInGame().attempt.outcome { player.rejoin() }

        twice.shouldBeInstanceOf<RequirementRefused>().message shouldContain "already quit"
        unquit.shouldBeInstanceOf<RequirementRefused>().message shouldContain "is on Paper; only a player who quit can rejoin"
    }

    test("a player who rejoined is checked again, its window counting from the rejoin") {
        val game = StandInGame()

        val ended =
            game.attempt.outcome {
                player.quit()
                player.rejoin()
                within(10.ticks) { player sees chat("Hello") }
            }

        ended.shouldBeInstanceOf<WindowMissed>().report shouldContain
            "did not see chat \"Hello\" within 10 ticks (ticks ${game.rejoinedAfter + 1} to ${game.rejoinedAfter + 10})"
    }

    test("a restart while a player is away is refused, as the restarted Paper would wait for that player") {
        val refused =
            StandInGame(restartsPaper = true).attempt.outcome {
                player.quit()
                restartPaper()
            }

        refused.shouldBeInstanceOf<RequirementRefused>().message shouldContain "rejoin it before restartPaper"
    }
}
