package com.typewritermc.region.data

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.region.shape.LocalBounds
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.shouldBe

private const val TOLERANCE = 1e-9

private infix fun Vector.shouldBeCloseTo(expected: Vector) {
    x shouldBe (expected.x plusOrMinus TOLERANCE)
    y shouldBe (expected.y plusOrMinus TOLERANCE)
    z shouldBe (expected.z plusOrMinus TOLERANCE)
}

class ResolvedTransformSpec : FunSpec({
    val world = World("test-world")

    test("toLocal and toWorld are inverse under yaw and pitch") {
        val transform = ResolvedTransform(world, Vector(10.0, 20.0, 30.0), 37f, -20f)
        val points = listOf(
            Vector(0.0, 0.0, 0.0),
            Vector(1.0, 2.0, 3.0),
            Vector(-4.5, 0.25, 12.0),
        )
        for (point in points) {
            transform.toWorld(transform.toLocal(point)) shouldBeCloseTo point
            transform.toLocal(transform.toWorld(point)) shouldBeCloseTo point
        }
    }

    test("fromOriginAndOffset rotates only the horizontal offset components") {
        val origin = Position(world, 10.0, 20.0, 30.0, 0f, 0f)
        val transform = ResolvedTransform.fromOriginAndOffset(origin, Vector(1.0, 2.0, 3.0), 90f, 0f)
        transform.worldOrigin shouldBeCloseTo Vector(7.0, 22.0, 31.0)
    }

    test("rotateLocalToWorld follows Minecraft's yaw and pitch convention") {
        val plusZ = Vector(0.0, 0.0, 1.0)
        ResolvedTransform(world, Vector.ZERO, 90f, 0f).rotateLocalToWorld(plusZ) shouldBeCloseTo
                Vector(-1.0, 0.0, 0.0)
        ResolvedTransform(world, Vector.ZERO, 0f, -90f).rotateLocalToWorld(plusZ) shouldBeCloseTo
                Vector(0.0, 1.0, 0.0)
    }

    test("rotated local bounds swap the horizontal extents under a quarter turn") {
        val rotated = LocalBounds(-1.0, -2.0, -3.0, 1.0, 2.0, 3.0).rotated(90f, 0f)
        rotated.minX shouldBe (-3.0 plusOrMinus TOLERANCE)
        rotated.maxX shouldBe (3.0 plusOrMinus TOLERANCE)
        rotated.minY shouldBe (-2.0 plusOrMinus TOLERANCE)
        rotated.maxY shouldBe (2.0 plusOrMinus TOLERANCE)
        rotated.minZ shouldBe (-1.0 plusOrMinus TOLERANCE)
        rotated.maxZ shouldBe (1.0 plusOrMinus TOLERANCE)
    }
})
