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
import com.typewritermc.region.entries.modifier.EntityDamageModifierEntry
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.tracker.RegionTracker
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import java.util.Optional

class RegionFlagManagerSpec : FunSpec({
    val world = World("flag-world")

    class BreakFlag(override val id: String = "break", override val name: String = "No Breaking") : RegionModifierEntry
    class PistonFlag(override val id: String = "piston", override val name: String = "No Pistons") : RegionModifierEntry

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

    fun staticRegion(id: String) = TestRegion(id = id, origin = ConstVar(Position(world, 0.0, 64.0, 0.0)))

    test("a viewerless flag on a variable placed region is reported, because it can never apply") {
        val dynamic = FlaggedRegion(
            entry = staticRegion("cone"),
            priority = 0,
            order = 0,
            modifiers = mapOf(PistonFlag::class to PistonFlag()),
            tracker = null,
            aabb = null,
        )

        val warnings = viewerlessFlagsOnDynamicRegions(listOf(dynamic), setOf(PistonFlag::class))

        warnings shouldHaveSize 1
        warnings.first().first shouldBe "cone"
        warnings.first().second shouldBe "No Pistons"
    }

    test("a player decided flag on a variable placed region is not reported") {
        val dynamic = FlaggedRegion(
            entry = staticRegion("cone"),
            priority = 0,
            order = 0,
            modifiers = mapOf(BreakFlag::class to BreakFlag()),
            tracker = null,
            aabb = null,
        )

        viewerlessFlagsOnDynamicRegions(listOf(dynamic), setOf(PistonFlag::class)).shouldBeEmpty()
    }

    test("a viewerless flag on a constant placed region is not reported") {
        val entry = staticRegion("city")
        val tracker = RegionTracker(null, entry)
        tracker.refresh()
        val region = FlaggedRegion(
            entry = entry,
            priority = 0,
            order = 0,
            modifiers = mapOf(PistonFlag::class to PistonFlag()),
            tracker = tracker,
            aabb = tracker.cachedAabb,
        )

        viewerlessFlagsOnDynamicRegions(listOf(region), setOf(PistonFlag::class)).shouldBeEmpty()
    }

    val entityDamageFlag = EntityDamageModifierEntry(id = "entity_damage", name = "No Entity Damage")

    test("a partly viewerless flag on a variable placed region is reported, because it only partly applies") {
        val dynamic = FlaggedRegion(
            entry = staticRegion("museum"),
            priority = 0,
            order = 0,
            modifiers = mapOf(EntityDamageModifierEntry::class to entityDamageFlag),
            tracker = null,
            aabb = null,
        )

        val warnings = viewerlessFlagsOnDynamicRegions(listOf(dynamic), PARTLY_VIEWERLESS_FLAGS)

        warnings shouldHaveSize 1
        warnings.first().first shouldBe "museum"
        warnings.first().second shouldBe "No Entity Damage"
    }

    test("a partly viewerless flag on a constant placed region is not reported") {
        val entry = staticRegion("museum")
        val tracker = RegionTracker(null, entry)
        tracker.refresh()
        val region = FlaggedRegion(
            entry = entry,
            priority = 0,
            order = 0,
            modifiers = mapOf(EntityDamageModifierEntry::class to entityDamageFlag),
            tracker = tracker,
            aabb = tracker.cachedAabb,
        )

        viewerlessFlagsOnDynamicRegions(listOf(region), PARTLY_VIEWERLESS_FLAGS).shouldBeEmpty()
    }

    test("buildFlaggedRegions skips a region with no flags, and resolves a tracker for a static one") {
        val flagged = TestRegion(id = "city", origin = ConstVar(Position(world, 0.0, 64.0, 0.0)))
        val plain = TestRegion(id = "plain", origin = ConstVar(Position(world, 0.0, 64.0, 0.0)))

        // A region whose modifier refs resolve to nothing carries no flags and must not be indexed.
        buildFlaggedRegions(listOf(flagged, plain)).shouldBeEmpty()
    }
})
