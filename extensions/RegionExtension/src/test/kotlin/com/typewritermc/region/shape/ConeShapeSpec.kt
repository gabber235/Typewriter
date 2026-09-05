package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.shouldBe
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sqrt

private const val TOLERANCE = 1e-9

class ConeShapeSpec : FunSpec({
    val shape = ConeShape(length = 8.0, halfAngleDegrees = 30.0)

    test("contains the apex, the axis, and rejects points behind or beside") {
        shape.contains(Vector(0.0, 0.0, 0.0)) shouldBe true
        shape.contains(Vector(0.0, 0.0, 1.0)) shouldBe true
        shape.contains(Vector(0.0, 0.0, 8.0)) shouldBe true
        shape.contains(Vector(0.0, 0.0, -0.1)) shouldBe false
        shape.contains(Vector(1.0, 0.0, 1.0)) shouldBe false
        shape.contains(Vector(0.0, 0.0, 8.1)) shouldBe false
    }

    test("signed distance inside takes the closer of cap and lateral surface") {
        shape.signedDistance(Vector(0.0, 0.0, 4.0)) shouldBe (-2.0 plusOrMinus TOLERANCE)
        shape.signedDistance(Vector(0.0, 0.0, 9.0)) shouldBe (1.0 plusOrMinus TOLERANCE)
    }

    test("horizontal distance equals the meridian slice distance") {
        shape.signedDistanceHorizontal(Vector(0.0, 5.0, 4.0)) shouldBe (-2.0 plusOrMinus TOLERANCE)
        shape.signedDistanceHorizontal(Vector(0.0, 5.0, 9.0)) shouldBe (1.0 plusOrMinus TOLERANCE)
    }

    test("the apex normal points away from the solid, not into it") {
        shape.outwardNormals(Vector(0.0, 0.0, 0.0)) shouldBe listOf(Vector(0.0, 0.0, -1.0))
    }

    test("a point past the cap gets the cap's normal, not the lateral surface's") {
        val normal = shape.outwardNormals(Vector(0.01, 0.0, 8.1)).single()
        normal.z shouldBe (0.99999 plusOrMinus 1e-4)
        normal.x shouldBe (0.00123 plusOrMinus 1e-4)
    }

    test("distance behind the apex measures to the apex, not to the extended surface") {
        val narrow = ConeShape(length = 10.0, halfAngleDegrees = 5.0)
        narrow.signedDistance(Vector(0.0, 0.0, -2.0)) shouldBe (2.0 plusOrMinus TOLERANCE)
        ConeShape(length = 5.0, halfAngleDegrees = 30.0)
            .signedDistance(Vector(0.0, 0.0, -5.0)) shouldBe (5.0 plusOrMinus TOLERANCE)
    }

    test("distance beside the cap measures to the rim") {
        ConeShape(length = 5.0, halfAngleDegrees = 30.0)
            .signedDistance(Vector(10.0, 0.0, 0.0)) shouldBe (sqrt(75.0) plusOrMinus TOLERANCE)
    }

    test("nearest outside lands on the boundary it measured to") {
        val narrow = ConeShape(length = 10.0, halfAngleDegrees = 5.0)
        narrow.nearestOutside(Vector(0.0, 0.0, -2.0)) shouldBe Vector.ZERO
        val beside = ConeShape(length = 5.0, halfAngleDegrees = 30.0).nearestOutside(Vector(10.0, 0.0, 0.0))
        beside.x shouldBe (2.5 plusOrMinus TOLERANCE)
        beside.z shouldBe (5.0 * cos(PI / 6) plusOrMinus TOLERANCE)
    }

    test("boundary samples lie on the spherical cap boundary") {
        shape.shouldSampleOnBoundary(tolerance = 1e-6)
    }
})
