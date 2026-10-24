package com.typewritermc.region.data

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.shouldBe

private infix fun Vector.shouldBeCloseTo(expected: Vector) {
    x shouldBe (expected.x plusOrMinus 1e-6)
    y shouldBe (expected.y plusOrMinus 1e-6)
    z shouldBe (expected.z plusOrMinus 1e-6)
}

class RotationMathSpec : FunSpec({
    val east = Vector(1.0, 0.0, 0.0)
    val up = Vector(0.0, 1.0, 0.0)
    val south = Vector(0.0, 0.0, 1.0)

    test("a zero rotation is the identity") {
        rotationMatrix(0f, 0f, 0f) * Vector(1.0, 2.0, 3.0) shouldBeCloseTo Vector(1.0, 2.0, 3.0)
    }

    test("without roll the matrix matches the transform's yaw and pitch convention") {
        val world = World("rotation-world")
        val transform = ResolvedTransform(world, Vector.ZERO, 37f, -20f)
        val matrix = rotationMatrix(37f, -20f, 0f)
        for (sample in listOf(east, up, south, Vector(1.0, -2.0, 3.0))) {
            matrix * sample shouldBeCloseTo transform.rotateLocalToWorld(sample)
        }
    }

    test("roll turns around the facing axis and leaves it in place") {
        val matrix = rotationMatrix(0f, 0f, 45f)
        matrix * south shouldBeCloseTo south
        (matrix * up).y shouldBe (Math.cos(Math.toRadians(45.0)) plusOrMinus 1e-9)
    }

    test("the transposed product inverts the rotation") {
        val matrix = rotationMatrix(51f, 33f, -70f)
        val sample = Vector(1.5, -2.5, 0.75)
        matrix.transposedTimes(matrix * sample) shouldBeCloseTo sample
    }

    test("the tilt readout ignores yaw and combines pitch with roll") {
        tiltDegrees(30f, 0f) shouldBe (30.0 plusOrMinus 1e-6)
        tiltDegrees(0f, 40f) shouldBe (40.0 plusOrMinus 1e-6)
        val combined = Math.toDegrees(Math.acos(Math.cos(Math.toRadians(30.0)) * Math.cos(Math.toRadians(40.0))))
        tiltDegrees(30f, 40f) shouldBe (combined plusOrMinus 1e-6)
    }

    test("a rolled transform still round trips between frames") {
        val world = World("rotation-world")
        val transform = ResolvedTransform(world, Vector(3.0, 4.0, 5.0), 20f, 35f, 50f)
        val sample = Vector(1.0, 2.0, -3.0)
        transform.toLocal(transform.toWorld(sample)) shouldBeCloseTo sample
    }
})
