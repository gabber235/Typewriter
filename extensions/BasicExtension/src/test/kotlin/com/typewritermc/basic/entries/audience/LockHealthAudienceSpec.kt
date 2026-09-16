package com.typewritermc.basic.entries.audience

import com.typewritermc.engine.paper.entry.entries.ConstVar
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.shouldBe
import io.mockk.Runs
import io.mockk.every
import io.mockk.just
import io.mockk.mockk
import io.mockk.spyk
import io.mockk.verify
import org.bukkit.attribute.Attribute
import org.bukkit.attribute.AttributeInstance
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.entity.PlayerMock

/**
 * `AudienceDisplay.players` re-resolves every player from `server.getPlayer(uuid)` rather than
 * keeping the reference handed to `addPlayer`, so spying a `PlayerMock` in place leaves the
 * original, unspied instance registered with the server; `tick()` would then act on that instance
 * and every stub or verification on the spy would silently observe nothing. Swapping the server's
 * registration to the spy itself is what makes the assignment `tick()` performs observable.
 *
 * Spy the [player] only after its setup calls (like the starting health) have already landed on
 * the plain instance, otherwise mockk records that setup as a call and `verify(exactly = 0)`
 * assertions see it.
 */
private fun ServerMock.replaceWithSpy(player: PlayerMock): PlayerMock {
    val spy = spyk(player)
    playerList.disconnectPlayer(player)
    playerList.addPlayer(spy)
    return spy
}

/**
 * The specs call [LockHealthAudienceDisplay.applyHeldHealth] instead of `tick`, because `tick`
 * only schedules it onto the server main thread and MockBukkit has no dispatcher that runs that
 * hop.
 */
class LockHealthAudienceSpec : FunSpec() {
    private lateinit var server: ServerMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            startAudienceKoin()
        }

        afterSpec {
            stopAudienceKoin()
            MockBukkit.unmock()
        }

        test("a player in the audience is put back to the locked health") {
            val player = server.addPlayer()
            player.health = 4.0
            val display = LockHealthAudienceDisplay(ConstVar(15.0)).activeWith(player)

            display.applyHeldHealth()

            player.health shouldBe (15.0 plusOrMinus 1e-9)
        }

        test("a player outside the audience keeps their own health") {
            val member = server.addPlayer()
            val outsider = server.addPlayer()
            outsider.health = 4.0
            val display = LockHealthAudienceDisplay(ConstVar(15.0)).activeWith(member)

            display.applyHeldHealth()

            outsider.health shouldBe (4.0 plusOrMinus 1e-9)
        }

        // MockBukkit's own setHealth silently clamps to the entity's maximum, so a MockBukkit
        // player can't distinguish "our code clamped" from "MockBukkit clamped". Spying on a
        // MockBukkit player (so server.getPlayer still resolves it) and stubbing the health
        // setter to a no-op makes the exact value LockHealthAudienceDisplay assigns observable.
        test("a locked health above the player's maximum is assigned exactly the maximum, not the raw target") {
            val original = server.addPlayer()
            original.health = 4.0
            val player = server.replaceWithSpy(original)
            val maxHealth = mockk<AttributeInstance>()
            every { maxHealth.value } returns 20.0
            every { player.getAttribute(Attribute.MAX_HEALTH) } returns maxHealth
            every { player.health = any() } just Runs
            val display = LockHealthAudienceDisplay(ConstVar(1000.0)).activeWith(player)

            display.applyHeldHealth()

            verify(exactly = 1) { player.health = 20.0 }
        }

        test("a locked health below zero is assigned exactly zero, never negative") {
            val original = server.addPlayer()
            original.health = 4.0
            val player = server.replaceWithSpy(original)
            every { player.health = any() } just Runs
            val display = LockHealthAudienceDisplay(ConstVar(-5.0)).activeWith(player)

            display.applyHeldHealth()

            verify(exactly = 1) { player.health = 0.0 }
        }

        test("a player already at the locked health has its health setter never called") {
            val original = server.addPlayer()
            original.health = 15.0
            val player = server.replaceWithSpy(original)
            every { player.health = any() } just Runs
            val display = LockHealthAudienceDisplay(ConstVar(15.0)).activeWith(player)

            display.applyHeldHealth()

            verify(exactly = 0) { player.health = any() }
        }
    }
}
