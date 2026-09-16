package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.shape.SphereShape
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe

private val world = World("test-world")

private fun candidate(id: String, at: Vector, shape: Shape, yaw: Float = 0f): TargetCandidate =
    TargetCandidate(id, ResolvedTransform(world, at, yaw, 0f), shape)

private fun aimFrom(eye: Vector, at: Vector): Vector = (at - eye).normalize()

class WorkspaceTargetingSpec : FunSpec({
    val range = 64.0

    test("aiming at one of two separate regions selects the aimed one") {
        val regions = listOf(
            candidate("west", Vector(-20.0, 65.0, 0.0), CuboidShape(3.0, 3.0, 3.0)),
            candidate("east", Vector(20.0, 65.0, 0.0), CuboidShape(3.0, 3.0, 3.0)),
        )
        val eye = Vector(0.0, 66.6, 0.0)

        pickTargetedRegion(regions, eye, aimFrom(eye, Vector(-20.0, 65.0, 0.0)), range) shouldBe "west"
        pickTargetedRegion(regions, eye, aimFrom(eye, Vector(20.0, 65.0, 0.0)), range) shouldBe "east"
    }

    test("a ray crossing two regions selects the nearer boundary") {
        val regions = listOf(
            candidate("near", Vector(10.0, 65.0, 0.0), CuboidShape(2.0, 2.0, 2.0)),
            candidate("far", Vector(30.0, 65.0, 0.0), CuboidShape(2.0, 2.0, 2.0)),
        )
        val eye = Vector(0.0, 65.0, 0.0)

        pickTargetedRegion(regions, eye, Vector(1.0, 0.0, 0.0), range) shouldBe "near"
    }

    test("aiming at a small region from inside a large one selects the small one") {
        // The regression this pick exists for: the player stands inside a big region whose
        // floor sits just below the ground. A slightly downward aim exits that floor after a
        // few blocks, closer than the aimed at region's wall, and a plain nearest hit pick
        // would select the surrounding region for every aim.
        val regions = listOf(
            candidate("surrounding", Vector(0.0, 63.0, 0.0), CuboidShape(50.0, 5.0, 50.0)),
            candidate("aimed", Vector(25.0, 65.5, 0.0), CuboidShape(2.0, 2.0, 2.0)),
        )
        val eye = Vector(0.0, 66.6, 0.0)

        val down = aimFrom(eye, Vector(25.0, 64.0, 0.0))
        pickTargetedRegion(regions, eye, down, range) shouldBe "aimed"
    }

    test("aiming at nothing while inside a region selects that region through its exit") {
        val regions = listOf(
            candidate("surrounding", Vector(0.0, 63.0, 0.0), CuboidShape(30.0, 5.0, 30.0)),
        )
        val eye = Vector(0.0, 66.6, 0.0)

        pickTargetedRegion(regions, eye, Vector(1.0, 0.0, 0.0), range) shouldBe "surrounding"
    }

    test("inside nested regions, the wall the aim leaves through decides") {
        val regions = listOf(
            candidate("outer", Vector(0.0, 65.0, 0.0), CuboidShape(20.0, 10.0, 20.0)),
            candidate("inner", Vector(0.0, 65.0, 0.0), CuboidShape(5.0, 10.0, 5.0)),
        )
        val eye = Vector(0.0, 65.0, 0.0)

        pickTargetedRegion(regions, eye, Vector(1.0, 0.0, 0.0), range) shouldBe "inner"

        val eyeBetween = Vector(10.0, 65.0, 0.0)
        pickTargetedRegion(regions, eyeBetween, Vector(1.0, 0.0, 0.0), range) shouldBe "outer"
    }

    test("a rotated region is hit through its rotated boundary") {
        val regions = listOf(
            candidate("rotated", Vector(20.0, 65.0, 0.0), CuboidShape(6.0, 3.0, 1.0), yaw = 45f),
        )
        val eye = Vector(20.0, 65.0, -10.0)

        pickTargetedRegion(regions, eye, Vector(0.0, 0.0, 1.0), range) shouldBe "rotated"
    }

    test("a sphere behind the player is not selected") {
        val regions = listOf(
            candidate("behind", Vector(-20.0, 65.0, 0.0), SphereShape(3.0)),
        )
        val eye = Vector(0.0, 65.0, 0.0)

        pickTargetedRegion(regions, eye, Vector(1.0, 0.0, 0.0), range).shouldBeNull()
    }

    test("no candidates yields no selection") {
        pickTargetedRegion(emptyList(), Vector.ZERO, Vector(1.0, 0.0, 0.0), range).shouldBeNull()
    }
})
