package com.typewritermc.utils

import com.typewritermc.engine.paper.command.formatDuration
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe

class DebugCommandTest : FunSpec({
    test("uptime omits unused leading units") {
        formatDuration(42_000) shouldBe "42s"
        formatDuration(3_661_000) shouldBe "1h 1m 1s"
        formatDuration(90_061_000) shouldBe "1d 1h 1m 1s"
    }
})
