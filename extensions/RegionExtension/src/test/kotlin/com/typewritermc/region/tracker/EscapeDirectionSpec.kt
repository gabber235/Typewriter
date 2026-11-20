package com.typewritermc.region.tracker

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.region.data.RegionDefinitionData
import com.typewritermc.region.shape.CuboidShape
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe

/**
 * The barrier and the push action ask for this direction exactly when the nearest face is the
 * floor or the ceiling, because a grounded player pushed into either only feels slowed. A
 * direction that comes back null or radial there leaves them standing in the region being
 * shoved into the ground, which is the failure the redirect exists to prevent.
 */
class EscapeDirectionSpec : FunSpec({
    val world = World("world")

    fun trackerFor(halfX: Double, halfY: Double, halfZ: Double): RegionTracker {
        val definition = RegionDefinitionData(
            origin = ConstVar(Position(world, 0.0, 64.0, 0.0)),
            shape = CuboidShape(halfX, halfY, halfZ),
        )
        return RegionTracker(null, definition).apply { refresh() }
    }

    test("a player standing on the floor of a flat room is sent sideways, not nowhere") {
        val tracker = trackerFor(30.0, 3.0, 30.0)
        val direction = tracker.horizontalEscapeDirection(Position(world, 0.0, 61.1, 0.0)).shouldNotBeNull()

        direction.y shouldBe 0.0
        (direction.length > 0.9) shouldBe true
    }

    test("the direction points at the nearest wall") {
        val tracker = trackerFor(30.0, 3.0, 30.0)
        val direction = tracker.horizontalEscapeDirection(Position(world, 25.0, 61.1, 5.0)).shouldNotBeNull()

        direction.x shouldBe (1.0 plusOrMinus 1e-9)
        direction.y shouldBe 0.0
        direction.z shouldBe (0.0 plusOrMinus 1e-9)
    }

    test("a player under the ceiling is sent sideways too") {
        val tracker = trackerFor(30.0, 3.0, 30.0)
        val direction = tracker.horizontalEscapeDirection(Position(world, -8.0, 66.9, 0.0)).shouldNotBeNull()

        direction.x shouldBe (-1.0 plusOrMinus 1e-9)
        direction.y shouldBe 0.0
    }
})
