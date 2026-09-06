package com.typewritermc.region

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entries.ComputeVar
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import com.typewritermc.region.data.CrossingCause
import com.typewritermc.region.data.DistanceMode
import com.typewritermc.region.data.RegionDefinitionData
import com.typewritermc.region.handler.EnterExitHandler
import com.typewritermc.region.handler.ProximityHandler
import com.typewritermc.region.shape.ConeShape
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.SphereShape
import com.typewritermc.engine.paper.utils.toPosition
import io.kotest.assertions.withClue
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.mockk.mockk
import org.bukkit.Location
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.HandlerList
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerJoinEvent
import org.bukkit.event.player.PlayerMoveEvent
import org.bukkit.event.player.PlayerTeleportEvent
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock

class RegionEngineSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock

    private fun position(x: Double, y: Double, z: Double) =
        Position(World(world.uid.toString()), x, y, z, 0f, 0f)

    private fun location(x: Double, y: Double, z: Double) = Location(world, x, y, z)

    private fun move(engine: RegionEngine, player: Player, to: Location): PlayerMoveEvent {
        val from = player.location
        player.teleport(to)
        val event = PlayerMoveEvent(player, from, to)
        engine.onMove(event)
        return event
    }

    init {
        beforeSpec {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("region-world")
            startKoin {
                modules(module { single { mockk<PlayerSessionManager>(relaxed = true) } })
            }
        }

        afterSpec {
            stopKoin()
            MockBukkit.unmock()
        }

        test("a player brushing a cone apex counts as inside") {
            val engine = RegionEngine()
            val player = server.addPlayer()
            player.teleport(location(90.0, 64.0, 90.0))

            val region = RegionDefinitionData(
                origin = ConstVar(position(100.0, 64.9, 100.0)),
                shape = ConeShape(length = 8.0, halfAngleDegrees = 30.0),
            )
            val enters = mutableListOf<CrossingCause>()
            val handler = EnterExitHandler(
                owner = "test",
                onEnter = { _, cause, _ -> enters.add(cause); false },
            )
            val subscription = engine.observe(region, null, handler)!!

            subscription.tracker.isInside(position(100.0, 64.0, 100.0)) shouldBe false
            subscription.tracker.isInside(player) shouldBe false

            move(engine, player, location(100.0, 64.0, 100.0))
            enters shouldBe listOf(CrossingCause.PLAYER_MOVED)
            subscription.tracker.isInside(player) shouldBe true

            subscription.cancel()
        }

        test("boundary inset keeps a member while skimming the boundary") {
            val engine = RegionEngine()
            val player = server.addPlayer()
            player.teleport(location(93.0, 61.0, 100.0))

            val region = RegionDefinitionData(
                origin = ConstVar(position(100.0, 64.0, 100.0)),
                shape = CuboidShape(5.0, 5.0, 5.0),
            )
            val events = mutableListOf<String>()
            val handler = EnterExitHandler(
                owner = "test",
                boundaryInset = ConstVar(0.5),
                onEnter = { _, _, _ -> events.add("enter"); false },
                onLeave = { _, _, _ -> events.add("leave"); false },
            )
            val subscription = engine.observe(region, null, handler)!!

            move(engine, player, location(94.8, 61.0, 100.0))
            events shouldBe listOf("enter")

            move(engine, player, location(94.5, 61.0, 100.0))
            events shouldBe listOf("enter")

            move(engine, player, location(94.8, 61.0, 100.0))
            events shouldBe listOf("enter")

            move(engine, player, location(93.5, 61.0, 100.0))
            events shouldBe listOf("enter", "leave")

            move(engine, player, location(94.5, 61.0, 100.0))
            events shouldBe listOf("enter", "leave")

            subscription.cancel()
        }

        test("a shallow overlap fires enter the moment the boundary is crossed") {
            val engine = RegionEngine()
            val player = server.addPlayer()
            player.teleport(location(93.0, 61.0, 100.0))

            val region = RegionDefinitionData(
                origin = ConstVar(position(100.0, 64.0, 100.0)),
                shape = CuboidShape(5.0, 5.0, 5.0),
            )
            val events = mutableListOf<String>()
            val handler = EnterExitHandler(
                owner = "test",
                boundaryInset = ConstVar(0.5),
                onEnter = { _, _, _ -> events.add("enter"); false },
                onLeave = { _, _, _ -> events.add("leave"); false },
            )
            val subscription = engine.observe(region, null, handler)!!

            move(engine, player, location(94.8, 61.0, 100.0))
            subscription.tracker.isInside(player) shouldBe true
            events shouldBe listOf("enter")

            subscription.cancel()
        }

        test("teleports classify with the Teleported cause") {
            val engine = RegionEngine()
            val player = server.addPlayer()
            player.teleport(location(90.0, 61.0, 100.0))

            val region = RegionDefinitionData(
                origin = ConstVar(position(100.0, 64.0, 100.0)),
                shape = CuboidShape(5.0, 5.0, 5.0),
            )
            val enters = mutableListOf<CrossingCause>()
            val subscription = engine.observe(
                region,
                null,
                EnterExitHandler(
                    owner = "test",
                    onEnter = { _, cause, _ -> enters.add(cause); false },
                ),
            )!!

            val from = player.location
            val to = location(100.0, 61.0, 100.0)
            player.teleport(to)
            engine.onTeleport(PlayerTeleportEvent(player, from, to))

            enters shouldBe listOf(CrossingCause.TELEPORTED)
            subscription.cancel()
        }

        test("a cancelled enter rolls membership back") {
            val engine = RegionEngine()
            val player = server.addPlayer()
            player.teleport(location(90.0, 61.0, 100.0))

            val region = RegionDefinitionData(
                origin = ConstVar(position(100.0, 64.0, 100.0)),
                shape = CuboidShape(5.0, 5.0, 5.0),
            )
            val handler = EnterExitHandler(
                owner = "test",
                onEnter = { _, _, _ -> true },
            )
            val subscription = engine.observe(region, null, handler)!!

            val event = move(engine, player, location(100.0, 61.0, 100.0))

            event.isCancelled shouldBe true
            handler.tracks(player) shouldBe false
            subscription.cancel()
        }

        test("a moving region engulfing a player fires Engulfed crossings") {
            val engine = RegionEngine()
            val player = server.addPlayer()
            player.teleport(location(100.0, 64.0, 100.0))

            var origin = position(100.0, 90.0, 100.0)
            val region = RegionDefinitionData(
                origin = ComputeVar { _, _ -> origin },
                shape = SphereShape(3.0),
            )
            val events = mutableListOf<Pair<String, CrossingCause>>()
            val handler = EnterExitHandler(
                owner = "test",
                tracked = player.uniqueId,
                onEnter = { _, cause, _ -> events.add("enter" to cause); false },
                onLeave = { _, cause, _ -> events.add("leave" to cause); false },
            )
            val subscription = engine.observe(region, player, handler)!!
            handler.tracks(player) shouldBe false

            origin = position(100.0, 65.0, 100.0)
            engine.refreshAndReconcile(subscription.tracker)
            events shouldBe listOf("enter" to CrossingCause.ENGULFED)

            origin = position(100.0, 90.0, 100.0)
            engine.refreshAndReconcile(subscription.tracker)
            events shouldBe listOf("enter" to CrossingCause.ENGULFED, "leave" to CrossingCause.ENGULFED)

            subscription.cancel()
        }

        test("the guard tutorial cone spots a player walking toward the guard") {
            val engine = RegionEngine()
            val player = server.addPlayer()
            player.teleport(location(185.0, 64.0, 200.0))

            val guard = Position(World(world.uid.toString()), 200.0, 64.0, 200.0, 90f, 0f)
            val region = RegionDefinitionData(
                origin = ComputeVar { _, _ -> guard },
                offset = ConstVar(Vector(0.0, 1.6, 0.0)),
                rotateWithOrigin = true,
                shape = ConeShape(length = 12.0, halfAngleDegrees = 30.0),
            )
            val enters = mutableListOf<CrossingCause>()
            val handler = EnterExitHandler(
                owner = "test",
                tracked = player.uniqueId,
                boundaryInset = ConstVar(0.5),
                onEnter = { _, cause, _ -> enters.add(cause); false },
            )
            val subscription = engine.observe(region, player, handler)!!

            var x = 185.0
            var enteredAt = Double.NaN
            while (x < 196.0) {
                x += 0.2
                move(engine, player, location(x, 64.0, 200.0))
                engine.refreshAndReconcile(subscription.tracker)
                if (enters.isNotEmpty() && enteredAt.isNaN()) enteredAt = x
            }

            enters.isNotEmpty() shouldBe true
            (200.0 - enteredAt >= 8.0) shouldBe true
            subscription.tracker.isInside(player) shouldBe true

            subscription.cancel()
        }

        test("horizontal proximity ignores height while full does not") {
            val engine = RegionEngine()
            val player = server.addPlayer()
            player.teleport(location(208.0, 90.0, 200.0))

            val region = RegionDefinitionData(
                origin = ConstVar(position(200.0, 64.0, 200.0)),
                shape = CuboidShape(5.0, 2.0, 5.0),
            )
            val horizontal = ProximityHandler("test", player.uniqueId, ConstVar(3.0), DistanceMode.HORIZONTAL)
            val full = ProximityHandler("test", player.uniqueId, ConstVar(3.0), DistanceMode.FULL)
            val first = engine.observe(region, null, horizontal)!!
            val second = engine.observe(region, null, full)!!

            horizontal.tracks(player) shouldBe true
            full.tracks(player) shouldBe false

            first.cancel()
            second.cancel()
        }

        // The audience manager and the event binder both subscribe from PlayerJoinEvent at NORMAL
        // priority, so the engine has to have recorded the joiner by then. Without that, every
        // region with a variable placement is refused for the rest of that player's session.
        test("a region subscribed to while a player joins is kept") {
            val engine = RegionEngine()
            val plugin = MockBukkit.createMockPlugin("region-join-test")
            engine.recordRoster(server.onlinePlayers)
            server.pluginManager.registerEvents(engine, plugin)

            val region = RegionDefinitionData(
                origin = ComputeVar { viewer, _ -> viewer?.location?.toPosition() ?: position(0.0, 0.0, 0.0) },
                shape = SphereShape(5.0),
            )
            var subscription: RegionEngine.Subscription? = null
            val binder = object : Listener {
                @EventHandler
                fun onJoin(event: PlayerJoinEvent) {
                    subscription = engine.observe(
                        region,
                        event.player,
                        EnterExitHandler(owner = "test", tracked = event.player.uniqueId),
                    )
                }
            }
            server.pluginManager.registerEvents(binder, plugin)

            val joiner = server.addPlayer()

            withClue("the joiner's own bubble region was refused") { subscription shouldNotBe null }
            subscription!!.tracker.viewer shouldBe joiner

            subscription!!.cancel()
            HandlerList.unregisterAll(binder)
            HandlerList.unregisterAll(engine)
        }
    }
}
