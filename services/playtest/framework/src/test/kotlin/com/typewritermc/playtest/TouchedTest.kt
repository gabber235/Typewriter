package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.harness.v1.test_run.CoveredClass

val TouchedTest by testSuite {
    test("a requirement that covered a line the change added is touched") {
        val touched = Touched.read("com/typewritermc/playtest/plugin/Probes.java 12 40\n")

        touched.touches(
            listOf(
                CoveredClass(
                    name = "com/typewritermc/playtest/plugin/Probes",
                    source = "com/typewritermc/playtest/plugin/Probes.java",
                    lines = listOf(10, 40, 41),
                ),
            ),
        ) shouldBe true
    }

    test("a requirement that covered only other lines of a changed file, or a file of that name in another package, is not touched") {
        val touched = Touched.read("com/typewritermc/playtest/plugin/Probes.java 12 40\ncom/typewritermc/playtest/plugin/Wipe.java 3\n")

        touched.touches(
            listOf(
                CoveredClass(
                    name = "com/typewritermc/playtest/plugin/Probes",
                    source = "com/typewritermc/playtest/plugin/Probes.java",
                    lines = listOf(10, 11, 41),
                ),
                CoveredClass(
                    name = "com/typewritermc/playtest/wire/Probes",
                    source = "com/typewritermc/playtest/wire/Probes.java",
                    lines = listOf(12, 40),
                ),
            ),
        ) shouldBe false
    }

    test("a run without a change touches no requirement") {
        Touched.read("").touches(
            listOf(
                CoveredClass(
                    name = "com/typewritermc/playtest/plugin/Probes",
                    source = "com/typewritermc/playtest/plugin/Probes.java",
                    lines = listOf(12),
                ),
            ),
        ) shouldBe false
    }
}
