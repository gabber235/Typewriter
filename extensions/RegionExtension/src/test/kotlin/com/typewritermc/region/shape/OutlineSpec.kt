package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.doubles.shouldBeLessThan
import io.kotest.matchers.ints.shouldBeGreaterThanOrEqual
import io.kotest.matchers.shouldBe
import kotlin.math.abs

class OutlineSpec : FunSpec({
    fun Shape.outlinePointsLieOnBoundary(tolerance: Double = 1e-6) {
        val polylines = outlinePolylines()
        polylines.shouldNotBeEmpty()
        for ((points) in polylines) {
            for (point in points) {
                abs(signedDistance(point)) shouldBeLessThan tolerance
            }
        }
    }

    test("cuboid edges lie on the boundary") {
        CuboidShape(2.0, 3.0, 4.0).outlinePointsLieOnBoundary()
    }

    test("cuboid outline is two rectangles and four verticals") {
        val polylines = CuboidShape(2.0, 3.0, 4.0).outlinePolylines()
        polylines.count { it.closed } shouldBe 2
        polylines.count { !it.closed } shouldBe 4
    }

    test("sphere rings lie on the boundary") {
        SphereShape(5.0).outlinePointsLieOnBoundary()
    }

    test("ellipsoid rings lie on the boundary") {
        EllipsoidShape(2.0, 5.0, 3.0).outlinePointsLieOnBoundary()
    }

    test("capsule rings and profile loops lie on the boundary") {
        CapsuleShape(1.5, 3.0).outlinePointsLieOnBoundary(1e-6)
    }

    test("cone rim, generatrices and cap arcs lie on the boundary") {
        ConeShape(10.0, 30.0).outlinePointsLieOnBoundary(1e-6)
    }

    test("the cone outline draws lines from the apex to the rim") {
        val polylines = ConeShape(10.0, 30.0).outlinePolylines()
        val generatrices = polylines.filter { !it.closed && it.points.first() == Vector.ZERO }
        generatrices.size shouldBeGreaterThanOrEqual 4
        for ((points) in generatrices) {
            points.last().z shouldBe 10.0 * kotlin.math.cos(Math.toRadians(30.0))
        }
    }

    test("polygon prism edges lie on the boundary") {
        val shape = PolygonShape(
            listOf(Vector(-3.0, 0.0, -3.0), Vector(3.0, 0.0, -3.0), Vector(3.0, 0.0, 3.0), Vector(-3.0, 0.0, 3.0)),
            2.0,
        )
        shape.outlinePointsLieOnBoundary()
    }

    test("a degenerate polygon has no outline") {
        PolygonShape(emptyList(), 2.0).outlinePolylines() shouldBe emptyList()
    }

    test("closed polylines connect back to the start in their segments") {
        val square = OutlinePolyline(
            listOf(Vector(0, 0, 0), Vector(1, 0, 0), Vector(1, 0, 1), Vector(0, 0, 1)),
            closed = true,
        )
        val segments = square.segments()
        segments.size shouldBe 4
        segments.last() shouldBe (Vector(0, 0, 1) to Vector(0, 0, 0))
    }
})
