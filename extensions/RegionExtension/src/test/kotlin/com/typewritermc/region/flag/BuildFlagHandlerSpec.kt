package com.typewritermc.region.flag

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World as CoreWorld
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.entries.modifier.BlockBreakModifierEntry
import com.typewritermc.region.entries.modifier.BlockBreakModifierHandler
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.PolygonShape
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.tracker.RegionTracker
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import org.bukkit.Material
import org.bukkit.event.block.BlockBreakEvent
import org.bukkit.event.block.BlockFadeEvent
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock
import java.util.Optional

class BuildFlagHandlerSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("flags")
            startKoin { modules(module { single { mockk<PlayerSessionManager>(relaxed = true) } }) }
        }

        afterSpec {
            stopKoin()
            MockBukkit.unmock()
        }

        class TestRegion(
            override val id: String,
            override val name: String = id,
            override val origin: Var<Position>,
            override val modifiers: List<Ref<out RegionModifierEntry>> = emptyList(),
            override val priorityOverride: Optional<Int> = Optional.empty(),
            override val offset: Var<Vector> = RegionDefaults.OFFSET,
            override val yaw: Var<Float> = RegionDefaults.YAW,
            override val pitch: Var<Float> = RegionDefaults.PITCH,
            override val roll: Var<Float> = RegionDefaults.ROLL,
            override val rotateWithOrigin: Boolean = false,
            override val color: Color = RegionDefaults.COLOR,
            override val refreshRateTicks: Int = RegionDefaults.REFRESH_RATE_TICKS,
            private val shape: Shape = CuboidShape(5.0, 5.0, 5.0),
        ) : RegionDefinitionEntry {
            override fun buildShape(): Shape = shape
        }

        fun indexDenyingBreaks(shape: Shape = CuboidShape(5.0, 5.0, 5.0)): RegionFlagIndex {
            val entry = TestRegion(
                id = "vault",
                origin = ConstVar(Position(CoreWorld(world.uid.toString()), 0.0, 64.0, 0.0)),
                shape = shape,
            )
            val tracker = RegionTracker(null, entry)
            tracker.refresh()
            val flag = BlockBreakModifierEntry(id = "no-break", name = "No Breaking", allowed = ConstVar(false))
            val region = FlaggedRegion(
                entry = entry,
                priority = 0,
                order = 0,
                modifiers = mapOf(BlockBreakModifierEntry::class to flag),
                tracker = tracker,
                aabb = tracker.cachedAabb,
            )
            return RegionFlagIndex(listOf(region), engine = null)
        }

        test("breaking a block inside the region is cancelled") {
            val handler = BlockBreakModifierHandler(indexDenyingBreaks())
            val player = server.addPlayer()

            val event = BlockBreakEvent(world.getBlockAt(2, 64, 2), player)
            handler.onBreak(event)

            event.isCancelled shouldBe true
        }

        test("breaking a block outside the region is allowed") {
            val handler = BlockBreakModifierHandler(indexDenyingBreaks())
            val player = server.addPlayer()

            val event = BlockBreakEvent(world.getBlockAt(50, 64, 50), player)
            handler.onBreak(event)

            event.isCancelled shouldBe false
        }

        test("a player standing outside cannot mine a block inside: the block decides, not the player") {
            val handler = BlockBreakModifierHandler(indexDenyingBreaks())
            val player = server.addPlayer()
            player.teleport(world.getBlockAt(40, 64, 40).location)

            val event = BlockBreakEvent(world.getBlockAt(0, 64, 0), player)
            handler.onBreak(event)

            event.isCancelled shouldBe true
        }

        val diamond = PolygonShape(
            listOf(Vector(4.2, 0.0, 0.0), Vector(0.0, 0.0, 4.2), Vector(-4.2, 0.0, 0.0), Vector(0.0, 0.0, -4.2)),
            halfHeight = 5.0,
        )

        test("a block whose corner sticks out of a polygon region is still protected: the center decides") {
            val handler = BlockBreakModifierHandler(indexDenyingBreaks(diamond))
            val player = server.addPlayer()

            val event = BlockBreakEvent(world.getBlockAt(-3, 64, -2), player)
            handler.onBreak(event)

            event.isCancelled shouldBe true
        }

        test("a block whose center falls outside the polygon region is not protected") {
            val handler = BlockBreakModifierHandler(indexDenyingBreaks(diamond))
            val player = server.addPlayer()

            val event = BlockBreakEvent(world.getBlockAt(-4, 64, -2), player)
            handler.onBreak(event)

            event.isCancelled shouldBe false
        }

        test("ice melting inside the region is refused") {
            val handler = BlockBreakModifierHandler(indexDenyingBreaks())
            val block = world.getBlockAt(2, 64, 2)
            block.type = Material.ICE

            val event = BlockFadeEvent(block, world.getBlockAt(2, 60, 2).state)
            handler.onFade(event)

            event.isCancelled shouldBe true
        }

        test("fire burning out inside the region is left alone, so it cannot burn forever") {
            val handler = BlockBreakModifierHandler(indexDenyingBreaks())
            val block = world.getBlockAt(2, 64, 2)
            block.type = Material.FIRE

            val event = BlockFadeEvent(block, world.getBlockAt(2, 60, 2).state)
            handler.onFade(event)

            event.isCancelled shouldBe false
        }
    }
}
