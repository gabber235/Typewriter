package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe

class HitboxSamplingSpec : FunSpec({
    test("produces the full lattice including the bottom center") {
        val offsets = hitboxSampleOffsets(0.3, 1.8)
        offsets.size shouldBe 45
        offsets shouldContain Vector(0.0, 0.0, 0.0)
        offsets shouldContain Vector(0.3, 1.8, 0.3)
        offsets shouldContain Vector(-0.3, 0.9, -0.3)
        for ((x, y, z) in offsets) {
            (x in -0.3..0.3) shouldBe true
            (y in 0.0..1.8) shouldBe true
            (z in -0.3..0.3) shouldBe true
        }
    }

    test("no gap between samples is wide enough to hide a half block thick shape") {
        val offsets = hitboxSampleOffsets(0.3, 1.8)
        for (axis in listOf<(Vector) -> Double>({ it.x }, { it.y }, { it.z })) {
            val levels = offsets.map(axis).distinct().sorted()
            levels.zipWithNext { low, high -> (high - low <= 0.5) shouldBe true }
        }
    }

    test("a standing player's chest is sampled, so a narrow cone through it registers") {
        // A 5 degree cone 3 blocks from its apex is a disc about 0.5 blocks across. Aimed
        // through the chest of a player standing at the origin, some sample must land in it.
        val cone = ConeShape(length = 20.0, halfAngleDegrees = 5.0)
        val apexHeight = 1.2
        val inside = hitboxSampleOffsets(0.3, 1.8).any { offset ->
            cone.contains(Vector(offset.x, offset.y - apexHeight, offset.z + 3.0))
        }
        inside shouldBe true
    }

    test("a giant player's lattice stays bounded, at a coarser spacing") {
        // The vanilla scale attribute reaches 16, which is a box 9.6 wide and 28.8 tall. At the
        // normal spacing that is twenty six thousand samples per tracker per move.
        val giant = hitboxSampleOffsets(4.8, 28.8)
        (giant.size <= 125) shouldBe true
        giant.isNotEmpty() shouldBe true
    }

    test("rejects negative dimensions") {
        shouldThrow<IllegalArgumentException> { hitboxSampleOffsets(-0.1, 1.8) }
        shouldThrow<IllegalArgumentException> { hitboxSampleOffsets(0.3, -1.0) }
    }
})
