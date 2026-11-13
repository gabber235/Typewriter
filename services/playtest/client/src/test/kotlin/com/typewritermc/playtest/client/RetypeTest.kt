package com.typewritermc.playtest.client

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val RetypeTest by testSuite {
    test("an unanswered request is retyped on the sixth tick, not before") {
        val retype = Retype().apply { typed("/warp s") }

        (1..5).map { retype.afterTick("/warp s", true) } shouldBe List(5) { false }
        retype.afterTick("/warp s", true) shouldBe true
    }

    test("a request still unanswered after a retype is retyped again six ticks later") {
        val retype = Retype().apply { typed("/warp s") }
        repeat(6) { retype.afterTick("/warp s", true) }

        (1..5).map { retype.afterTick("/warp s", true) } shouldBe List(5) { false }
        retype.afterTick("/warp s", true) shouldBe true
    }

    test("an answer starts the patience again") {
        val retype = Retype().apply { typed("/warp s") }
        repeat(5) { retype.afterTick("/warp s", true) }
        retype.afterTick("/warp s", false) shouldBe false

        (1..5).map { retype.afterTick("/warp s", true) } shouldBe List(5) { false }
        retype.afterTick("/warp s", true) shouldBe true
    }

    test("an answered request is never retyped") {
        val retype = Retype().apply { typed("/warp s") }

        (1..20).map { retype.afterTick("/warp s", false) } shouldBe List(20) { false }
    }

    test("another edit or a closed chat ends the retype for good") {
        val edited = Retype().apply { typed("/warp s") }
        edited.afterTick("/warp sp", true) shouldBe false
        (1..10).map { edited.afterTick("/warp s", true) } shouldBe List(10) { false }

        val closed = Retype().apply { typed("/warp s") }
        closed.afterTick(null, true) shouldBe false
        (1..10).map { closed.afterTick("/warp s", true) } shouldBe List(10) { false }
    }

    test("nothing typed is never retyped") {
        val retype = Retype()

        (1..10).map { retype.afterTick("/warp s", true) } shouldBe List(10) { false }
    }
}
