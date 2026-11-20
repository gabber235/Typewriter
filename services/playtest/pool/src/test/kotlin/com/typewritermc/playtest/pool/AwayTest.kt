package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val AwayTest by testSuite {
    test("a quitting player's leave seen on the Paper the pool moved it off answers no quit, its leave from its own Paper does") {
        val quitting = Away.Leaving(request = 7)

        quitting.left(onItsPaper = false) shouldBe Away.Left.Moved
        quitting.left(onItsPaper = true) shouldBe Away.Left.QuitDone(7)
    }

    test("a player rejoining its Paper that is seen leaving it is lost; seen leaving the Paper it quit from it is not") {
        val joining = Away.Joining(request = 8)

        joining.left(onItsPaper = false) shouldBe Away.Left.Moved
        joining.left(onItsPaper = true) shouldBe Away.Left.Lost
    }

    test("a player whose attempt ended while it left comes back once its Paper saw it go") {
        Away.Leaving(request = null).left(onItsPaper = true) shouldBe Away.Left.ComeBack
    }
}
