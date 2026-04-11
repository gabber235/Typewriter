package com.typewritermc.quest.entries.audience.objectives

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

class TargetSpecTest : FunSpec({

    // -------------------------------------------------------------------------
    // parse — golden cases
    // -------------------------------------------------------------------------

    context("parse golden cases") {
        test("blank string returns EmptyTarget") {
            TargetSpec.parse("") shouldBe EmptyTarget
            TargetSpec.parse("   ") shouldBe EmptyTarget
        }

        test("single exact value") {
            TargetSpec.parse("5") shouldBe ExactTarget(5)
        }

        test("inclusive range") {
            TargetSpec.parse("5-10") shouldBe RangeTarget(5, 10)
        }

        test("lower bound (open upper end)") {
            TargetSpec.parse("32..") shouldBe LowerBoundTarget(32)
        }

        test("upper bound (open lower end)") {
            TargetSpec.parse("..10") shouldBe UpperBoundTarget(10)
        }

        test("wildcard * returns UniversalTarget") {
            TargetSpec.parse("*") shouldBe UniversalTarget
        }

        test("bare .. returns UniversalTarget") {
            TargetSpec.parse("..") shouldBe UniversalTarget
        }

        test("composite of exact values") {
            val result = TargetSpec.parse("1,3,5").shouldBeInstanceOf<CompositeTarget>()
            result.specs shouldBe listOf(ExactTarget(1), ExactTarget(3), ExactTarget(5))
        }

        test("composite of range and exact") {
            val result = TargetSpec.parse("28-61,63").shouldBeInstanceOf<CompositeTarget>()
            result.specs shouldBe listOf(RangeTarget(28, 61), ExactTarget(63))
        }

        test("composite with open-ended bounds") {
            val result = TargetSpec.parse("28-61,63,70..").shouldBeInstanceOf<CompositeTarget>()
            result.specs shouldBe listOf(RangeTarget(28, 61), ExactTarget(63), LowerBoundTarget(70))
        }
    }

    // -------------------------------------------------------------------------
    // parse — simplification
    // -------------------------------------------------------------------------

    context("parse simplification") {
        test("subsumed exact inside range is dropped") {
            // 5 is inside 1-10, so ExactTarget(5) is removed
            TargetSpec.parse("1-10,5") shouldBe RangeTarget(1, 10)
        }

        test("subsumed range inside wider range is dropped") {
            TargetSpec.parse("1-10,3-7") shouldBe RangeTarget(1, 10)
        }

        test("lower bound subsumes exact and range above it") {
            TargetSpec.parse("10..,15") shouldBe LowerBoundTarget(10)
            TargetSpec.parse("10..,12-20") shouldBe LowerBoundTarget(10)
        }

        test("upper bound subsumes exact and range below it") {
            TargetSpec.parse("..10,5") shouldBe UpperBoundTarget(10)
            TargetSpec.parse("..10,3-8") shouldBe UpperBoundTarget(10)
        }

        test("overlapping lower and upper bounds collapse to UniversalTarget") {
            // ..5 covers ≤5, 3.. covers ≥3 — together they cover everything
            TargetSpec.parse("..5,3..") shouldBe UniversalTarget
        }

        test("adjacent lower and upper bounds collapse to UniversalTarget") {
            // ..4 and 5.. are adjacent — together cover everything
            TargetSpec.parse("..4,5..") shouldBe UniversalTarget
        }

        test("duplicate exact values deduplicate cleanly") {
            TargetSpec.parse("5,5") shouldBe ExactTarget(5)
        }

        test("triplicate exact values deduplicate cleanly") {
            TargetSpec.parse("5,5,6") shouldBe CompositeTarget(listOf(ExactTarget(5), ExactTarget(6)))
        }
    }

    // -------------------------------------------------------------------------
    // parse — invalid / edge inputs
    // -------------------------------------------------------------------------

    context("parse invalid and edge inputs") {
        test("all-invalid tokens returns EmptyTarget") {
            TargetSpec.parse("abc,def") shouldBe EmptyTarget
        }

        test("mixed valid and invalid tokens — invalid silently dropped") {
            TargetSpec.parse("5,abc,10") shouldBe CompositeTarget(listOf(ExactTarget(5), ExactTarget(10)))
        }

        test("inverted range (max < min) is invalid") {
            TargetSpec.parse("10-5") shouldBe EmptyTarget
        }

        test("single-number range (min == max) is valid") {
            TargetSpec.parse("7-7") shouldBe RangeTarget(7, 7)
        }

        test("malformed range with extra dash is invalid") {
            // "1-2-3" splits to from=1, to=null (limit=2 gives "2-3" which is non-int)
            TargetSpec.parse("1-2-3") shouldBe EmptyTarget
        }

        test("whitespace around tokens is trimmed") {
            TargetSpec.parse(" 5 , 10 ") shouldBe CompositeTarget(listOf(ExactTarget(5), ExactTarget(10)))
        }

        test("whitespace-only tokens are ignored") {
            TargetSpec.parse("5, ,10") shouldBe CompositeTarget(listOf(ExactTarget(5), ExactTarget(10)))
        }
    }

    // -------------------------------------------------------------------------
    // contains
    // -------------------------------------------------------------------------

    context("contains") {
        test("ExactTarget matches only its value") {
            ExactTarget(5).contains(5) shouldBe true
            ExactTarget(5).contains(4) shouldBe false
            ExactTarget(5).contains(6) shouldBe false
        }

        test("RangeTarget matches inclusive bounds") {
            RangeTarget(3, 7).contains(3) shouldBe true
            RangeTarget(3, 7).contains(7) shouldBe true
            RangeTarget(3, 7).contains(5) shouldBe true
            RangeTarget(3, 7).contains(2) shouldBe false
            RangeTarget(3, 7).contains(8) shouldBe false
        }

        test("LowerBoundTarget matches its min and above") {
            LowerBoundTarget(10).contains(10) shouldBe true
            LowerBoundTarget(10).contains(100) shouldBe true
            LowerBoundTarget(10).contains(9) shouldBe false
        }

        test("UpperBoundTarget matches its max and below") {
            UpperBoundTarget(10).contains(10) shouldBe true
            UpperBoundTarget(10).contains(0) shouldBe true
            UpperBoundTarget(10).contains(11) shouldBe false
        }

        test("UniversalTarget matches everything") {
            UniversalTarget.contains(Int.MIN_VALUE) shouldBe true
            UniversalTarget.contains(0) shouldBe true
            UniversalTarget.contains(Int.MAX_VALUE) shouldBe true
        }

        test("EmptyTarget matches nothing") {
            EmptyTarget.contains(0) shouldBe false
            EmptyTarget.contains(Int.MIN_VALUE) shouldBe false
            EmptyTarget.contains(Int.MAX_VALUE) shouldBe false
        }

        test("CompositeTarget matches union of specs") {
            val spec = CompositeTarget(listOf(ExactTarget(1), RangeTarget(5, 8)))
            spec.contains(1) shouldBe true
            spec.contains(5) shouldBe true
            spec.contains(8) shouldBe true
            spec.contains(2) shouldBe false
            spec.contains(9) shouldBe false
        }
    }

    // -------------------------------------------------------------------------
    // subsumes
    // -------------------------------------------------------------------------

    context("subsumes") {
        test("UniversalTarget subsumes everything") {
            UniversalTarget.subsumes(ExactTarget(5)) shouldBe true
            UniversalTarget.subsumes(RangeTarget(1, 100)) shouldBe true
            UniversalTarget.subsumes(LowerBoundTarget(0)) shouldBe true
            UniversalTarget.subsumes(EmptyTarget) shouldBe true
            UniversalTarget.subsumes(UniversalTarget) shouldBe true
        }

        test("EmptyTarget only subsumes itself") {
            EmptyTarget.subsumes(EmptyTarget) shouldBe true
            EmptyTarget.subsumes(ExactTarget(5)) shouldBe false
        }

        test("ExactTarget only subsumes the same exact value") {
            ExactTarget(5).subsumes(ExactTarget(5)) shouldBe true
            ExactTarget(5).subsumes(ExactTarget(6)) shouldBe false
            ExactTarget(5).subsumes(RangeTarget(5, 5)) shouldBe false
        }

        test("RangeTarget subsumes contained exacts and sub-ranges") {
            RangeTarget(1, 10).subsumes(ExactTarget(5)) shouldBe true
            RangeTarget(1, 10).subsumes(ExactTarget(11)) shouldBe false
            RangeTarget(1, 10).subsumes(RangeTarget(3, 7)) shouldBe true
            RangeTarget(1, 10).subsumes(RangeTarget(3, 11)) shouldBe false
        }

        test("LowerBoundTarget subsumes contained exacts, ranges, and wider lower bounds") {
            LowerBoundTarget(5).subsumes(ExactTarget(5)) shouldBe true
            LowerBoundTarget(5).subsumes(ExactTarget(4)) shouldBe false
            LowerBoundTarget(5).subsumes(RangeTarget(5, 100)) shouldBe true
            LowerBoundTarget(5).subsumes(RangeTarget(4, 100)) shouldBe false
            LowerBoundTarget(5).subsumes(LowerBoundTarget(10)) shouldBe true
            LowerBoundTarget(5).subsumes(LowerBoundTarget(4)) shouldBe false
        }

        test("UpperBoundTarget subsumes contained exacts, ranges, and wider upper bounds") {
            UpperBoundTarget(10).subsumes(ExactTarget(10)) shouldBe true
            UpperBoundTarget(10).subsumes(ExactTarget(11)) shouldBe false
            UpperBoundTarget(10).subsumes(RangeTarget(0, 10)) shouldBe true
            UpperBoundTarget(10).subsumes(RangeTarget(0, 11)) shouldBe false
            UpperBoundTarget(10).subsumes(UpperBoundTarget(5)) shouldBe true
            UpperBoundTarget(10).subsumes(UpperBoundTarget(11)) shouldBe false
        }
    }
})
