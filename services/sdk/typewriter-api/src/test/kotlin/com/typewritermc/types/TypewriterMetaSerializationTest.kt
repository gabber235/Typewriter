@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package com.typewritermc.types

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.elements.Element
import com.typewritermc.elements.TypewriterElement
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.serialization.json.Json

val TypewriterMetaSerializationTest by testSuite {
    test("TypewriterType generates its serializer") {
        val source = MetaSerializableType("value")

        Json.decodeFromString(MetaSerializableType.serializer(), Json.encodeToString(MetaSerializableType.serializer(), source)) shouldBe
            source
        MetaSerializableType
            .serializer()
            .descriptor.annotations
            .filterIsInstance<TypewriterType>()
            .single()
            .id shouldBe "019d4813b98b74dabd0222e6182f8e42"
    }

    test("TypewriterElement generates its serializer") {
        val source = MetaSerializableElement("Element", GraphPlacement(0, 0, 1, 1))

        Json.decodeFromString(
            MetaSerializableElement.serializer(),
            Json.encodeToString(MetaSerializableElement.serializer(), source),
        ) shouldBe source
        MetaSerializableElement
            .serializer()
            .descriptor.annotations
            .filterIsInstance<TypewriterElement>()
            .single()
            .name shouldBe "Meta Serializable Element"
    }
}

@TypewriterType(id = "019d4813b98b74dabd0222e6182f8e42")
private data class MetaSerializableType(
    val value: String,
)

@TypewriterElement(
    id = "019d4813b98b74dabd0222e6182f8e43",
    name = "Meta Serializable Element",
    description = "Verifies generated serialization",
    icon = "material-symbols:code",
    color = "#7C4DFF",
)
private data class MetaSerializableElement(
    override val name: String,
    override val placement: GraphPlacement,
) : Element
