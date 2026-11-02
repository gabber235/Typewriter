package com.typewritermc.region.tracker

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.region.data.RegionDefinitionData
import com.typewritermc.region.shape.CuboidShape
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.shouldBeGreaterThanOrEqual
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe

/**
 * The engine skips a tracker entirely for a player outside its cached AABB, so an AABB that
 * does not cover the resolved shape means enter and exit events, proximity bands and region
 * audiences never fire for the part it misses. Every stored rotation angle has to reach the
 * AABB, roll included: a wide flat region with roll extends much further vertically than its
 * unrolled bounds.
 */
class RotatedTrackerBoundsSpec : FunSpec({
    val world = World("world")

    fun tracker(yaw: Float, pitch: Float, roll: Float): RegionTracker {
        val definition = RegionDefinitionData(
            origin = ConstVar(Position(world, 0.0, 64.0, 0.0)),
            offset = ConstVar(Vector.ZERO),
            yaw = ConstVar(yaw),
            pitch = ConstVar(pitch),
            roll = ConstVar(roll),
            shape = CuboidShape(halfX = 10.0, halfY = 1.0, halfZ = 10.0),
        )
        return RegionTracker(null, definition).also { it.refresh() }
    }

    test("a rolled slab's bounds reach as high as the roll tips it") {
        val aabb = tracker(yaw = 0f, pitch = 0f, roll = 90f).cachedAabb.shouldNotBeNull()

        // Roll turns the 10-wide X half extent into the vertical one.
        (aabb.maxY - 64.0) shouldBeGreaterThanOrEqual 10.0
        (64.0 - aabb.minY) shouldBeGreaterThanOrEqual 10.0
    }

    test("a rolled region covers the corners of its own shape") {
        val transform = tracker(yaw = 35f, pitch = 20f, roll = 55f).lastTransform.shouldNotBeNull()
        val aabb = tracker(yaw = 35f, pitch = 20f, roll = 55f).cachedAabb.shouldNotBeNull()

        for (x in listOf(-10.0, 10.0)) for (y in listOf(-1.0, 1.0)) for (z in listOf(-10.0, 10.0)) {
            val corner = transform.toWorld(Vector(x, y, z))
            aabb.contains(Position(world, corner.x, corner.y, corner.z)) shouldBe true
        }
    }

    test("an unrotated region keeps the bounds its shape describes") {
        val aabb = tracker(yaw = 0f, pitch = 0f, roll = 0f).cachedAabb.shouldNotBeNull()

        aabb.minX shouldBe -10.0
        aabb.maxX shouldBe 10.0
        aabb.minY shouldBe 63.0
        aabb.maxY shouldBe 65.0
    }
})
