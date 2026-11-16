package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.CoveredClass
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val TouchedTest by testSuite {
    test("a requirement that covered a line the change added is touched") {
        val touched = Touched.read("com/typewritermc/playtest/plugin/Probes.java 12 40\n")

        touched.touches(
            listOf(CoveredClass("com/typewritermc/playtest/plugin/Probes", "com/typewritermc/playtest/plugin/Probes.java", listOf(10, 40, 41))),
        ) shouldBe true
    }

    test("a requirement that covered only other lines of a changed file, or a file of that name in another package, is not touched") {
        val touched = Touched.read("com/typewritermc/playtest/plugin/Probes.java 12 40\ncom/typewritermc/playtest/plugin/Wipe.java 3\n")

        touched.touches(
            listOf(
                CoveredClass("com/typewritermc/playtest/plugin/Probes", "com/typewritermc/playtest/plugin/Probes.java", listOf(10, 11, 41)),
                CoveredClass("com/typewritermc/playtest/wire/Probes", "com/typewritermc/playtest/wire/Probes.java", listOf(12, 40)),
            ),
        ) shouldBe false
    }

    test("a run without a change touches no requirement") {
        Touched.read("").touches(
            listOf(CoveredClass("com/typewritermc/playtest/plugin/Probes", "com/typewritermc/playtest/plugin/Probes.java", listOf(12))),
        ) shouldBe false
    }
}
