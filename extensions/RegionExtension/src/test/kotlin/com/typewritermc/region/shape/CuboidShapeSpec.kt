package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.shouldBe
import kotlin.math.sqrt

private const val TOLERANCE = 1e-9

class CuboidShapeSpec : FunSpec({
    val shape = CuboidShape(2.0, 1.0, 3.0)

    test("contains inside, boundary, and outside points") {
        shape.contains(Vector(0.0, 0.0, 0.0)) shouldBe true
        shape.contains(Vector(2.0, 1.0, 3.0)) shouldBe true
        shape.contains(Vector(2.1, 0.0, 0.0)) shouldBe false
    }

    test("signed distance is negative inside and euclidean outside") {
        shape.signedDistance(Vector(0.0, 0.0, 0.0)) shouldBe (-1.0 plusOrMinus TOLERANCE)
        shape.signedDistance(Vector(3.0, 0.0, 0.0)) shouldBe (1.0 plusOrMinus TOLERANCE)
        shape.signedDistance(Vector(3.0, 2.0, 0.0)) shouldBe (sqrt(2.0) plusOrMinus TOLERANCE)
    }

    test("horizontal distance ignores floor and ceiling") {
        shape.signedDistanceHorizontal(Vector(0.0, 0.0, 0.0)) shouldBe (-2.0 plusOrMinus TOLERANCE)
        shape.signedDistanceHorizontal(Vector(0.0, 50.0, 0.0)) shouldBe (-2.0 plusOrMinus TOLERANCE)
        shape.signedDistanceHorizontal(Vector(3.0, 50.0, 0.0)) shouldBe (1.0 plusOrMinus TOLERANCE)
    }

    test("a flat room reports the lateral distance horizontally") {
        val room = CuboidShape(10.0, 1.0, 10.0)
        room.signedDistance(Vector.ZERO) shouldBe (-1.0 plusOrMinus TOLERANCE)
        room.signedDistanceHorizontal(Vector.ZERO) shouldBe (-10.0 plusOrMinus TOLERANCE)
    }

    test("nearest outside projects onto the closest face") {
        shape.nearestOutside(Vector(1.5, 0.0, 0.0)) shouldBe Vector(2.0, 0.0, 0.0)
        shape.nearestOutside(Vector(5.0, 0.0, 0.0)) shouldBe Vector(2.0, 0.0, 0.0)
    }

    test("corners return one normal per touching face") {
        shape.outwardNormals(Vector(2.0, 1.0, 3.0)).size shouldBe 3
        shape.outwardNormals(Vector(1.99, 0.0, 0.0)) shouldBe listOf(Vector(1.0, 0.0, 0.0))
    }

    test("a point past an edge points away from the edge, not between the two faces") {
        val room = CuboidShape(10.0, 5.0, 10.0)
        val normals = room.outwardNormals(Vector(10.001, 8.0, 0.0))
        normals.size shouldBe 1

        val direction = normals.single()
        direction.y shouldBe (1.0 plusOrMinus 1e-3)
        direction.x shouldBe (0.0 plusOrMinus 1e-3)
        direction.length shouldBe (1.0 plusOrMinus TOLERANCE)
    }

    test("the normal does not swing as a player crosses a face plane") {
        val room = CuboidShape(10.0, 5.0, 10.0)
        val inside = room.outwardNormals(Vector(9.999, 8.0, 0.0)).single()
        val outside = room.outwardNormals(Vector(10.001, 8.0, 0.0)).single()

        outside.x shouldBe (inside.x plusOrMinus 1e-3)
        outside.y shouldBe (inside.y plusOrMinus 1e-3)
    }

    test("boundary samples lie on the boundary") {
        shape.shouldSampleOnBoundary()
    }

    test("boundary samples cover every corner exactly once for uneven sizes") {
        val uneven = CuboidShape(3.7, 1.3, 2.9)
        uneven.shouldSampleOnBoundary()

        val samples = uneven.sampleBoundary(0.5).toList()
        for (cornerX in listOf(-3.7, 3.7)) for (cornerY in listOf(-1.3, 1.3)) for (cornerZ in listOf(-2.9, 2.9)) {
            samples.count { it.x == cornerX && it.y == cornerY && it.z == cornerZ } shouldBe 1
        }
    }
})
