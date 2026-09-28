package com.typewritermc.region.flag

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World as CoreWorld
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.entries.modifier.FireSpreadModifierEntry
import com.typewritermc.region.entries.modifier.FireSpreadModifierHandler
import com.typewritermc.region.entries.modifier.FluidFlowModifierEntry
import com.typewritermc.region.entries.modifier.FluidFlowModifierHandler
import com.typewritermc.region.entries.modifier.PistonModifierEntry
import com.typewritermc.region.entries.modifier.PistonModifierHandler
import com.typewritermc.region.entries.modifier.RedstoneModifierEntry
import com.typewritermc.region.entries.modifier.RedstoneModifierHandler
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.tracker.RegionTracker
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import org.bukkit.block.BlockFace
import org.bukkit.entity.Entity
import org.bukkit.event.block.BlockBurnEvent
import org.bukkit.event.block.BlockFromToEvent
import org.bukkit.event.block.BlockIgniteEvent
import org.bukkit.event.block.BlockPistonExtendEvent
import org.bukkit.event.block.BlockPistonRetractEvent
import org.bukkit.event.block.BlockRedstoneEvent
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock
import java.util.Optional
import kotlin.reflect.KClass

class MechanicalFlagHandlerSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("mechanical")
        }

        afterSpec { MockBukkit.unmock() }

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
        ) : RegionDefinitionEntry {
            override fun buildShape(): Shape = CuboidShape(5.0, 5.0, 5.0)
        }

        /** A region at the origin, five blocks in every direction, carrying [flags]. */
        fun indexWith(flags: Map<KClass<out RegionModifierEntry>, RegionModifierEntry>): RegionFlagIndex {
            val entry = TestRegion(
                id = "vault",
                origin = ConstVar(Position(CoreWorld(world.uid.toString()), 0.0, 64.0, 0.0)),
            )
            val tracker = RegionTracker(null, entry)
            tracker.refresh()
            val region = FlaggedRegion(entry, 0, 0, flags, tracker, tracker.cachedAabb)
            return RegionFlagIndex(listOf(region), engine = null)
        }

        test("a piston pushing a block into the region is cancelled whole") {
            val index = indexWith(mapOf(PistonModifierEntry::class to PistonModifierEntry(allowed = false)))
            val handler = PistonModifierHandler(index)

            val piston = world.getBlockAt(20, 64, 0)
            val outside = world.getBlockAt(19, 64, 0)
            val inside = world.getBlockAt(2, 64, 0)
            val event = BlockPistonExtendEvent(piston, listOf(outside, inside), BlockFace.WEST)
            handler.onExtend(event)

            event.isCancelled shouldBe true
        }

        test("a piston moving only blocks outside the region is left alone") {
            val index = indexWith(mapOf(PistonModifierEntry::class to PistonModifierEntry(allowed = false)))
            val handler = PistonModifierHandler(index)

            val piston = world.getBlockAt(40, 64, 0)
            val outside = world.getBlockAt(39, 64, 0)
            val event = BlockPistonExtendEvent(piston, listOf(outside), BlockFace.WEST)
            handler.onExtend(event)

            event.isCancelled shouldBe false
        }

        test("a piston is allowed when the region says so") {
            val index = indexWith(mapOf(PistonModifierEntry::class to PistonModifierEntry(allowed = true)))
            val handler = PistonModifierHandler(index)

            val piston = world.getBlockAt(20, 64, 0)
            val inside = world.getBlockAt(2, 64, 0)
            val event = BlockPistonExtendEvent(piston, listOf(inside), BlockFace.WEST)
            handler.onExtend(event)

            event.isCancelled shouldBe false
        }

        // A sticky piston standing inside the region drags whatever is stuck to its head in from
        // outside, and the block it pulls is listed where it stands rather than where it lands.
        test("a sticky piston pulling a block into the region is cancelled") {
            val index = indexWith(mapOf(PistonModifierEntry::class to PistonModifierEntry(allowed = false)))
            val handler = PistonModifierHandler(index)

            val piston = world.getBlockAt(3, 64, 0)
            val pulled = world.getBlockAt(5, 64, 0)
            val event = BlockPistonRetractEvent(piston, listOf(pulled), BlockFace.WEST)
            handler.onRetract(event)

            event.isCancelled shouldBe true
        }

        test("a sticky piston pulling a block nowhere near the region is left alone") {
            val index = indexWith(mapOf(PistonModifierEntry::class to PistonModifierEntry(allowed = false)))
            val handler = PistonModifierHandler(index)

            val piston = world.getBlockAt(30, 64, 0)
            val pulled = world.getBlockAt(32, 64, 0)
            val event = BlockPistonRetractEvent(piston, listOf(pulled), BlockFace.WEST)
            handler.onRetract(event)

            event.isCancelled shouldBe false
        }

        test("redstone inside the region is held at its old current") {
            val index = indexWith(mapOf(RedstoneModifierEntry::class to RedstoneModifierEntry(allowed = false)))
            val handler = RedstoneModifierHandler(index)

            val event = BlockRedstoneEvent(world.getBlockAt(2, 64, 2), 0, 15)
            handler.onRedstone(event)

            event.newCurrent shouldBe 0
        }

        test("redstone outside the region is left alone") {
            val index = indexWith(mapOf(RedstoneModifierEntry::class to RedstoneModifierEntry(allowed = false)))
            val handler = RedstoneModifierHandler(index)

            val event = BlockRedstoneEvent(world.getBlockAt(50, 64, 50), 0, 15)
            handler.onRedstone(event)

            event.newCurrent shouldBe 15
        }

        test("fire spreading into a denying region is cancelled") {
            val index = indexWith(mapOf(FireSpreadModifierEntry::class to FireSpreadModifierEntry(allowed = false)))
            val handler = FireSpreadModifierHandler(index)

            val inside = world.getBlockAt(2, 64, 0)
            val event = BlockIgniteEvent(inside, BlockIgniteEvent.IgniteCause.SPREAD, null as Entity?)
            handler.onIgnite(event)

            event.isCancelled shouldBe true
        }

        test("fire spreading outside the region is left alone") {
            val index = indexWith(mapOf(FireSpreadModifierEntry::class to FireSpreadModifierEntry(allowed = false)))
            val handler = FireSpreadModifierHandler(index)

            val outside = world.getBlockAt(40, 64, 40)
            val event = BlockIgniteEvent(outside, BlockIgniteEvent.IgniteCause.SPREAD, null as Entity?)
            handler.onIgnite(event)

            event.isCancelled shouldBe false
        }

        test("a player lighting a fire with flint and steel is not this flag's business") {
            val index = indexWith(mapOf(FireSpreadModifierEntry::class to FireSpreadModifierEntry(allowed = false)))
            val handler = FireSpreadModifierHandler(index)

            val inside = world.getBlockAt(2, 64, 0)
            val player = server.addPlayer()
            val event = BlockIgniteEvent(inside, BlockIgniteEvent.IgniteCause.FLINT_AND_STEEL, player)
            handler.onIgnite(event)

            event.isCancelled shouldBe false
        }

        test("a player throwing a fire charge is not this flag's business either") {
            val index = indexWith(mapOf(FireSpreadModifierEntry::class to FireSpreadModifierEntry(allowed = false)))
            val handler = FireSpreadModifierHandler(index)

            val inside = world.getBlockAt(2, 64, 0)
            val event = BlockIgniteEvent(inside, BlockIgniteEvent.IgniteCause.FIREBALL, server.addPlayer())
            handler.onIgnite(event)

            event.isCancelled shouldBe false
        }

        test("a ghast's fireball is, since no ignite flag can ever see it") {
            val index = indexWith(mapOf(FireSpreadModifierEntry::class to FireSpreadModifierEntry(allowed = false)))
            val handler = FireSpreadModifierHandler(index)

            val inside = world.getBlockAt(2, 64, 0)
            val event = BlockIgniteEvent(inside, BlockIgniteEvent.IgniteCause.FIREBALL, null as Entity?)
            handler.onIgnite(event)

            event.isCancelled shouldBe true
        }

        test("a block burning inside the region is cancelled") {
            val index = indexWith(mapOf(FireSpreadModifierEntry::class to FireSpreadModifierEntry(allowed = false)))
            val handler = FireSpreadModifierHandler(index)

            val inside = world.getBlockAt(2, 64, 0)
            val event = BlockBurnEvent(inside)
            handler.onBurn(event)

            event.isCancelled shouldBe true
        }

        test("a fluid flowing into a denying region is cancelled even though its source is outside") {
            val index = indexWith(mapOf(FluidFlowModifierEntry::class to FluidFlowModifierEntry(allowed = false)))
            val handler = FluidFlowModifierHandler(index)

            val source = world.getBlockAt(40, 64, 0)
            val destination = world.getBlockAt(2, 64, 0)
            val event = BlockFromToEvent(source, destination)
            handler.onFlow(event)

            event.isCancelled shouldBe true
        }

        test("a fluid flowing out of the region is left alone") {
            val index = indexWith(mapOf(FluidFlowModifierEntry::class to FluidFlowModifierEntry(allowed = false)))
            val handler = FluidFlowModifierHandler(index)

            val source = world.getBlockAt(2, 64, 0)
            val destination = world.getBlockAt(40, 64, 0)
            val event = BlockFromToEvent(source, destination)
            handler.onFlow(event)

            event.isCancelled shouldBe false
        }
    }
}
