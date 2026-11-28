package com.typewritermc.playtest.launch

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.shouldBe

val PartLimitTest by testSuite {
    test("a game JVM's heap is its kind's share of the part's memory limit in whole MiB, never rounded up past it") {
        // 3904 MiB at 66%, 2393 MiB at 46%, 1775 MiB at 42% and 812 MiB at 40%.
        mapOf(
            PartLimit.SHARED_PAPER to "-Xmx2576m",
            PartLimit.OWN_PAPER to "-Xmx1100m",
            PartLimit.CLIENT to "-Xmx745m",
            PartLimit.POOL to "-Xmx324m",
        ).forEach { (kind, flag) -> withClue(kind) { kind.heapFlag() shouldBe flag } }
    }
}
