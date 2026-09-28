package com.typewritermc.realm.repository

import com.surrealdb.RecordId
import com.typewritermc.realm.repository.utils.toUnifiedResourceId
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val UnifiedResourceIdTest by testSuite {
    test("round trips opaque resource identities through the canonical table") {
        val id = ResourceId("same-value-for-any-kind")

        id.unifiedSurrealId().toUnifiedResourceId() shouldBe id
    }

    test("rejects records outside the canonical resource table") {
        shouldThrow<IllegalArgumentException> {
            RecordId("page", "same-value-for-any-kind").toUnifiedResourceId()
        }
    }
}
