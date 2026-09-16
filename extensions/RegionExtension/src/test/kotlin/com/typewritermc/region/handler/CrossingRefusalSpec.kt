package com.typewritermc.region.handler

import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import com.typewritermc.region.data.CrossingCause
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module

/**
 * A cancelled crossing is rolled back by the engine, so the next move presents the same
 * crossing again. Without a memory of the refusal the entry fires its whole trigger pipeline
 * every tick a player leans on the boundary.
 */
class CrossingRefusalSpec : FunSpec() {
    private lateinit var server: ServerMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            server.addSimpleWorld("refusal-world")
            startKoin {
                modules(module { single { mockk<PlayerSessionManager>(relaxed = true) } })
            }
        }

        afterSpec {
            stopKoin()
            MockBukkit.unmock()
        }


        /**
         * The move event the engine hands a handler for a walked crossing. A refusal only means
         * anything when there is an event to cancel, so the specs that exercise one pass a real
         * one; the specs about a crossing that stands pass `null`, like the vehicle path does.
         */
        fun walk(player: org.bukkit.entity.Player): org.bukkit.event.player.PlayerMoveEvent =
            org.bukkit.event.player.PlayerMoveEvent(player, player.location, player.location)

        test("a refused enter fires once, however many times the crossing is retried") {
            val player = server.addPlayer()
            var fires = 0
            val handler = EnterExitHandler(owner = "test", onEnter = { _, _, _ -> fires++; true })

            repeat(5) {
                handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
                // What the engine does after cancelling: roll the membership back to the outside.
                handler.resync(player, 1.0)
                handler.refuse(player)
            }

            fires shouldBe 1
        }

        test("a handler that never asked to cancel does not start blocking moves") {
            val player = server.addPlayer()
            var fires = 0
            val handler = EnterExitHandler(owner = "test", onEnter = { _, _, _ -> fires++; false })

            // The engine refuses every handler it touched, including the ones that let the
            // crossing through, because the cancellation rolled all of them back.
            handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            handler.resync(player, 1.0)
            handler.refuse(player)

            handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            fires shouldBe 1
        }

        test("a refusal is lifted once the engine reports the move landed") {
            val player = server.addPlayer()
            var fires = 0
            val handler = EnterExitHandler(owner = "test", onEnter = { _, _, _ -> fires++; false })

            handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, walk(player))
            handler.resync(player, 1.0)
            handler.refuse(player)
            handler.clearRefusal(player)

            handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            fires shouldBe 2
        }

        test("an engulf landing between a dispatch and its resync does not lose the refusal") {
            val player = server.addPlayer()
            var fires = 0
            val handler = EnterExitHandler(owner = "test", onEnter = { _, _, _ -> fires++; false })

            handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            // The async reconcile classifies the same player before the engine rolls the move back.
            handler.onClassification(player, -1.0, CrossingCause.ENGULFED, null) shouldBe false
            handler.refuse(player)
            handler.resync(player, 1.0)

            handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            fires shouldBe 1
        }

        test("a region engulfing a refused player still fires, since nothing can roll that back") {
            val player = server.addPlayer()
            var fires = 0
            val handler = EnterExitHandler(owner = "test", onEnter = { _, _, _ -> fires++; true })

            handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            handler.resync(player, 1.0)
            handler.refuse(player)

            handler.onClassification(player, -1.0, CrossingCause.ENGULFED, null)
            fires shouldBe 2
            handler.tracks(player) shouldBe true
        }

        test("moving clear of the boundary arms the enter again") {
            val player = server.addPlayer()
            var fires = 0
            val handler = EnterExitHandler(owner = "test", onEnter = { _, _, _ -> fires++; true })

            handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, walk(player))
            handler.resync(player, 1.0)
            handler.refuse(player)

            handler.onClassification(player, 4.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true

            fires shouldBe 2
        }

        test("two classifications of the same crossing only fire once") {
            val player = server.addPlayer()
            var enters = 0
            var leaves = 0
            val handler = EnterExitHandler(
                owner = "test",
                onEnter = { _, _, _ -> enters++; false },
                onLeave = { _, _, _ -> leaves++; false },
            )

            // The move listener and the async reconcile can classify the same player at once.
            handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, null)
            handler.onClassification(player, -1.0, CrossingCause.ENGULFED, null)
            handler.onClassification(player, 1.0, CrossingCause.PLAYER_MOVED, null)
            handler.onClassification(player, 1.0, CrossingCause.ENGULFED, null)

            enters shouldBe 1
            leaves shouldBe 1
        }

        // The engine resyncs a cancelled crossing against the position the player is left at,
        // which is the one they crossed from. With a boundary inset that position sits inside
        // the hysteresis band, so the side the handler thinks they were on decides whether the
        // refusal still holds on their next step.
        test("a refused enter still holds when the region has a boundary inset") {
            val player = server.addPlayer()
            var fires = 0
            val handler = EnterExitHandler(
                owner = "test",
                boundaryInset = ConstVar(0.5),
                onEnter = { _, _, _ -> fires++; true },
            )

            // Walking in from just outside: refused, and rolled back to where they came from.
            handler.onClassification(player, -0.1, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            handler.resync(player, 0.2)
            handler.refuse(player)
            handler.tracks(player) shouldBe false

            // The same step again, and every step after it.
            handler.onClassification(player, -0.1, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            handler.onClassification(player, -0.4, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            fires shouldBe 1
            handler.tracks(player) shouldBe false
        }

        test("a refused exit still holds when the region has a boundary inset") {
            val player = server.addPlayer()
            var fires = 0
            val handler = EnterExitHandler(
                owner = "test",
                boundaryInset = ConstVar(0.5),
                onLeave = { _, _, _ -> fires++; true },
            )

            handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            handler.tracks(player) shouldBe true

            // Stepping past the inset: refused, and rolled back into the band they came from.
            handler.onClassification(player, 0.6, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            handler.resync(player, 0.5)
            handler.refuse(player)
            handler.tracks(player) shouldBe true

            handler.onClassification(player, 0.6, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            handler.onClassification(player, 0.9, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            fires shouldBe 1
            handler.tracks(player) shouldBe true
        }

        // The engine only dispatches when the player's block changes, but membership goes by
        // their whole body, so the position a cancelled move is rolled back to is usually one
        // the region already counts as inside. The refusal has to hold there anyway.
        test("a refused enter holds when the player is rolled back to a spot the region counts as inside") {
            val player = server.addPlayer()
            var fires = 0
            val handler = EnterExitHandler(owner = "test", onEnter = { _, _, _ -> fires++; true })

            // Their body reaches into the region a fraction before their feet do.
            handler.onClassification(player, -0.35, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            handler.resync(player, -0.05)
            handler.refuse(player)
            handler.tracks(player) shouldBe false

            // Pushing on, tick after tick, from that same spot.
            handler.onClassification(player, -0.35, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            handler.onClassification(player, -0.35, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            fires shouldBe 1
            handler.tracks(player) shouldBe false
        }

        test("backing off the boundary arms the refused enter again and fires no leave") {
            val player = server.addPlayer()
            var enters = 0
            var leaves = 0
            val handler = EnterExitHandler(
                owner = "test",
                onEnter = { _, _, _ -> enters++; true },
                onLeave = { _, _, _ -> leaves++; false },
            )

            handler.onClassification(player, -0.35, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            handler.resync(player, -0.05)
            handler.refuse(player)

            // Walking away: no exit for a crossing that was refused, and no cancel either.
            handler.onClassification(player, 2.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            leaves shouldBe 0

            handler.onClassification(player, -0.35, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            enters shouldBe 2
        }

        // The engine refuses every handler on every tracker it touched during a cancelled move,
        // including the ones that were nowhere near a boundary of their own.
        test("a handler that did not cross is not held to the refusal of one that did") {
            val player = server.addPlayer()
            var leaves = 0
            val town = EnterExitHandler(owner = "test", onLeave = { _, _, _ -> leaves++; false })

            // The player is a member of the town, and stays one while a vault inside it refuses.
            town.onClassification(player, -5.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            town.onClassification(player, -4.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            town.resync(player, -4.0)
            town.refuse(player)

            // Later they walk out of the town for real.
            town.onClassification(player, 1.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            leaves shouldBe 1
            town.tracks(player) shouldBe false
        }

        // The reconcile of a moving region runs off the main thread, so an engulf can land in the
        // middle of a refused move. It fires, because nothing rolls an engulf back, and the player
        // is inside for real once it has: the crossing they were refused has happened to them.
        test("an engulf that reaches a refused player takes the crossing over") {
            val player = server.addPlayer()
            var enters = 0
            var leaves = 0
            val handler = EnterExitHandler(
                owner = "test",
                onEnter = { _, _, _ -> enters++; true },
                onLeave = { _, _, _ -> leaves++; false },
            )

            handler.onClassification(player, -0.35, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            // The region catches up with them before the engine has rolled the move back.
            handler.onClassification(player, -0.35, CrossingCause.ENGULFED, null)
            handler.resync(player, -0.05)
            handler.refuse(player)
            enters shouldBe 2
            handler.tracks(player) shouldBe true

            // Still held to the refusal, every move from inside would be cancelled and the player
            // could never walk back out of the region that engulfed them.
            handler.onClassification(player, -0.35, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            handler.onClassification(player, 1.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            leaves shouldBe 1
            handler.tracks(player) shouldBe false
        }

        // The engulf that changes nothing is the other half of it: the region shifting under a
        // player who is still standing where the rollback left them settles nothing at all.
        test("an engulf that carries nobody across leaves the refusal in place") {
            val player = server.addPlayer()
            var fires = 0
            val handler = EnterExitHandler(owner = "test", onEnter = { _, _, _ -> fires++; true })

            handler.onClassification(player, -0.35, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            handler.resync(player, -0.05)
            handler.refuse(player)

            handler.onClassification(player, 0.5, CrossingCause.ENGULFED, null) shouldBe false

            handler.onClassification(player, -0.35, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
            fires shouldBe 1
        }

        // A vehicle's movement cannot be refused, so a crossing on a horse stands whatever the
        // entry answered, and the membership has to stand with it.
        test("a cancelling enter with no event to cancel keeps the player a member") {
            val player = server.addPlayer()
            var enters = 0
            var leaves = 0
            val handler = EnterExitHandler(
                owner = "test",
                onEnter = { _, _, _ -> enters++; true },
                onLeave = { _, _, _ -> leaves++; false },
            )

            handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, null)
            handler.tracks(player) shouldBe true

            handler.onClassification(player, 1.0, CrossingCause.PLAYER_MOVED, null)
            enters shouldBe 1
            leaves shouldBe 1
            handler.tracks(player) shouldBe false
        }

        // A crossing nothing can roll back is not a refusal, so it must not answer for the next
        // move the player makes.
        test("an engulfing enter that asked to cancel does not block the next walk out") {
            val player = server.addPlayer()
            var leaves = 0
            val handler = EnterExitHandler(
                owner = "test",
                onEnter = { _, _, _ -> true },
                onLeave = { _, _, _ -> leaves++; false },
            )

            handler.onClassification(player, -1.0, CrossingCause.ENGULFED, null)
            handler.tracks(player) shouldBe true

            handler.onClassification(player, 1.0, CrossingCause.PLAYER_MOVED, null) shouldBe false
            leaves shouldBe 1
            handler.tracks(player) shouldBe false
        }

        // An audience filter pushes its state from the callback, so the rollback has to reach it:
        // the enter it already answered is being taken back, and the player is left standing on the
        // side they came from, where no later crossing would correct it.
        test("a rolled back crossing reports the membership it was put back to") {
            val player = server.addPlayer()
            val reported = mutableListOf<Boolean>()
            val handler = EnterExitHandler(
                owner = "test",
                onEnter = { _, _, _ -> false },
                onResync = { _, member -> reported += member },
            )

            handler.onClassification(player, -1.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe false
            handler.resync(player, 1.0)
            handler.refuse(player)
            reported shouldBe listOf(false)

            // A resync that settles on the membership the handler already holds says nothing.
            handler.resync(player, 1.0)
            reported shouldBe listOf(false)
        }

        test("a refused proximity band behaves the same way") {
            val player = server.addPlayer()
            var fires = 0
            val handler = ProximityHandler(
                owner = "test",
                distance = ConstVar(5.0),
                onEnterBand = { _, _, _ -> fires++; true },
            )

            repeat(4) {
                handler.onClassification(player, 2.0, CrossingCause.PLAYER_MOVED, walk(player)) shouldBe true
                handler.resync(player, 40.0)
                handler.refuse(player)
            }

            fires shouldBe 1
        }
    }
}
