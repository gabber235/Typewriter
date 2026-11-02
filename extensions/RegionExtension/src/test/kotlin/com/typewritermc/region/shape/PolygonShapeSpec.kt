package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.doubles.shouldBeGreaterThan
import io.kotest.matchers.shouldBe

private const val TOLERANCE = 1e-9

class PolygonShapeSpec : FunSpec({
    val square = PolygonShape(
        points = listOf(
            Vector(-2.0, 0.0, -2.0),
            Vector(2.0, 0.0, -2.0),
            Vector(2.0, 0.0, 2.0),
            Vector(-2.0, 0.0, 2.0),
        ),
        halfHeight = 1.0,
    )

    test("a star's tip points out of the star, not along one of its edges") {
        val star = PolygonShape(
            points = (0 until 10).map { index ->
                val radius = if (index % 2 == 0) 10.0 else 4.0
                val angle = 2 * kotlin.math.PI * index / 10
                Vector(kotlin.math.cos(angle) * radius, 0.0, kotlin.math.sin(angle) * radius)
            },
            halfHeight = 3.0,
        )
        val tip = Vector(10.0, 0.0, 0.0)
        val normal = star.outwardNormals(tip).single()

        normal.x shouldBeGreaterThan 0.9
        // Stepping out along it leaves the star, and stepping in along it enters.
        star.signedDistance(tip + normal * 0.5) shouldBeGreaterThan 0.0
        (star.signedDistance(tip - normal * 0.5) < 0.0) shouldBe true
    }

    test("a vertex dropped on one already placed does not turn the corner's normal along a wall") {
        val doubled = PolygonShape(
            points = listOf(
                Vector(0.0, 0.0, 0.0),
                Vector(10.0, 0.0, 0.0),
                Vector(10.0, 0.0, 0.0),
                Vector(10.0, 0.0, 10.0),
                Vector(0.0, 0.0, 10.0),
            ),
            halfHeight = 2.0,
        )
        val corner = Vector(10.0, 0.0, 0.0)
        val normal = doubled.outwardNormals(corner).single()

        normal.x shouldBeGreaterThan 0.5
        (normal.z < -0.5) shouldBe true
        doubled.signedDistance(corner + normal * 0.5) shouldBeGreaterThan 0.0
    }

    test("contains respects the outline and the height") {
        square.contains(Vector(0.0, 0.0, 0.0)) shouldBe true
        square.contains(Vector(0.0, 1.5, 0.0)) shouldBe false
        square.contains(Vector(3.0, 0.0, 0.0)) shouldBe false
    }

    test("signed distance combines lateral and vertical parts") {
        square.signedDistance(Vector(0.0, 0.0, 0.0)) shouldBe (-1.0 plusOrMinus TOLERANCE)
        square.signedDistance(Vector(0.0, 0.0, 3.0)) shouldBe (1.0 plusOrMinus TOLERANCE)
    }

    test("horizontal distance ignores the caps entirely") {
        square.signedDistanceHorizontal(Vector(0.0, 0.0, 0.0)) shouldBe (-2.0 plusOrMinus TOLERANCE)
        square.signedDistanceHorizontal(Vector(0.0, 40.0, 0.0)) shouldBe (-2.0 plusOrMinus TOLERANCE)
        square.signedDistanceHorizontal(Vector(0.0, 0.0, 3.0)) shouldBe (1.0 plusOrMinus TOLERANCE)
    }

    test("a degenerate polygon contains nothing and reports far distances") {
        val degenerate = PolygonShape(points = emptyList(), halfHeight = 1.0)
        degenerate.contains(Vector(0.0, 0.0, 0.0)) shouldBe false
        degenerate.signedDistance(Vector(0.0, 0.0, 0.0)) shouldBeGreaterThan 1.0e8
        degenerate.signedDistanceHorizontal(Vector(0.0, 0.0, 0.0)) shouldBeGreaterThan 1.0e8
        degenerate.sampleBoundary(0.5).toList().shouldBeEmpty()
    }

    test("boundary samples lie on the boundary") {
        square.shouldSampleOnBoundary()
    }
})
