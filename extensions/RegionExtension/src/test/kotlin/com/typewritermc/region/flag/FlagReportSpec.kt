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
import com.typewritermc.region.entries.modifier.PistonModifierEntry
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.tracker.RegionTracker
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.mockk.mockk
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock
import java.util.Optional
import kotlin.reflect.KClass

class FlagReportSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("flag-report")
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
            val half: Double,
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
            override fun buildShape(): Shape = CuboidShape(half, half, half)
        }

        fun regionAt(
            id: String,
            half: Double,
            priority: Int,
            order: Int,
            flags: Map<KClass<out RegionModifierEntry>, RegionModifierEntry>,
        ): FlaggedRegion {
            val entry = TestRegion(
                id = id,
                origin = ConstVar(Position(CoreWorld(world.uid.toString()), 0.0, 64.0, 0.0)),
                half = half,
            )
            val tracker = RegionTracker(null, entry)
            tracker.refresh()
            return FlaggedRegion(entry, priority, order, flags, tracker, tracker.cachedAabb)
        }

        fun at(x: Double) = Position(CoreWorld(world.uid.toString()), x, 64.0, 0.0)

        fun twoRegionIndex(): RegionFlagIndex {
            val hub = regionAt(
                id = "hub", half = 20.0, priority = 0, order = 0,
                flags = mapOf(BlockBreakModifierEntry::class to BlockBreakModifierEntry(allowed = ConstVar(false))),
            )
            val arena = regionAt(
                id = "arena", half = 5.0, priority = 10, order = 1,
                flags = mapOf(BlockBreakModifierEntry::class to BlockBreakModifierEntry(allowed = ConstVar(true))),
            )
            return RegionFlagIndex(listOf(hub, arena), engine = null)
        }

        test("every flag type in handlerFactories has a report label") {
            FLAG_LABELS.keys shouldBe handlerFactories.keys
        }

        test("flagReport names the arena as deciding block break where it overlaps the hub") {
            val index = twoRegionIndex()
            val player = server.addPlayer()

            val breakLine = flagReport(index, at(2.0), player).first { it.contains("Block Break") }

            breakLine shouldContain "arena"
            breakLine shouldContain "allowed"
        }

        test("flagReport falls through to the hub outside the arena") {
            val index = twoRegionIndex()
            val player = server.addPlayer()

            val breakLine = flagReport(index, at(15.0), player).first { it.contains("Block Break") }

            breakLine shouldContain "hub"
            breakLine shouldContain "denied"
        }

        test("flags nobody carries collapse into one trailing counter with the names on hover") {
            val index = twoRegionIndex()
            val player = server.addPlayer()

            val lines = flagReport(index, at(2.0), player)

            lines.size shouldBe 2
            lines.last() shouldContain "+ 17 undecided flags"
            lines.last() shouldContain "hover:show_text"
            lines.last() shouldContain "Piston"
        }

        test("a block no region decides gets a single quiet line") {
            val index = twoRegionIndex()
            val player = server.addPlayer()

            flagReport(index, at(500.0), player) shouldBe
                    listOf("<gray>No region decides any flag at this block.")
        }

        test("standingReport lists every containing region highest priority first, one line each") {
            val index = twoRegionIndex()
            val player = server.addPlayer()

            val lines = standingReport(index, at(2.0), player)

            lines.size shouldBe 2
            lines[0] shouldContain "arena"
            lines[0] shouldContain "Block Break</white> <green>✔</green>"
            lines[1] shouldContain "hub"
            lines[1] shouldContain "Block Break</white> <red>✘</red>"
        }

        test("standingReport says so when the position is in no flagged region") {
            val index = twoRegionIndex()
            val player = server.addPlayer()

            standingReport(index, at(500.0), player) shouldBe
                    listOf("<gray>No flagged region contains this position.")
        }
    }
}
