package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe

class FaceMathSpec : FunSpec({
    val boxFaces = listOf(
        RegionFace("+x", "+X face", Vector(2.0, 0.0, 0.0), Vector(1, 0, 0), Vector(0, 1, 0), Vector(0, 0, 1), 2.0, 2.0),
        RegionFace(
            "-x",
            "-X face",
            Vector(-2.0, 0.0, 0.0),
            Vector(-1, 0, 0),
            Vector(0, 0, 1),
            Vector(0, 1, 0),
            2.0,
            2.0
        ),
        RegionFace(
            "+y",
            "top face",
            Vector(0.0, 2.0, 0.0),
            Vector(0, 1, 0),
            Vector(0, 0, 1),
            Vector(1, 0, 0),
            2.0,
            2.0
        ),
    )

    test("the nearest face the ray hits wins, not the one behind it") {
        val face = pickFace(boxFaces, localEye = Vector(10.0, 0.0, 0.0), localDirection = Vector(-1, 0, 0))
        face.shouldNotBeNull().id shouldBe "+x"
    }

    test("looking down from above picks the top face") {
        val face = pickFace(boxFaces, localEye = Vector(0.5, 10.0, 0.5), localDirection = Vector(0, -1, 0))
        face.shouldNotBeNull().id shouldBe "+y"
    }

    test("looking away from every face picks nothing") {
        pickFace(boxFaces, localEye = Vector(10.0, 0.0, 0.0), localDirection = Vector(1, 0, 0)).shouldBeNull()
    }

    test("a ray missing all panels falls back to the nearest face on the player's side") {
        val face =
            pickFace(boxFaces, localEye = Vector(10.0, 0.0, 0.0), localDirection = Vector(-0.7, 0.0, 0.7).normalize())
        face.shouldNotBeNull().id shouldBe "+x"
    }

    test("a corner ray hitting two faces keeps the previously targeted one") {
        val eye = Vector(10.0, 10.0, 0.0)
        val direction = Vector(-1.0, -1.0, 0.0).normalize()
        pickFace(boxFaces, eye, direction).shouldNotBeNull().id shouldBe "+x"
        pickFace(boxFaces, eye, direction, preferredId = "+y").shouldNotBeNull().id shouldBe "+y"
    }

    test("the near fallback sticks to the previous face while it stays nearly as close") {
        val eye = Vector(6.0, 6.5, -5.0)
        val direction = Vector(0, 0, 1)
        pickFace(boxFaces, eye, direction).shouldNotBeNull().id shouldBe "+y"
        pickFace(boxFaces, eye, direction, preferredId = "+x").shouldNotBeNull().id shouldBe "+x"
    }

    test("drag delta is the normal-line coordinate closest to the view ray") {
        val delta = dragDelta(
            eye = Vector(3.0, 10.0, 0.0),
            direction = Vector(0, -1, 0),
            faceCenter = Vector.ZERO,
            faceNormal = Vector(1, 0, 0),
        )
        delta shouldBe (3.0 plusOrMinus 1e-9)
    }

    test("a drag parallel to the normal reports zero") {
        val delta = dragDelta(
            eye = Vector(0.0, 0.0, -5.0),
            direction = Vector(0, 0, 1),
            faceCenter = Vector.ZERO,
            faceNormal = Vector(0, 0, 1),
        )
        delta shouldBe (0.0 plusOrMinus 1e-9)
    }

    test("quarter grid snapping rounds to the nearest quarter, negatives included") {
        snapToQuarterGrid(0.3) shouldBe 0.25
        snapToQuarterGrid(0.38) shouldBe 0.5
        snapToQuarterGrid(-0.3) shouldBe -0.25
        snapToQuarterGrid(2.0) shouldBe 2.0
    }

    test("pushing follows the view: a face looking back at the player steps inward") {
        pushPullSign(Vector(0, 0, 1), Vector(0, 0, 1)) shouldBe 1.0
        pushPullSign(Vector(0, 0, 1), Vector(0, 0, -1)) shouldBe -1.0
        pushPullSign(Vector(0, 0, 1), Vector(1, 0, 0)) shouldBe 1.0
    }
})
