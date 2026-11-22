package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.harness.v1.wire.StateKind

val ContentTest by testSuite {
    test("an attempt's content is live before its body runs, the body sees it, and its removal is live before the attempt ends") {
        val game = StandInGame().apply { marks = listOf(StateKind.EXPERIENCE) }
        val stand = StandInContent()

        val failure =
            game.attempt.outcome(listOf(stand)) {
                stand.events += "body sees ${content.single().live.present}"
                holds(player, StateKind.EXPERIENCE)
            }

        failure shouldBe null
        stand.events shouldBe
            listOf(
                "write for gv-1",
                "live on paper-1: present [book], absent []",
                "body sees [book]",
                "remove",
                "live on paper-1: present [], absent [book]",
            )
    }

    test("a body that fails still has its content removed, and fails for its own reason") {
        val content = StandInContent()

        val failure =
            StandInGame().attempt.outcome(listOf(content)) {
                content.events += "body"
                error("the body broke")
            }

        failure?.message shouldBe "the body broke"
        content.events.takeLast(2) shouldBe listOf("remove", "live on paper-1: present [], absent [book]")
    }

    test("content that never runs on Paper fails the attempt before its body, and is removed") {
        val content = StandInContent(neverLive = true)

        val failure = StandInGame().attempt.outcome(listOf(content)) { content.events += "body" }

        failure.shouldBeInstanceOf<IllegalStateException>().message shouldContain "never ran"
        content.events shouldBe
            listOf(
                "write for gv-1",
                "live on paper-1: present [book], absent []",
                "remove",
                "live on paper-1: present [], absent [book]",
            )
    }

    test("a body's change to its content is live on Paper before the body goes on") {
        val game = StandInGame().apply { marks = listOf(StateKind.EXPERIENCE) }
        val stand = StandInContent()

        val failure =
            game.attempt.outcome(listOf(stand)) {
                content.single().change()
                stand.events += "body goes on"
                holds(player, StateKind.EXPERIENCE)
            }

        failure shouldBe null
        stand.events.drop(2).take(3) shouldBe listOf("change", "live on paper-1: present [changed book], absent [book]", "body goes on")
    }

    test("content whose removal fails fails an attempt whose body passed") {
        val game = StandInGame().apply { marks = listOf(StateKind.EXPERIENCE) }

        val failure = game.attempt.outcome(listOf(StandInContent(removalFails = true))) { holds(player, StateKind.EXPERIENCE) }

        failure.shouldBeInstanceOf<IllegalStateException>().message shouldContain "could not be removed"
    }

    test("content is live once the Paper's engine applies every id it adds and none it removes") {
        val game = StandInGame().apply { applied = listOf(setOf("old"), setOf("old", "book"), setOf("book")) }

        game.attempt.contentPaper.awaitApplied(LiveContent(present = setOf("book"), absent = setOf("old")))

        game.appliedAsks shouldBe 3
    }

    test("content the Paper's engine never applies fails naming what is still missing and what is still applied") {
        val game = StandInGame().apply { applied = listOf(setOf("old", "other")) }

        val failure =
            shouldThrow<IllegalStateException> {
                game.attempt.contentPaper.awaitApplied(LiveContent(present = setOf("book"), absent = setOf("old")))
            }

        failure.message shouldBe "paper-1 still does not apply [book] and still applies [old] after 1m"
    }

    test("content waits until the Paper's engine runs the publication the selection names, asking both again each time") {
        val game = StandInGame().apply { publications = listOf(null, "old", "newer") }
        val selected = mutableListOf("mine", "newer", "newer")

        game.attempt.contentPaper.awaitPublication { selected.removeFirst() }

        game.appliedAsks shouldBe 3
    }

    test("a Paper whose engine never runs the selected publication fails naming the one it runs") {
        val game = StandInGame().apply { publications = listOf("old") }

        val failure = shouldThrow<IllegalStateException> { game.attempt.contentPaper.awaitPublication { "mine" } }

        failure.message shouldBe "paper-1 still applies publication old, not the selected mine, after 1m"
    }

    test("a Paper whose engine reports nothing fails the wait with Paper's reason") {
        val game = StandInGame().apply { appliedFailure = "no engine reports what it applies" }

        val failure = shouldThrow<ProbeFailed> { game.attempt.contentPaper.awaitApplied(LiveContent(present = setOf("book"))) }

        failure.message shouldBe "no engine reports what it applies"
    }
}
