package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.doubles.shouldBeLessThan
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import kotlin.math.abs

class RayCastSpec : FunSpec({
    val box = CuboidShape(10.0, 5.0, 10.0)
    val sphere = SphereShape(6.0)
    val cone = ConeShape(length = 5.0, halfAngleDegrees = 30.0)

    val east = Vector(1.0, 0.0, 0.0)
    val west = Vector(-1.0, 0.0, 0.0)

    test("a ray from inside leaves through the face it is aimed at") {
        val hit = box.raycastBoundary(Vector.ZERO, east).shouldNotBeNull()
        hit.x shouldBe (10.0 plusOrMinus 0.01)
        abs(box.signedDistance(hit)) shouldBeLessThan 0.01
    }

    test("a ray from outside stops at the near face, not the far one") {
        val hit = box.raycastBoundary(Vector(-40.0, 0.0, 0.0), east).shouldNotBeNull()
        hit.x shouldBe (-10.0 plusOrMinus 0.01)
    }

    test("a ray aimed away from the region reports a miss") {
        box.raycastBoundary(Vector(-40.0, 0.0, 0.0), west).shouldBeNull()
    }

    test("a ray beyond the reach of the march reports a miss") {
        box.raycastBoundary(Vector(-500.0, 0.0, 0.0), east).shouldBeNull()
    }

    test("a ray grazing the silhouette is not stepped over") {
        // The chord here is 0.2 blocks, shorter than the march step, so the coarse samples
        // both land outside and only the refinement finds the pair of crossings.
        val hit = sphere.raycastBoundary(Vector(5.995, 0.0, -20.0), Vector(0.0, 0.0, 1.0)).shouldNotBeNull()
        abs(sphere.signedDistance(hit)) shouldBeLessThan 0.01
    }

    test("a ray across a narrow cone near its apex is not stepped over") {
        val narrow = ConeShape(length = 20.0, halfAngleDegrees = 5.0)
        val hit = narrow.raycastBoundary(Vector(-5.1, 0.0, 1.0), east).shouldNotBeNull()
        abs(narrow.signedDistance(hit)) shouldBeLessThan 0.01
    }

    test("a curved boundary is hit on its surface") {
        val hit = sphere.raycastBoundary(Vector(0.0, 0.0, -20.0), Vector(0.0, 0.0, 1.0)).shouldNotBeNull()
        abs(sphere.signedDistance(hit)) shouldBeLessThan 0.01
    }
})
