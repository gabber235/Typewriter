package com.typewritermc.region.flag

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.tracker.RegionTracker
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import java.util.Optional
import kotlin.reflect.KClass

class RegionFlagIndexSpec : FunSpec({
    val world = World("flag-world")

    class BreakFlag(
        override val id: String = "",
        override val name: String = "",
        val allowed: Boolean = false,
    ) : RegionModifierEntry

    class PvpFlag(
        override val id: String = "",
        override val name: String = "",
    ) : RegionModifierEntry

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
        x: Double,
        half: Double,
        priority: Int,
        order: Int,
        flags: Map<KClass<out RegionModifierEntry>, RegionModifierEntry>,
    ): FlaggedRegion {
        val entry = TestRegion(id = id, origin = ConstVar(Position(world, x, 64.0, 0.0)), half = half)
        val tracker = RegionTracker(null, entry)
        tracker.refresh()
        return FlaggedRegion(entry, priority, order, flags, tracker, tracker.cachedAabb)
    }

    fun at(x: Double, y: Double = 64.0, z: Double = 0.0) = Position(world, x, y, z)

    val deny = BreakFlag(id = "deny", allowed = false)
    val allow = BreakFlag(id = "allow", allowed = true)

    test("a region carrying the flag decides for a point inside it") {
        val index = RegionFlagIndex(
            listOf(regionAt("city", 0.0, 10.0, priority = 0, order = 0, flags = mapOf(BreakFlag::class to deny))),
            engine = null,
        )

        val resolved = index.resolve(BreakFlag::class, at(3.0), null).shouldNotBeNull()
        resolved.allowed shouldBe false
    }

    test("a point in no region resolves to nothing") {
        val index = RegionFlagIndex(
            listOf(regionAt("city", 0.0, 10.0, priority = 0, order = 0, flags = mapOf(BreakFlag::class to deny))),
            engine = null,
        )

        index.resolve(BreakFlag::class, at(500.0), null).shouldBeNull()
    }

    test("the higher priority region wins, so an arena re-allows what the city forbids") {
        val city = regionAt("city", 0.0, 20.0, priority = 0, order = 0, flags = mapOf(BreakFlag::class to deny))
        val arena = regionAt("arena", 0.0, 5.0, priority = 10, order = 1, flags = mapOf(BreakFlag::class to allow))
        val index = RegionFlagIndex(listOf(city, arena), engine = null)

        index.resolve(BreakFlag::class, at(2.0), null).shouldNotBeNull().allowed shouldBe true
        index.resolve(BreakFlag::class, at(15.0), null).shouldNotBeNull().allowed shouldBe false
    }

    test("a higher priority region without the flag falls through to a lower one that has it") {
        val city = regionAt("city", 0.0, 20.0, priority = 0, order = 0, flags = mapOf(BreakFlag::class to deny))
        val plaza = regionAt("plaza", 0.0, 5.0, priority = 10, order = 1, flags = mapOf(PvpFlag::class to PvpFlag()))
        val index = RegionFlagIndex(listOf(city, plaza), engine = null)

        index.resolve(BreakFlag::class, at(2.0), null).shouldNotBeNull().allowed shouldBe false
    }

    test("equal priorities resolve to the region declared later") {
        val older = regionAt("older", 0.0, 10.0, priority = 5, order = 0, flags = mapOf(BreakFlag::class to deny))
        val newer = regionAt("newer", 0.0, 10.0, priority = 5, order = 1, flags = mapOf(BreakFlag::class to allow))
        val index = RegionFlagIndex(listOf(older, newer), engine = null)

        index.resolve(BreakFlag::class, at(0.0), null).shouldNotBeNull().allowed shouldBe true
    }

    test("a region too large to index is still found, through the oversized bucket") {
        val huge = regionAt("huge", 0.0, 6000.0, priority = 0, order = 0, flags = mapOf(BreakFlag::class to deny))
        val index = RegionFlagIndex(listOf(huge), engine = null)

        index.oversizedCount shouldBe 1
        index.resolve(BreakFlag::class, at(1000.0), null).shouldNotBeNull().allowed shouldBe false
    }

    test("a normal region is indexed by chunk, not scanned") {
        val index = RegionFlagIndex(
            listOf(regionAt("city", 0.0, 10.0, priority = 0, order = 0, flags = mapOf(BreakFlag::class to deny))),
            engine = null,
        )

        index.oversizedCount shouldBe 0
    }

    test("a block in a chunk no region touches tests no region at all") {
        val regions = (0 until 200).map { index ->
            regionAt("r$index", index * 64.0, 8.0, priority = 0, order = index, flags = mapOf(BreakFlag::class to deny))
        }
        val index = RegionFlagIndex(regions, engine = null)

        // Far from every region's chunks. The index must not consult a single region here: this is
        // the redstone contraption case, and the whole design exists to make it free.
        index.resolve(BreakFlag::class, at(100_000.0), null).shouldBeNull()
        index.candidatesTouched shouldBe 0
    }

    test("a lookup inside one region touches only the regions sharing its chunk") {
        val regions = (0 until 200).map { index ->
            regionAt("r$index", index * 64.0, 8.0, priority = 0, order = index, flags = mapOf(BreakFlag::class to deny))
        }
        val index = RegionFlagIndex(regions, engine = null)

        index.resolve(BreakFlag::class, at(0.0), null).shouldNotBeNull()
        index.candidatesTouched shouldBe 1
    }

    // The index and the lookup must round a coordinate to a chunk the same way. They round
    // differently for negatives if either side uses a plain division, and the region's flags then
    // silently stop applying across half the world.
    test("a region on the negative side of an axis still decides") {
        val index = RegionFlagIndex(
            listOf(regionAt("west", -200.0, 10.0, priority = 0, order = 0, flags = mapOf(BreakFlag::class to deny))),
            engine = null,
        )

        index.resolve(BreakFlag::class, at(-200.0), null).shouldNotBeNull().allowed shouldBe false
        index.resolve(BreakFlag::class, at(-195.0), null).shouldNotBeNull().allowed shouldBe false
        index.resolve(BreakFlag::class, at(-160.0), null).shouldBeNull()
    }

    test("a region straddling the origin decides on both sides of it") {
        val index = RegionFlagIndex(
            listOf(regionAt("center", 0.0, 20.0, priority = 0, order = 0, flags = mapOf(BreakFlag::class to deny))),
            engine = null,
        )

        index.resolve(BreakFlag::class, at(-18.0, 64.0, -18.0), null).shouldNotBeNull().allowed shouldBe false
        index.resolve(BreakFlag::class, at(18.0, 64.0, 18.0), null).shouldNotBeNull().allowed shouldBe false
    }

    test("a decision names the region that made it") {
        val city = regionAt("city", 0.0, 20.0, priority = 0, order = 0, flags = mapOf(BreakFlag::class to deny))
        val arena = regionAt("arena", 0.0, 5.0, priority = 10, order = 1, flags = mapOf(BreakFlag::class to allow))
        val index = RegionFlagIndex(listOf(city, arena), engine = null)

        val decision = index.resolveDecision(BreakFlag::class, at(2.0), null).shouldNotBeNull()
        decision.flag.allowed shouldBe true
        decision.regionName shouldBe "arena"
        decision.priority shouldBe 10

        val outer = index.resolveDecision(BreakFlag::class, at(15.0), null).shouldNotBeNull()
        outer.regionName shouldBe "city"
        outer.priority shouldBe 0
    }

    test("resolve agrees with resolveDecision, because it is the same walk") {
        val city = regionAt("city", 0.0, 20.0, priority = 0, order = 0, flags = mapOf(BreakFlag::class to deny))
        val arena = regionAt("arena", 0.0, 5.0, priority = 10, order = 1, flags = mapOf(BreakFlag::class to allow))
        val index = RegionFlagIndex(listOf(city, arena), engine = null)

        index.resolve(BreakFlag::class, at(2.0), null) shouldBe
                index.resolveDecision(BreakFlag::class, at(2.0), null)?.flag
        index.resolve(BreakFlag::class, at(500.0), null) shouldBe
                index.resolveDecision(BreakFlag::class, at(500.0), null)?.flag
    }

    test("regionsAt lists every containing region, highest priority first") {
        val city = regionAt("city", 0.0, 20.0, priority = 0, order = 0, flags = mapOf(BreakFlag::class to deny))
        val arena = regionAt("arena", 0.0, 5.0, priority = 10, order = 1, flags = mapOf(BreakFlag::class to allow))
        val index = RegionFlagIndex(listOf(city, arena), engine = null)

        index.regionsAt(at(2.0), null).map { it.entry.name } shouldBe listOf("arena", "city")
        index.regionsAt(at(15.0), null).map { it.entry.name } shouldBe listOf("city")
        index.regionsAt(at(500.0), null).map { it.entry.name } shouldBe emptyList()
    }
})
