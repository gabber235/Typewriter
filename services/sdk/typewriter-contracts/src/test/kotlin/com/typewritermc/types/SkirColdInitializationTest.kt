package com.typewritermc.types

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val SkirColdInitializationTest by testSuite {
    test("every recursive serializer entry initializes in a cold process") {
        runColdProbes(
            listOf(
                "FieldValue",
                "RecordPayload",
                "NamedValue",
                "ListItem",
                "ListPayload",
                "MapRow",
                "MapPayload",
                "DataValue",
            ),
        ).forEach { result -> result shouldBe 0 }
    }

    test("parallel first serializer access completes without deadlock") {
        runColdProbes(List(4) { "concurrent" }).forEach { result -> result shouldBe 0 }
    }
}
