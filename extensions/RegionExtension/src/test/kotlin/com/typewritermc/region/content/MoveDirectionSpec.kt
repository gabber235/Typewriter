package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe

class MoveDirectionSpec : FunSpec({
    val plusX = Vector(1.0, 0.0, 0.0)
    val plusZ = Vector(0.0, 0.0, 1.0)
    val down = Vector(0.0, -1.0, 0.0)

    test("a fresh look picks the dominant horizontal axis") {
        autoMoveDirection(Vector(1.0, 0.0, 0.4), pitch = 0f) shouldBe plusX
        autoMoveDirection(Vector(0.4, 0.0, 1.0), pitch = 0f) shouldBe plusZ
        autoMoveDirection(Vector(-1.0, 0.0, 0.4), pitch = 0f) shouldBe Vector(-1.0, 0.0, 0.0)
    }

    test("the vertical axis needs a steep look to engage") {
        autoMoveDirection(plusX, pitch = 50f) shouldBe plusX
        autoMoveDirection(plusX, pitch = 60f) shouldBe down
        autoMoveDirection(plusX, pitch = -60f) shouldBe Vector(0.0, 1.0, 0.0)
    }

    test("the vertical axis holds until the look flattens well below the entry angle") {
        autoMoveDirection(plusX, pitch = 45f, previous = down) shouldBe down
        autoMoveDirection(plusX, pitch = 30f, previous = down) shouldBe plusX
    }

    test("a held horizontal axis survives a shallow diagonal") {
        autoMoveDirection(Vector(1.0, 0.0, 1.2), pitch = 0f, previous = plusX) shouldBe plusX
    }

    test("a clearly dominant other axis takes over") {
        autoMoveDirection(Vector(0.6, 0.0, 1.0), pitch = 0f, previous = plusX) shouldBe plusZ
        autoMoveDirection(Vector(1.0, 0.0, 0.6), pitch = 0f, previous = plusZ) shouldBe plusX
    }

    test("the sign always follows the look along the held axis") {
        autoMoveDirection(Vector(-1.0, 0.0, 0.2), pitch = 0f, previous = plusX) shouldBe Vector(-1.0, 0.0, 0.0)
    }
})
