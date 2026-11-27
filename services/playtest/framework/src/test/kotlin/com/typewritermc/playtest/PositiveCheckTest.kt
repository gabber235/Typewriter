package com.typewritermc.playtest

import com.typewritermc.playtest.wire.chatLine
import com.typewritermc.playtest.wire.perception
import com.typewritermc.playtest.wire.text
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.longs.shouldBeGreaterThan
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.harness.v1.test_run.Artifact
import skirout.harness.v1.test_run.ArtifactKind
import skirout.harness.v1.test_run.AttemptPolicy
import skirout.harness.v1.wire.StateKind

val PositiveCheckTest by testSuite {
    test("a body that only reads is refused for making no positive check, and the refusal is never retried") {
        var ran = 0

        val verdict =
            AttemptPolicy.RerunFailuresWrapper(4).attempt(quarantined = false) {
                ran++
                StandInGame().attempt.outcome {
                    probe.chat(player, "Hello")
                    player.capture("scene")
                }
            }

        val failed = verdict.shouldBeInstanceOf<Verdict.Failed>()
        ran shouldBe 1
        val refused = failed.failures.single().shouldBeInstanceOf<RequirementRefused>()
        refused.message shouldContain "made no positive check"
    }

    test("a window whose check held is a positive check: its body passes, and the same body without it is refused") {
        val hello = perception(0).copy(texts = listOf(text("chat", "Hello")), chat = listOf(chatLine(101, "Hello")))
        val game = StandInGame().apply { shows = hello }
        val unchecked = StandInGame().apply { shows = hello }

        val held =
            game.attempt.outcome {
                probe.chat(player, "Hello")
                within(5.ticks) { player sees chat("Hello") }
            }
        val stimulusOnly = unchecked.attempt.outcome { probe.chat(player, "Hello") }

        held shouldBe null
        stimulusOnly.shouldBeInstanceOf<RequirementRefused>()
    }

    test("a captured frame is evidence, never a check: it joins the screenshots, and a body that only captures is refused") {
        val game = StandInGame()

        val captured = game.attempt.outcome { player.capture("sidebar") }

        captured.shouldBeInstanceOf<RequirementRefused>()
        val evidence = game.attempt.evidence
        evidence.artifacts shouldBe listOf(Artifact(kind = ArtifactKind.SCREENSHOT, path = "sidebar.png"))
        evidence.file("sidebar.png").toFile().length() shouldBeGreaterThan 0L
    }

    test("a holds check of the test kit is a positive check: its body passes, and a body that only marks is refused") {
        val game = StandInGame().apply { marks = listOf(StateKind.EXPERIENCE) }
        val unchecked = StandInGame().apply { marks = listOf(StateKind.EXPERIENCE) }

        val held = game.attempt.outcome { holds(player, StateKind.EXPERIENCE) }
        val marked = unchecked.attempt.outcome { mark(player, StateKind.EXPERIENCE) }

        held shouldBe null
        marked.shouldBeInstanceOf<RequirementRefused>()
    }
}
