package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe

val RoutesTest by testSuite {
    test("an answer reaches the session that asked, under that session's own id, once") {
        val routes = Routes<String, Long>()
        val first = routes.route("module", 1)
        val second = routes.route("sibling", 1)

        first shouldNotBe second
        routes.answer(second).shouldNotBeNull().run {
            session shouldBe "sibling"
            id shouldBe 1L
        }
        routes.answer(second).shouldBeNull()
    }

    test("a session that left gets no answers to what it asked, and the others still do") {
        val routes = Routes<String, Long>()
        val dead = routes.route("module", 7)
        val alive = routes.route("sibling", 7)

        routes.leave("module")

        routes.answer(dead).shouldBeNull()
        routes.answer(alive).shouldNotBeNull().session shouldBe "sibling"
    }
}
