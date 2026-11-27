package com.typewritermc.playtest.wire

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.harness.v1.wire.AttemptKind

val AttemptKindsTest by testSuite {
    test("a paced attempt's Paper grants ticks at its pace, a verdict or demo attempt's as fast as the pool steps") {
        listOf(AttemptKind.PacedWrapper(50), AttemptKind.VERDICT, AttemptKind.DEMO).map { it.paceMillis } shouldBe listOf(50, 0, 0)
    }
}
