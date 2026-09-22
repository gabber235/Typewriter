package com.typewritermc.entity.entries.activity

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.floats.plusOrMinus
import io.kotest.matchers.shouldBe
import kotlin.math.sqrt

class LookRotationSpec : FunSpec({
    context("getLookPitch") {
        test("a target straight ahead and as far up as it is away is 45 degrees up") {
            getLookPitch(3.0, 3.0, 0.0) shouldBe (-45f plusOrMinus 0.01f)
        }

        test("a diagonal target measures its horizontal distance along the diagonal") {
            getLookPitch(1.0, sqrt(2.0), 1.0) shouldBe (-45f plusOrMinus 0.01f)
            getLookPitch(-2.0, -sqrt(8.0), 2.0) shouldBe (45f plusOrMinus 0.01f)
        }

        test("a target on the same height keeps the head level") {
            getLookPitch(1.0, 0.0, 1.0) shouldBe (0f plusOrMinus 0.01f)
        }
    }
})
