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
        (1L..5L).forEach { claims.submit("module", it to 1) }

        claims.grants().map { it.submission } shouldContainExactly listOf(1L, 2L, 3L, 4L)
        claims.grants().shouldBeEmpty()

        claims.release(listOf("gv-3"))
        claims.grants() shouldContainExactly listOf(Grant("module", 5L, listOf("gv-3")))
    }

    test("a group gets all its players together and never two attempts share a player") {
        val claims = Claims<String, String>(pool)
        claims.submit("module", 1L to 3)
        claims.submit("module", 2L to 1)
        claims.submit("module", 3L to 1)

        val grants = claims.grants()

        grants.map { it.submission } shouldContainExactly listOf(1L, 2L)
        grants.first().players shouldHaveSize 3
        grants.flatMap { it.players }.distinct() shouldHaveSize 4
    }

    test("a group waiting at the head keeps freed players from the singles behind it") {
        val claims = Claims<String, String>(pool)
        (1L..4L).forEach { claims.submit("module", it to 1) }
        claims.grants()
        claims.submit("module", 5L to 3)
        claims.submit("module", 6L to 1)

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
        (1L..6L).forEach { claims.submit("module", it to 1) }
        claims.grants()
        claims.submit("ide", 100L to 1)

        claims.release(listOf("gv-2"))

        claims.grants() shouldContainExactly listOf(Grant("ide", 100L, listOf("gv-2")))
    }

    test("sessions take turns while both have claims waiting") {
        val claims = Claims<String, String>(listOf("gv-1"))
        (1L..3L).forEach { claims.submit("first", it to 1) }
        (11L..13L).forEach { claims.submit("second", it to 1) }

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
        claims.submit("first", 1L to 1)
        claims.submit("first", 2L to 1)
        claims.submit("second", 11L to 1)
        claims.grants()

        claims.leave("first")
        claims.release(listOf("gv-1"))

        claims.grants() shouldContainExactly listOf(Grant("second", 11L, listOf("gv-1")))
    }

    test("a claim for more players than the pool holds is refused with both numbers") {
        val claims = Claims<String, String>(listOf("gv-1"))

        val refused = shouldThrow<IllegalArgumentException> { claims.submit("module", 1L to 3) }

        refused.message shouldContain "3 players"
        refused.message shouldContain "holds 1"
        claims.grants().shouldBeEmpty()
    }

    test("a claim for no players is refused") {
        val claims = Claims<String, String>(pool)

        shouldThrow<IllegalArgumentException> { claims.submit("module", 1L to 0) }.message shouldContain "at least 1"
    }

    test("released players are free again in the pool's order") {
        val claims = Claims<String, String>(pool)
        claims.submit("module", 1L to 4)
        claims.grants()

        claims.release(listOf("gv-4", "gv-2", "gv-1", "gv-3"))
        claims.submit("module", 2L to 2)

        claims.grants().single().players shouldBe listOf("gv-1", "gv-2")
    }

    test("a player whose client is lost goes to no claim, not even once its attempt ends, until its new client is ready") {
        val claims = Claims<String, String>(listOf("gv-1", "gv-2"))
        claims.submit("module", 1L to 1)
        claims.grants()

        claims.holdOut("gv-1", Out.LOST_CLIENT)
        claims.release(listOf("gv-1"))
        claims.submit("module", 2L to 1)
        claims.submit("module", 3L to 1)

        claims.grants() shouldContainExactly listOf(Grant("module", 2L, listOf("gv-2")))
        claims.letBack("gv-1", Out.LOST_CLIENT)
        claims.grants() shouldContainExactly listOf(Grant("module", 3L, listOf("gv-1")))
    }

    test("a group that needs a lost player's place waits for its new client") {
        val claims = Claims<String, String>(pool)
        claims.holdOut("gv-3", Out.LOST_CLIENT)
        claims.submit("module", 1L to 4)

        claims.grants().shouldBeEmpty()
        claims.letBack("gv-3", Out.LOST_CLIENT)

        claims.grants().single().players shouldBe pool
    }

    test("side by side attempts get their players at the same moment, never one before the other") {
        val claims = Claims<String, String>(pool)
        (1L..3L).forEach { claims.submit("module", it to 1) }
        claims.grants()
        claims.submit("module", 4L to 1, 5L to 1)

        claims.grants().shouldBeEmpty()
        claims.release(listOf("gv-2"))

        claims.grants() shouldContainExactly listOf(Grant("module", 4L, listOf("gv-2")), Grant("module", 5L, listOf("gv-4")))
    }

    test("a player held out for two reasons goes to no claim until both let it back") {
        val claims = Claims<String, String>(listOf("gv-1"))
        claims.holdOut("gv-1", Out.LOST_CLIENT)
        claims.holdOut("gv-1", Out.HUNG_WORK)
        claims.submit("module", 1L to 1)

        claims.letBack("gv-1", Out.LOST_CLIENT)
        claims.grants().shouldBeEmpty()
        claims.letBack("gv-1", Out.HUNG_WORK)

        claims.grants() shouldContainExactly listOf(Grant("module", 1L, listOf("gv-1")))
    }

    test("a player let back while its attempt still runs goes to no other claim until that attempt ends") {
        val claims = Claims<String, String>(listOf("gv-1"))
        claims.submit("module", 1L to 1)
        claims.grants()

        claims.holdOut("gv-1", Out.LOST_CLIENT)
        claims.letBack("gv-1", Out.LOST_CLIENT)
        claims.submit("module", 2L to 1)

        claims.grants().shouldBeEmpty()
        claims.release(listOf("gv-1"))
        claims.grants() shouldContainExactly listOf(Grant("module", 2L, listOf("gv-1")))
    }
}
