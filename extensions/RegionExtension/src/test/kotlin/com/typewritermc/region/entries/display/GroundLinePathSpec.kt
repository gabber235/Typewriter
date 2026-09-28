package com.typewritermc.region.entries.display

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.doubles.shouldBeLessThan
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe

class GroundLinePathSpec : FunSpec({
    fun point(x: Double, z: Double) = GroundOutlinePoint(Vector(x, 64.0, z), Vector.ZERO)

    /** A ten by ten square walked east, then south, then west, then north. */
    fun square(step: Double = 1.0): List<GroundOutlinePoint> {
        val points = mutableListOf<GroundOutlinePoint>()
        var value = 0.0
        while (value < 10.0) { points += point(value, 0.0); value += step }
        value = 0.0
        while (value < 10.0) { points += point(10.0, value); value += step }
        value = 10.0
        while (value > 0.0) { points += point(value, 10.0); value -= step }
        value = 10.0
        while (value > 0.0) { points += point(0.0, value); value -= step }
        return points
    }

    test("walking east then south then west then north is clockwise seen from above") {
        GroundLinePath(square()).clockwiseDirection shouldBe 1
    }

    test("the reversed loop is counter clockwise") {
        GroundLinePath(square().reversed()).clockwiseDirection shouldBe -1
    }

    test("the arc length of the loop is its perimeter") {
        GroundLinePath(square()).totalArc shouldBe (40.0 plusOrMinus 1e-6)
    }

    test("walking a full perimeter returns to the start") {
        val path = GroundLinePath(square())
        val start = path.pointAt(0.0).shouldNotBeNull()
        val around = path.pointAt(path.totalArc - 1e-9).shouldNotBeNull()
        (around.position - start.position).length shouldBeLessThan 0.01
    }

    test("an arc lands where the distance says it should") {
        val path = GroundLinePath(square())
        val quarter = path.pointAt(10.0).shouldNotBeNull()
        quarter.position.x shouldBe (10.0 plusOrMinus 0.01)
        quarter.position.z shouldBe (0.0 plusOrMinus 0.01)
    }

    test("the tangent along the first edge points east") {
        val path = GroundLinePath(square())
        val tangent = path.pointAt(5.0).shouldNotBeNull().tangent
        tangent.x shouldBe (1.0 plusOrMinus 0.01)
        tangent.z shouldBe (0.0 plusOrMinus 0.01)
    }

    test("a hole in the loop is never walked across") {
        val broken = listOf(point(0.0, 0.0), point(1.0, 0.0), point(20.0, 0.0), point(21.0, 0.0))
        val path = GroundLinePath(broken)
        // The stretch from x=1 to x=20 is a hole, so an arc inside it has no point.
        path.pointAt(5.0).shouldBeNull()
        path.pointAt(0.5).shouldNotBeNull()
    }

    test("an arc landing exactly on the vertex that starts a hole returns that vertex") {
        val broken = listOf(point(0.0, 0.0), point(1.0, 0.0), point(20.0, 0.0), point(21.0, 0.0))
        val path = GroundLinePath(broken)
        val vertex = path.pointAt(1.0).shouldNotBeNull()
        vertex.position.x shouldBe (1.0 plusOrMinus 1e-9)
        vertex.position.z shouldBe (0.0 plusOrMinus 1e-9)
        path.pointAt(5.0).shouldBeNull()
    }

    test("a hole wrapping from the last vertex back to the first still blocks its interior") {
        val broken = listOf(point(0.0, 0.0), point(1.0, 0.0), point(20.0, 0.0), point(21.0, 0.0))
        val path = GroundLinePath(broken)
        // The wrap from x=21 back to x=0 is also a hole, so an arc inside it has no point.
        val lastVertex = path.pointAt(21.0).shouldNotBeNull()
        lastVertex.position.x shouldBe (21.0 plusOrMinus 1e-9)
        lastVertex.position.z shouldBe (0.0 plusOrMinus 1e-9)
        path.pointAt(30.0).shouldBeNull()
    }

    test("a two point path has tangents along the segment, not zero") {
        val path = GroundLinePath(listOf(point(0.0, 0.0), point(10.0, 0.0)))
        val first = path.vertices[0].tangent
        first.x shouldBe (1.0 plusOrMinus 1e-9)
        first.z shouldBe (0.0 plusOrMinus 1e-9)
        val second = path.vertices[1].tangent
        second.x shouldBe (1.0 plusOrMinus 1e-9)
        second.z shouldBe (0.0 plusOrMinus 1e-9)
    }
})
