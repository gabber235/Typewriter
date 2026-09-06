package com.typewritermc.region.flag

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World as CoreWorld
import com.typewritermc.engine.paper.entry.entries.ComputeVar
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.entries.modifier.BlockBreakModifierEntry
import com.typewritermc.region.entries.modifier.BlockBreakModifierHandler
import com.typewritermc.region.entries.modifier.BlockPlaceModifierEntry
import com.typewritermc.region.entries.modifier.BlockPlaceModifierHandler
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.tracker.RegionTracker
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import org.bukkit.event.block.BlockBreakEvent
import org.bukkit.event.block.BlockGrowEvent
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock
import java.util.Optional

/**
 * A flag whose allowance is bound to a variable cannot answer for an event with no player behind
 * it. It has to step aside there rather than read as a denial: a region that means "members may
 * build here" would otherwise stop its own crops from growing, for good and without saying so.
 */
class VariableAllowanceSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("allowance")
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

        fun region(
            id: String,
            priority: Int,
            flag: RegionModifierEntry,
            type: kotlin.reflect.KClass<out RegionModifierEntry>,
        ): FlaggedRegion {
            val entry = TestRegion(
                id = id,
                origin = ConstVar(Position(CoreWorld(world.uid.toString()), 0.0, 64.0, 0.0)),
            )
            val tracker = RegionTracker(null, entry)
            tracker.refresh()
            return FlaggedRegion(
                entry = entry,
                priority = priority,
                order = priority,
                modifiers = mapOf(type to flag),
                tracker = tracker,
                aabb = tracker.cachedAabb,
            )
        }

        test("a crop keeps growing under a flag whose allowance needs a player") {
            val flag = BlockPlaceModifierEntry(
                id = "members-only",
                name = "Members Only",
                allowed = ComputeVar { _, _ -> true },
            )
            val index = RegionFlagIndex(
                listOf(region("farm", 0, flag, BlockPlaceModifierEntry::class)),
                engine = null,
            )
            val block = world.getBlockAt(2, 64, 2)

            val event = BlockGrowEvent(block, block.state)
            BlockPlaceModifierHandler(index).onGrow(event)

            event.isCancelled shouldBe false
        }

        test("a player is still decided about by the same flag") {
            val flag = BlockBreakModifierEntry(
                id = "members-only",
                name = "Members Only",
                allowed = ComputeVar { _, _ -> false },
            )
            val index = RegionFlagIndex(
                listOf(region("vault", 0, flag, BlockBreakModifierEntry::class)),
                engine = null,
            )

            val event = BlockBreakEvent(world.getBlockAt(2, 64, 2), server.addPlayer())
            BlockBreakModifierHandler(index).onBreak(event)

            event.isCancelled shouldBe true
        }

        test("the region below decides when the one on top cannot") {
            val members = BlockPlaceModifierEntry(
                id = "members-only",
                name = "Members Only",
                allowed = ComputeVar { _, _ -> true },
            )
            val sealed = BlockPlaceModifierEntry(
                id = "sealed",
                name = "Sealed",
                allowed = ConstVar(false),
            )
            val index = RegionFlagIndex(
                listOf(
                    region("plot", 10, members, BlockPlaceModifierEntry::class),
                    region("world-guard", 0, sealed, BlockPlaceModifierEntry::class),
                ),
                engine = null,
            )
            val block = world.getBlockAt(2, 64, 2)

            val event = BlockGrowEvent(block, block.state)
            BlockPlaceModifierHandler(index).onGrow(event)

            event.isCancelled shouldBe true
        }

        test("the console names the region whose allowance cannot cover every case") {
            val flag = BlockPlaceModifierEntry(
                id = "members-only",
                name = "Members Only",
                allowed = ComputeVar { _, _ -> true },
            )
            val reported = variableAllowancesOnViewerlessFlags(
                listOf(region("farm", 0, flag, BlockPlaceModifierEntry::class)),
            )

            reported shouldBe listOf("farm" to "Members Only")
        }

        test("a constant allowance is not reported") {
            val flag = BlockPlaceModifierEntry(id = "sealed", name = "Sealed", allowed = ConstVar(false))
            val reported = variableAllowancesOnViewerlessFlags(
                listOf(region("plot", 0, flag, BlockPlaceModifierEntry::class)),
            )

            reported.isEmpty() shouldBe true
        }
    }
}
