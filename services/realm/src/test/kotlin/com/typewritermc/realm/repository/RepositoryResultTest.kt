package com.typewritermc.realm.repository

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val RepositoryResultTest by testSuite {
    test("known database slugs become domain failures") {
        repositoryMutation<Unit> { error("database rejected tag-width-invalid-error") } shouldBe
            RepositoryResult.DomainFailure("tag-width-invalid-error")
    }
}
