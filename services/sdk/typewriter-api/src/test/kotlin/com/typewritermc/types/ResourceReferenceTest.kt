package com.typewritermc.types

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.serialization.json.Json

private interface TestResource : Referenceable

val ResourceReferenceTest by testSuite {
    test("references preserve opaque resource ids") {
        val reference = Ref<TestResource>(ResourceId("page:chapter/intro"))

        val encoded = Json.encodeToString(RefSerializer, reference)

        Json.decodeFromString(RefSerializer, encoded) shouldBe reference
    }

    test("resource ids reject blank values") {
        shouldThrow<IllegalArgumentException> { ResourceId(" ") }
    }
}
