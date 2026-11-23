package com.typewritermc.engine.delivery

import com.typewritermc.engine.events.testing.reason
import com.typewritermc.events.EventResult
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/** The rules a sender follows without any engine: merging results and spacing the asks it repeats. */
val DeliveryRulesTest by testSuite {
    test("the strongest result wins: denied, then failed, then done, then not handled") {
        val denied = EventResult.Denied(reason("guarded"))
        val failed = EventResult.Failed(reason("broken"))

        merged(listOf(EventResult.NotHandled, EventResult.Done, failed, denied)) shouldBe denied
        merged(listOf(EventResult.Done, failed, EventResult.NotHandled)) shouldBe failed
        merged(listOf(EventResult.NotHandled, EventResult.Done)) shouldBe EventResult.Done
        merged(listOf(EventResult.NotHandled)) shouldBe EventResult.NotHandled
    }

    test("of equally strong results the first wins, and no result at all is not handled") {
        merged(listOf(EventResult.Failed(reason("first")), EventResult.Failed(reason("second")))) shouldBe
            EventResult.Failed(reason("first"))
        merged(emptyList()) shouldBe EventResult.NotHandled
    }

    test("the gap before asking again doubles with every lost ask, up to the last gap") {
        val timings = DeliveryTimings(firstGap = 50.milliseconds, lastGap = 1.seconds)

        (1..7).map(timings::gap) shouldBe
            listOf(50, 100, 200, 400, 800, 1000, 1000).map { it.milliseconds }
        timings.gap(Int.MAX_VALUE) shouldBe 1.seconds
    }
}
