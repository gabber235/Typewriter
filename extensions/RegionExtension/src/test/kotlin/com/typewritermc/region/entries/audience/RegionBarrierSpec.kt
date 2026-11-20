package com.typewritermc.region.entries.audience

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import com.typewritermc.region.content.RegionEditRegistry
import com.typewritermc.region.data.DistanceMode
import com.typewritermc.region.data.RegionDefinitionData
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.tracker.RegionTracker
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.shouldBeGreaterThan
import io.kotest.matchers.doubles.shouldBeLessThan
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import org.bukkit.Location
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock

/**
 * The barrier ramps its push across the last stretch on the side the player is allowed to be.
 * A region standing on the terrain has its floor face right where players stand, so the ramp
 * has to know the difference between somebody approaching a wall and somebody simply standing
 * on the ground inside.
 */
class RegionBarrierSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("barrier-world")
            startKoin {
                modules(
                    module {
                        single { mockk<PlayerSessionManager>(relaxed = true) }
                        single { RegionEditRegistry() }
                    },
                )
            }
        }

        afterSpec {
            stopKoin()
            MockBukkit.unmock()
        }

        // A room 20 by 20, four blocks tall, whose floor face sits at y = 60.
        val definition = RegionDefinitionData(
            origin = ConstVar(Position(World(""), 0.0, 62.0, 0.0)),
            shape = CuboidShape(10.0, 2.0, 10.0),
        )

        fun barrier(mode: BarrierMode) = RegionBarrierDisplay(
            region = RegionReferenceData(),
            mode = mode,
            strength = ConstVar(0.6),
            activationDistance = ConstVar(1.5),
            distanceMode = DistanceMode.FULL,
            entryId = null,
        )

        fun trackerIn(worldId: String): RegionTracker {
            val anchored = definition.copy(origin = ConstVar(Position(World(worldId), 0.0, 62.0, 0.0)))
            return RegionTracker(null, anchored).apply { refresh() }
        }

        test("a player standing on the floor of a KEEP_IN region is not pushed up") {
            val tracker = trackerIn(world.uid.toString())
            val player = server.addPlayer()
            player.teleport(Location(world, 0.0, 60.0, 0.0))
            player.isOnGround = true

            barrier(BarrierMode.KEEP_IN).pushFor(player, tracker) shouldBe null
        }

        test("a player standing a block above that floor is not pushed up either") {
            val tracker = trackerIn(world.uid.toString())
            val player = server.addPlayer()
            player.teleport(Location(world, 0.0, 61.0, 0.0))
            player.isOnGround = true

            barrier(BarrierMode.KEEP_IN).pushFor(player, tracker) shouldBe null
        }

        // A builder in creative flight is never on the ground, and bumping them upward every tick
        // they descend towards the arena floor is the same nuisance the ground test spares
        // everyone else.
        test("a builder flying over that floor is not pushed up either") {
            val tracker = trackerIn(world.uid.toString())
            val player = server.addPlayer()
            player.teleport(Location(world, 0.0, 61.0, 0.0))
            player.isOnGround = false
            player.allowFlight = true
            player.isFlying = true

            barrier(BarrierMode.KEEP_IN).pushFor(player, tracker) shouldBe null
        }

        // Nothing is holding a falling player up, so the ramp is the only thing between them and
        // the face they are heading for.
        test("a player falling towards the floor of a KEEP_IN region is still caught") {
            val tracker = trackerIn(world.uid.toString())
            val player = server.addPlayer()
            player.teleport(Location(world, 0.0, 61.0, 0.0))
            player.isOnGround = false

            val push = barrier(BarrierMode.KEEP_IN).pushFor(player, tracker).shouldNotBeNull()
            push.y shouldBeGreaterThan 0.0
        }

        test("a player dropping onto the roof of a KEEP_OUT region is pushed off it") {
            val tracker = trackerIn(world.uid.toString())
            val player = server.addPlayer()
            player.teleport(Location(world, 0.0, 65.0, 0.0))
            player.isOnGround = false

            val push = barrier(BarrierMode.KEEP_OUT).pushFor(player, tracker).shouldNotBeNull()
            push.y shouldBeGreaterThan 0.0
        }

        test("a player who left the region is still carried back in") {
            val tracker = trackerIn(world.uid.toString())
            val player = server.addPlayer()
            player.teleport(Location(world, 11.0, 62.0, 0.0))

            val push = barrier(BarrierMode.KEEP_IN).pushFor(player, tracker).shouldNotBeNull()
            push.x shouldBeLessThan 0.0
        }

        test("a player approaching a wall from inside is still pushed off it") {
            val tracker = trackerIn(world.uid.toString())
            val player = server.addPlayer()
            player.teleport(Location(world, 9.5, 62.0, 0.0))

            val push = barrier(BarrierMode.KEEP_IN).pushFor(player, tracker).shouldNotBeNull()
            push.x shouldBeLessThan 0.0
        }

        // The mirror of the arena floor: standing on the roof of a KEEP_OUT region is allowed,
        // and lifting those players off it every tick is the same defect on the other face.
        test("a KEEP_OUT barrier does not levitate someone standing on the region's roof") {
            val tracker = trackerIn(world.uid.toString())
            val player = server.addPlayer()
            player.teleport(Location(world, 0.0, 64.5, 0.0))
            player.isOnGround = true

            barrier(BarrierMode.KEEP_OUT).pushFor(player, tracker) shouldBe null
        }

        test("a KEEP_OUT barrier still carries someone who got inside back out") {
            val tracker = trackerIn(world.uid.toString())
            val player = server.addPlayer()
            player.teleport(Location(world, 9.0, 62.0, 0.0))

            val push = barrier(BarrierMode.KEEP_OUT).pushFor(player, tracker).shouldNotBeNull()
            push.x shouldBeGreaterThan 0.0
        }
    }
}
