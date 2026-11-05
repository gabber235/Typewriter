package com.typewritermc.realm.edit

import com.typewritermc.authoring.SubmissionKey
import com.typewritermc.realm.testing.realmDatabase
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.RelationProjectionDelta

val SurrealSubmissionRetentionTest by testSuite {
    test("a Realm keeps the submissions of its newest commits up to the bound, the newest always among them") {
        realmDatabase("submission_retention").use { database ->
            val storage = SurrealAuthoringStorage(database)
            val nothing =
                AuthoringMutationPlan(emptyMap(), emptySet(), RelationProjectionDelta(removals = emptyList(), created = emptyList()))
            val keys = (0..COMMIT_SUBMISSIONS_KEPT).map { SubmissionKey("save-$it") }
            keys.forEach { storage.persistAtomic(nothing, it, request = "digest-${it.value}") }

            keys.count { storage.submittedRequest(it) != null } shouldBe COMMIT_SUBMISSIONS_KEPT
            storage.submittedRequest(keys.last()) shouldBe "digest-${keys.last().value}"
        }
    }
}
