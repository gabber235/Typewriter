package com.typewritermc.imprint.gradle

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val ExtensionManifestEncoderTest by testSuite {
    test("manifest bytes are independent of discovery order") {
        val first =
            ExtensionManifestEncoder.encode(
                "typewritermc:fixture",
                "1.0.0",
                listOf("REALM|realm|1.0.0", "ENGINE|paper|1.0.0"),
                listOf("typewritermc:minecraft|1.0.0"),
                listOf(
                    ActivatorIndexEntry("common", "first", "fixture.First"),
                    ActivatorIndexEntry("enginePaper", "second", "fixture.Second"),
                ),
            )
        val second =
            ExtensionManifestEncoder.encode(
                "typewritermc:fixture",
                "1.0.0",
                listOf("REALM|realm|1.0.0", "ENGINE|paper|1.0.0"),
                listOf("typewritermc:minecraft|1.0.0"),
                listOf(
                    ActivatorIndexEntry("common", "first", "fixture.First"),
                    ActivatorIndexEntry("enginePaper", "second", "fixture.Second"),
                ).reversed(),
            )

        first shouldBe second
    }
}
