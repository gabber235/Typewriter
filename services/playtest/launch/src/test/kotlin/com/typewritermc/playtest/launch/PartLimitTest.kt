package com.typewritermc.playtest.launch

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.comparables.shouldBeLessThan
import io.kotest.matchers.shouldBe

val PartLimitTest by testSuite {
    test("a game JVM's heap is its kind's share of the part's own memory limit, leaving the rest for what the JVM keeps beside it") {
        val mib = 1024L * 1024
        for (kind in PartLimit.entries.filter { it.heapPercent > 0 }) {
            val heap =
                kind
                    .heapFlag()
                    .removePrefix("-Xmx")
                    .removeSuffix("m")
                    .toLong() * mib

            withClue(kind) {
                heap shouldBe kind.limitBytes * kind.heapPercent / 100 / mib * mib
                heap shouldBeLessThan kind.limitBytes
            }
        }
        PartLimit.SHARED_PAPER.heapFlag() shouldBe "-Xmx2576m"
    }
}
