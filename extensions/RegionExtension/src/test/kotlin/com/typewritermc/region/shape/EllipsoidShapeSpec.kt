package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.shouldBe

private const val TOLERANCE = 1e-9

class EllipsoidShapeSpec : FunSpec({
    val shape = EllipsoidShape(2.0, 1.0, 3.0)

    test("contains inside, boundary, and outside points") {
        shape.contains(Vector(0.0, 0.0, 0.0)) shouldBe true
        shape.contains(Vector(2.0, 0.0, 0.0)) shouldBe true
        shape.contains(Vector(0.0, 1.1, 0.0)) shouldBe false
    }

    test("signed distance is exact along every axis") {
        shape.signedDistance(Vector(0.0, 0.0, 0.0)) shouldBe (-1.0 plusOrMinus TOLERANCE)
        shape.signedDistance(Vector(4.0, 0.0, 0.0)) shouldBe (2.0 plusOrMinus TOLERANCE)
        shape.signedDistance(Vector(0.0, 3.0, 0.0)) shouldBe (2.0 plusOrMinus TOLERANCE)
        shape.signedDistance(Vector(0.0, 0.0, 7.0)) shouldBe (4.0 plusOrMinus TOLERANCE)
    }

    test("a flattened ellipsoid reports blocks, not blocks scaled by the axis ratio") {
        val flat = EllipsoidShape(10.0, 1.5, 10.0)
        flat.signedDistance(Vector(0.0, 0.0, 14.0)) shouldBe (4.0 plusOrMinus TOLERANCE)
        EllipsoidShape(10.0, 1.0, 1.0)
            .signedDistance(Vector(20.0, 0.0, 0.0)) shouldBe (10.0 plusOrMinus TOLERANCE)
    }

    test("a uniform ellipsoid agrees with the sphere exactly") {
        val uniform = EllipsoidShape(4.0, 4.0, 4.0)
        val sphere = SphereShape(4.0)
        for (point in listOf(Vector(9.0, 0.0, 0.0), Vector(1.0, 2.0, 3.0), Vector(-7.0, 5.0, 2.0))) {
            uniform.signedDistance(point) shouldBe (sphere.signedDistance(point) plusOrMinus TOLERANCE)
        }
    }

    test("horizontal distance uses the silhouette ellipse") {
        shape.signedDistanceHorizontal(Vector(0.0, 9.0, 0.0)) shouldBe (-2.0 plusOrMinus TOLERANCE)
        shape.signedDistanceHorizontal(Vector(4.0, 9.0, 0.0)) shouldBe (2.0 plusOrMinus TOLERANCE)
    }

    test("nearest outside projects onto the surface") {
        shape.nearestOutside(Vector(4.0, 0.0, 0.0)) shouldBe Vector(2.0, 0.0, 0.0)
    }

    test("normals point outward") {
        shape.outwardNormals(Vector(0.0, 2.0, 0.0)) shouldBe listOf(Vector(0.0, 1.0, 0.0))
    }

    test("boundary samples lie on the boundary") {
        shape.shouldSampleOnBoundary()
    }

    test("depth inside is measured against the nearest surface, not the longest axis") {
        val pancake = EllipsoidShape(20.0, 2.0, 20.0)
        pancake.signedDistance(Vector(0.001, 0.0, 0.0)) shouldBe (-2.0 plusOrMinus 1e-3)
        pancake.signedDistance(Vector(19.0, 0.0, 0.0)) shouldBe (-0.5945884 plusOrMinus 1e-5)
        pancake.signedDistance(Vector(0.0, 1.5, 0.0)) shouldBe (-0.5 plusOrMinus TOLERANCE)
    }

    test("depth is continuous through the center") {
        val pancake = EllipsoidShape(20.0, 2.0, 20.0)
        val atCenter = pancake.signedDistance(Vector.ZERO)
        val besideCenter = pancake.signedDistance(Vector(1e-5, 0.0, 0.0))
        atCenter shouldBe (-2.0 plusOrMinus TOLERANCE)
        besideCenter shouldBe (atCenter plusOrMinus 1e-4)
    }

    test("distance outside is measured to the closest point, not along the ray from the center") {
        val pancake = EllipsoidShape(20.0, 2.0, 20.0)
        pancake.signedDistance(Vector(42.43, 4.243, 0.0)) shouldBe (22.8247 plusOrMinus 1e-3)
        pancake.signedDistance(Vector(21.0, 1.0, 0.0)) shouldBe (1.3558 plusOrMinus 1e-3)
    }

    test("the nearest surface at the center is on the shortest axis") {
        val pancake = EllipsoidShape(20.0, 2.0, 20.0)
        pancake.nearestOutside(Vector.ZERO) shouldBe Vector(0.0, 2.0, 0.0)
        pancake.outwardNormals(Vector.ZERO) shouldBe listOf(Vector(0.0, 1.0, 0.0))
        // A hair off center answers the same way, so a barrier does not swing between the two.
        val beside = Vector(9e-4, 0.0, 0.0)
        val besideCenter = pancake.nearestOutside(beside)
        besideCenter.y shouldBe (2.0 plusOrMinus 1e-6)
        (besideCenter - beside).length shouldBe (2.0 plusOrMinus 1e-4)
    }

    test("a point a rounding error off the flat axis stays finite") {
        val pancake = EllipsoidShape(20.0, 2.0, 20.0)
        for (y in listOf(1e-16, 2e-16, 1e-15, 5e-16)) {
            val point = Vector(1e-9, y, 1e-9)
            val distance = pancake.signedDistance(point)
            distance.isFinite() shouldBe true
            distance shouldBe (-2.0 plusOrMinus 1e-6)

            val surface = pancake.nearestOutside(point)
            surface.y.isFinite() shouldBe true
            pancake.outwardNormals(point).single().length shouldBe (1.0 plusOrMinus 1e-9)
        }
    }

    test("the reported distance is the distance to the reported nearest point") {
        val pancake = EllipsoidShape(20.0, 2.0, 20.0)
        for (point in listOf(Vector(25.0, 6.0, 3.0), Vector(-30.0, 1.0, 12.0), Vector(0.5, 0.2, 0.1))) {
            val surface = pancake.nearestOutside(point)
            val gap = (surface - point).length
            kotlin.math.abs(pancake.signedDistance(point)) shouldBe (gap plusOrMinus 1e-6)
            pancake.signedDistance(surface) shouldBe (0.0 plusOrMinus 1e-6)
        }
    }
})
