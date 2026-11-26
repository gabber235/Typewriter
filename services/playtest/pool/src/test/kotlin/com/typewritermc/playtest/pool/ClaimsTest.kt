package com.typewritermc.playtest.pool

import com.typewritermc.playtest.launch.PartLimit
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
        (1L..5L).forEach { claims.submit("module", Claim(it, 1)) }

        claims.grants().map { it.submission } shouldContainExactly listOf(1L, 2L, 3L, 4L)
        claims.grants().shouldBeEmpty()

        claims.release(listOf("gv-3"))
        claims.grants() shouldContainExactly listOf(Grant("module", 5L, listOf("gv-3")))
    }

    test("a group gets all its players together and never two attempts share a player") {
        val claims = Claims<String, String>(pool)
        claims.submit("module", Claim(1L, 3))
        claims.submit("module", Claim(2L, 1))
        claims.submit("module", Claim(3L, 1))

        val grants = claims.grants()

        grants.map { it.submission } shouldContainExactly listOf(1L, 2L)
        grants.first().players shouldHaveSize 3
        grants.flatMap { it.players }.distinct() shouldHaveSize 4
    }

    test("a group waiting at the head keeps freed players from the singles behind it") {
        val claims = Claims<String, String>(pool)
        (1L..4L).forEach { claims.submit("module", Claim(it, 1)) }
        claims.grants()
        claims.submit("module", Claim(5L, 3))
        claims.submit("module", Claim(6L, 1))

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
        (1L..6L).forEach { claims.submit("module", Claim(it, 1)) }
        claims.grants()
        claims.submit("ide", Claim(100L, 1))

        claims.release(listOf("gv-2"))

        claims.grants() shouldContainExactly listOf(Grant("ide", 100L, listOf("gv-2")))
    }

    test("sessions take turns while both have claims waiting") {
        val claims = Claims<String, String>(listOf("gv-1"))
        (1L..3L).forEach { claims.submit("first", Claim(it, 1)) }
        (11L..13L).forEach { claims.submit("second", Claim(it, 1)) }

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
        claims.submit("first", Claim(1L, 1))
        claims.submit("first", Claim(2L, 1))
        claims.submit("second", Claim(11L, 1))
        claims.grants()

        claims.leave("first")
        claims.release(listOf("gv-1"))

        claims.grants() shouldContainExactly listOf(Grant("second", 11L, listOf("gv-1")))
    }

    test("a claim for more players than the pool holds is refused with both numbers") {
        val claims = Claims<String, String>(listOf("gv-1"))

        val refused = shouldThrow<IllegalArgumentException> { claims.submit("module", Claim(1L, 3)) }

        refused.message shouldContain "3 players"
        refused.message shouldContain "holds 1"
        claims.grants().shouldBeEmpty()
    }

    test("a claim for no players is refused") {
        val claims = Claims<String, String>(pool)

        shouldThrow<IllegalArgumentException> { claims.submit("module", Claim(1L, 0)) }.message shouldContain "at least 1"
    }

    test("released players are free again in the pool's order") {
        val claims = Claims<String, String>(pool)
        claims.submit("module", Claim(1L, 4))
        claims.grants()

        claims.release(listOf("gv-4", "gv-2", "gv-1", "gv-3"))
        claims.submit("module", Claim(2L, 2))

        claims.grants().single().players shouldBe listOf("gv-1", "gv-2")
    }

    test("a player whose client is lost goes to no claim, not even once its attempt ends, until its new client is ready") {
        val claims = Claims<String, String>(listOf("gv-1", "gv-2"))
        claims.submit("module", Claim(1L, 1))
        claims.grants()

        claims.holdOut("gv-1", Out.LOST_CLIENT)
        claims.release(listOf("gv-1"))
        claims.submit("module", Claim(2L, 1))
        claims.submit("module", Claim(3L, 1))

        claims.grants() shouldContainExactly listOf(Grant("module", 2L, listOf("gv-2")))
        claims.letBack("gv-1", Out.LOST_CLIENT)
        claims.grants() shouldContainExactly listOf(Grant("module", 3L, listOf("gv-1")))
    }

    test("a group that needs a lost player's place waits for its new client") {
        val claims = Claims<String, String>(pool)
        claims.holdOut("gv-3", Out.LOST_CLIENT)
        claims.submit("module", Claim(1L, 4))

        claims.grants().shouldBeEmpty()
        claims.letBack("gv-3", Out.LOST_CLIENT)

        claims.grants().single().players shouldBe pool
    }

    test("side by side attempts get their players at the same moment, never one before the other") {
        val claims = Claims<String, String>(pool)
        (1L..3L).forEach { claims.submit("module", Claim(it, 1)) }
        claims.grants()
        claims.submit("module", Claim(4L, 1), Claim(5L, 1))

        claims.grants().shouldBeEmpty()
        claims.release(listOf("gv-2"))

        claims.grants() shouldContainExactly listOf(Grant("module", 4L, listOf("gv-2")), Grant("module", 5L, listOf("gv-4")))
    }

    test("a player held out for two reasons goes to no claim until both let it back") {
        val claims = Claims<String, String>(listOf("gv-1"))
        claims.holdOut("gv-1", Out.LOST_CLIENT)
        claims.holdOut("gv-1", Out.HUNG_WORK)
        claims.submit("module", Claim(1L, 1))

        claims.letBack("gv-1", Out.LOST_CLIENT)
        claims.grants().shouldBeEmpty()
        claims.letBack("gv-1", Out.HUNG_WORK)

        claims.grants() shouldContainExactly listOf(Grant("module", 1L, listOf("gv-1")))
    }

    test("a player let back while its attempt still runs goes to no other claim until that attempt ends") {
        val claims = Claims<String, String>(listOf("gv-1"))
        claims.submit("module", Claim(1L, 1))
        claims.grants()

        claims.holdOut("gv-1", Out.LOST_CLIENT)
        claims.letBack("gv-1", Out.LOST_CLIENT)
        claims.submit("module", Claim(2L, 1))

        claims.grants().shouldBeEmpty()
        claims.release(listOf("gv-1"))
        claims.grants() shouldContainExactly listOf(Grant("module", 2L, listOf("gv-1")))
    }

    test("a third restart attempt waits while two own Papers have not fully exited, and is claimed once one is gone") {
        val claims = Claims<String, String>(pool)
        (1L..3L).forEach { claims.submit("module", Claim(it, 1, restarts = true)) }

        claims.grants().map { it.submission } shouldContainExactly listOf(1L, 2L)
        claims.release(listOf("gv-1"))
        claims.grants().shouldBeEmpty()
        claims.ownPaperGone()
        claims.grants() shouldContainExactly listOf(Grant("module", 3L, listOf("gv-1")))
    }

    test("an own Paper that does not fit in what is left of the budget waits until another one ends, then is claimed to boot") {
        val ownPaper = PartLimit.OWN_PAPER.limitBytes
        val claims = Claims<String, String>(pool, OwnPaperRoom(leftBytes = ownPaper * 3 / 2, slots = 2))
        claims.submit("module", Claim(1L, 1, restarts = true))
        claims.submit("module", Claim(2L, 1, restarts = true))

        claims.grants().map { it.submission } shouldContainExactly listOf(1L)
        // The attempt ended, but its own Paper still takes its memory while it stops.
        claims.release(listOf("gv-1"))
        claims.grants().shouldBeEmpty()
        claims.ownPaperGone()
        claims.grants() shouldContainExactly listOf(Grant("module", 2L, listOf("gv-1")))
    }

    test("attempts side by side that need more own Papers than the budget holds at once are refused with both numbers") {
        val claims = Claims<String, String>(pool, OwnPaperRoom(leftBytes = PartLimit.OWN_PAPER.limitBytes, slots = 2))

        val refused =
            shouldThrow<IllegalArgumentException> {
                claims.submit("module", *(1L..2L).map { Claim(it, 1, restarts = true) }.toTypedArray())
            }

        refused.message shouldContain "2 Papers of their own"
        refused.message shouldContain "at most 1"
    }

    test("attempts side by side that need more own Papers than may run at once are refused with both numbers") {
        val claims = Claims<String, String>(pool)

        val refused =
            shouldThrow<IllegalArgumentException> {
                claims.submit("module", *(1L..3L).map { Claim(it, 1, restarts = true) }.toTypedArray())
            }

        refused.message shouldContain "3 Papers of their own"
        refused.message shouldContain "at most 2"
    }

    test("the shared Paper runs one pace at a time: a claim at another pace waits until none at the current pace runs or waits") {
        val claims = Claims<String, String>(pool)
        claims.submit("module", Claim(1L, 1))
        claims.submit("module", Claim(2L, 1, pace = 50))
        claims.submit("module", Claim(3L, 1))

        claims.grants().map { it.submission } shouldContainExactly listOf(1L, 3L)

        claims.release(listOf("gv-1"))
        claims.grants().shouldBeEmpty()

        claims.release(listOf("gv-2"))
        claims.grants() shouldContainExactly listOf(Grant("module", 2L, listOf("gv-1")))
    }

    test("a restart attempt runs at its own pace on its own Paper, beside the shared Paper's attempts at theirs") {
        val claims = Claims<String, String>(pool)
        claims.submit("module", Claim(1L, 1))
        claims.submit("module", Claim(2L, 1, restarts = true, pace = 50))

        claims.grants().map { it.submission } shouldContainExactly listOf(1L, 2L)
    }
}
