package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain

val ClaimsTest by testSuite {
    val pool = listOf("gv-1", "gv-2", "gv-3", "gv-4")

    test("four single claims run at once and a fifth waits until a player is released") {
        val claims = Claims<String, String>(pool)
        (1L..5L).forEach { claims.submit("module", it, 1) }

        claims.grants().map { it.submission } shouldContainExactly listOf(1L, 2L, 3L, 4L)
        claims.grants().shouldBeEmpty()

        claims.release(listOf("gv-3"))
        claims.grants() shouldContainExactly listOf(Grant("module", 5L, listOf("gv-3")))
    }

    test("a group gets all its players together and never two attempts share a player") {
        val claims = Claims<String, String>(pool)
        claims.submit("module", 1, 3)
        claims.submit("module", 2, 1)
        claims.submit("module", 3, 1)

        val grants = claims.grants()

        grants.map { it.submission } shouldContainExactly listOf(1L, 2L)
        grants.first().players shouldHaveSize 3
        grants.flatMap { it.players }.distinct() shouldHaveSize 4
    }

    test("a group waiting at the head keeps freed players from the singles behind it") {
        val claims = Claims<String, String>(pool)
        (1L..4L).forEach { claims.submit("module", it, 1) }
        claims.grants()
        claims.submit("module", 5, 3)
        claims.submit("module", 6, 1)

        claims.release(listOf("gv-1"))
        claims.grants().shouldBeEmpty()
        claims.release(listOf("gv-2"))
        claims.grants().shouldBeEmpty()
        claims.release(listOf("gv-3"))

        claims.grants() shouldContainExactly listOf(Grant("module", 5L, listOf("gv-1", "gv-2", "gv-3")))
        claims.release(listOf("gv-4"))
        claims.grants() shouldContainExactly listOf(Grant("module", 6L, listOf("gv-4")))
    }

    test("a session that submits later gets the next free player before the earlier session's queue") {
        val claims = Claims<String, String>(pool)
        (1L..6L).forEach { claims.submit("module", it, 1) }
        claims.grants()
        claims.submit("ide", 100, 1)

        claims.release(listOf("gv-2"))

        claims.grants() shouldContainExactly listOf(Grant("ide", 100L, listOf("gv-2")))
    }

    test("sessions take turns while both have claims waiting") {
        val claims = Claims<String, String>(listOf("gv-1"))
        (1L..3L).forEach { claims.submit("first", it, 1) }
        (11L..13L).forEach { claims.submit("second", it, 1) }

        val order =
            (1..6).map {
                val grant = claims.grants().single()
                claims.release(grant.players)
                grant.submission
            }

        order shouldContainExactly listOf(1L, 11L, 2L, 12L, 3L, 13L)
    }

    test("a session that leaves takes its waiting claims with it") {
        val claims = Claims<String, String>(listOf("gv-1"))
        claims.submit("first", 1, 1)
        claims.submit("first", 2, 1)
        claims.submit("second", 11, 1)
        claims.grants()

        claims.leave("first")
        claims.release(listOf("gv-1"))

        claims.grants() shouldContainExactly listOf(Grant("second", 11L, listOf("gv-1")))
    }

    test("a claim for more players than the pool holds is refused with both numbers") {
        val claims = Claims<String, String>(listOf("gv-1"))

        val refused = shouldThrow<IllegalArgumentException> { claims.submit("module", 1, 3) }

        refused.message shouldContain "3 players"
        refused.message shouldContain "holds 1"
        claims.grants().shouldBeEmpty()
    }

    test("a claim for no players is refused") {
        val claims = Claims<String, String>(pool)

        shouldThrow<IllegalArgumentException> { claims.submit("module", 1, 0) }.message shouldContain "at least 1"
    }

    test("released players are free again in the pool's order") {
        val claims = Claims<String, String>(pool)
        claims.submit("module", 1, 4)
        claims.grants()

        claims.release(listOf("gv-4", "gv-2", "gv-1", "gv-3"))
        claims.submit("module", 2, 2)

        claims.grants().single().players shouldBe listOf("gv-1", "gv-2")
    }
}
