package com.typewritermc.elements

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.serialization.json.Json

val ElementInstanceIdTest by testSuite {
    test("instance identities preserve new and existing opaque keys") {
        listOf(
            "kd9pn4fa2s7m8q3v6x0z",
            "60000000000000000000000000000001",
            "950f5b9a-4a8d-4683-a527-8879d550d790",
        ).forEach { key ->
            val id = ElementInstanceId(key)
            val encoded = Json.encodeToString(ElementInstanceIdSerializer, id)
            encoded shouldBe "\"$key\""
            Json.decodeFromString(ElementInstanceIdSerializer, encoded) shouldBe id
        }
    }
}
