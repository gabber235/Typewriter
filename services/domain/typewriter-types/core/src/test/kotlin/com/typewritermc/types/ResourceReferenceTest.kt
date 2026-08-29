package com.typewritermc.types

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.serialization.json.Json

private interface TestResource : Referenceable

val ResourceReferenceTest by testSuite {
    test("references preserve resource tables and record key shapes") {
        val references =
            listOf(
                Ref<TestResource>(ResourceId("page", "simple")),
                Ref<TestResource>(
                    ResourceId(
                        "page",
                        RecordIdKey.Array(
                            listOf(
                                RecordIdValue.String("chapter"),
                                RecordIdValue.Number(7),
                            ),
                        ),
                    ),
                ),
                Ref<TestResource>(ResourceId("page", "~literal")),
            )

        references.forEach { reference ->
            val encoded = Json.encodeToString(RefSerializer, reference)
            Json.decodeFromString(RefSerializer, encoded) shouldBe reference
        }
    }

    test("references reject missing and invalid resource tables") {
        shouldThrow<IllegalArgumentException> { ResourceId.parse("missing-table") }
        shouldThrow<IllegalArgumentException> { ResourceId("Page", "opening") }
    }
}
