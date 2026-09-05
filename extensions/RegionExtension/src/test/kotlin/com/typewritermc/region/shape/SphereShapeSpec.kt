package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.shouldBe

private const val TOLERANCE = 1e-9

class SphereShapeSpec : FunSpec({
    val shape = SphereShape(2.0)

    test("contains inside, boundary, and outside points") {
        shape.contains(Vector(0.0, 0.0, 0.0)) shouldBe true
        shape.contains(Vector(2.0, 0.0, 0.0)) shouldBe true
        shape.contains(Vector(2.1, 0.0, 0.0)) shouldBe false
    }

    test("signed distance") {
        shape.signedDistance(Vector(0.0, 0.0, 0.0)) shouldBe (-2.0 plusOrMinus TOLERANCE)
        shape.signedDistance(Vector(3.0, 0.0, 0.0)) shouldBe (1.0 plusOrMinus TOLERANCE)
    }

    test("horizontal distance uses the silhouette circle") {
        shape.signedDistanceHorizontal(Vector(0.0, 5.0, 0.0)) shouldBe (-2.0 plusOrMinus TOLERANCE)
        shape.signedDistanceHorizontal(Vector(3.0, 5.0, 0.0)) shouldBe (1.0 plusOrMinus TOLERANCE)
    }

    test("nearest outside projects onto the surface") {
        shape.nearestOutside(Vector(1.0, 0.0, 0.0)) shouldBe Vector(2.0, 0.0, 0.0)
    }

    test("normals point radially outward") {
        shape.outwardNormals(Vector(0.0, 3.0, 0.0)) shouldBe listOf(Vector(0.0, 1.0, 0.0))
    }

    test("boundary samples lie on the boundary") {
        shape.shouldSampleOnBoundary()
    }
})
