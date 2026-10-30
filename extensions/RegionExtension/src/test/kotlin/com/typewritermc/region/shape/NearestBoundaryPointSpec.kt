package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import io.kotest.assertions.withClue
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.doubles.shouldBeLessThan
import io.kotest.matchers.shouldBe
import kotlin.math.abs

/**
 * The editor aims its outline and its tools at the boundary point nearest to the player's eye,
 * from inside a region as often as from outside it, so every shape has to answer both.
 */
class NearestBoundaryPointSpec : FunSpec({
    val shapes = listOf(
        SphereShape(6.0),
        CuboidShape(3.0, 2.0, 4.0),
        EllipsoidShape(5.0, 2.0, 3.0),
        CapsuleShape(2.0, 3.0),
        ConeShape(8.0, 30.0),
        PolygonShape(
            listOf(Vector(-3.0, 0.0, -3.0), Vector(3.0, 0.0, -3.0), Vector(3.0, 0.0, 3.0), Vector(-3.0, 0.0, 3.0)),
            halfHeight = 2.0,
        ),
    )
    val queries = listOf(
        Vector(0.0, 0.0, 0.0),
        Vector(0.0, 0.5, 1.0),
        Vector(0.0, 30.0, 0.0),
        Vector(12.0, -1.0, 4.0),
        Vector(0.0, 0.0, -5.0),
    )

    test("every shape answers a point on its own boundary, from inside and outside") {
        for (shape in shapes) {
            for (query in queries) {
                val nearest = shape.nearestBoundaryPoint(query)
                withClue("$shape at $query answered $nearest") {
                    abs(shape.signedDistance(nearest)) shouldBeLessThan 1e-6
                }
            }
        }
    }

    test("the exact center of a sphere still has a nearest boundary point") {
        SphereShape(1.0).nearestBoundaryPoint(Vector.ZERO).length shouldBe (1.0 plusOrMinus 1e-9)
    }

    test("straight behind the cone's apex projects onto the apex") {
        ConeShape(8.0, 30.0).nearestBoundaryPoint(Vector(0.0, 0.0, -5.0)).length shouldBeLessThan 1e-9
    }
})
