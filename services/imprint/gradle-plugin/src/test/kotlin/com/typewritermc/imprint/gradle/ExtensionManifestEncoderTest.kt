package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.TypewriterActivatorReference
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.encodeToByteArray

@OptIn(ExperimentalSerializationApi::class)
val ExtensionManifestEncoderTest by testSuite {
    test("manifest bytes are independent of discovery order") {
        val first =
            canonicalExtensionManifest(
                id = "typewritermc:fixture",
                version = "1.0.0",
                targets = listOf("REALM|realm|1.0.0", "ENGINE|paper|1.0.0"),
                capabilities = listOf("typewritermc:minecraft|1.0.0"),
                activators =
                    listOf(
                        TypewriterActivatorReference("common", "first", "fixture.First"),
                        TypewriterActivatorReference("enginePaper", "second", "fixture.Second"),
                    ),
            )
        val second =
            canonicalExtensionManifest(
                id = "typewritermc:fixture",
                version = "1.0.0",
                targets = listOf("ENGINE|paper|1.0.0", "REALM|realm|1.0.0"),
                capabilities = listOf("typewritermc:minecraft|1.0.0"),
                activators =
                    listOf(
                        TypewriterActivatorReference("common", "first", "fixture.First"),
                        TypewriterActivatorReference("enginePaper", "second", "fixture.Second"),
                    ).reversed(),
            )

        Cbor.Default.encodeToByteArray(first) shouldBe Cbor.Default.encodeToByteArray(second)
    }
}
