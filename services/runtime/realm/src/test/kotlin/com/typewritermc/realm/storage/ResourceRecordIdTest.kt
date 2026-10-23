package com.typewritermc.realm.repository

import com.surrealdb.RecordId
import com.typewritermc.realm.repository.utils.surrealRecordId
import com.typewritermc.realm.repository.utils.toResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.ResourceId

val ResourceRecordIdTest by testSuite {
    test("round trips opaque resource identities through the canonical table") {
        val id = ResourceId(value = "same-value-for-any-kind")

        id.surrealRecordId().toResourceId() shouldBe id
    }

    test("rejects records outside the canonical resource table") {
        shouldThrow<IllegalArgumentException> {
            RecordId("page", "same-value-for-any-kind").toResourceId()
        }
    }
}
