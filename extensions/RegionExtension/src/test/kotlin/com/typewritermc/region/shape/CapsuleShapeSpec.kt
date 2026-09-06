package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.shouldBe

private const val TOLERANCE = 1e-9

class CapsuleShapeSpec : FunSpec({
    val shape = CapsuleShape(radius = 1.0, halfHeight = 2.0)

    test("contains inside, cap, and outside points") {
        shape.contains(Vector(0.0, 0.0, 0.0)) shouldBe true
        shape.contains(Vector(0.0, 2.9, 0.0)) shouldBe true
        shape.contains(Vector(0.0, 3.1, 0.0)) shouldBe false
        shape.contains(Vector(1.0, 0.0, 0.0)) shouldBe true
    }

    test("signed distance measures from the spine") {
        shape.signedDistance(Vector(0.0, 0.0, 0.0)) shouldBe (-1.0 plusOrMinus TOLERANCE)
        shape.signedDistance(Vector(0.0, 3.5, 0.0)) shouldBe (0.5 plusOrMinus TOLERANCE)
        shape.signedDistance(Vector(2.0, 0.0, 0.0)) shouldBe (1.0 plusOrMinus TOLERANCE)
    }

    test("horizontal distance uses the silhouette circle") {
        shape.signedDistanceHorizontal(Vector(0.0, 10.0, 0.0)) shouldBe (-1.0 plusOrMinus TOLERANCE)
        shape.signedDistanceHorizontal(Vector(2.0, 10.0, 0.0)) shouldBe (1.0 plusOrMinus TOLERANCE)
    }

    test("nearest outside projects onto the surface") {
        shape.nearestOutside(Vector(0.5, 0.0, 0.0)) shouldBe Vector(1.0, 0.0, 0.0)
    }

    test("normals point away from the spine") {
        shape.outwardNormals(Vector(0.0, 3.0, 0.0)) shouldBe listOf(Vector(0.0, 1.0, 0.0))
    }

    test("boundary samples lie on the boundary") {
        shape.shouldSampleOnBoundary()
    }
})
