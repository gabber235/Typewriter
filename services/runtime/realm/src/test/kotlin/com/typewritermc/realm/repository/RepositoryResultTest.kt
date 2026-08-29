package com.typewritermc.realm.repository

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val RepositoryResultTest by testSuite {
    test("repository failures accept only exact known wire values") {
        RepositoryFailure.fromWireValue("page-chapter-invalid-error") shouldBe RepositoryFailure.PAGE_CHAPTER_INVALID
        RepositoryFailure.fromWireValue("database rejected page-chapter-invalid-error") shouldBe null
        RepositoryFailure.fromWireValue("unknown-error") shouldBe null
        RepositoryFailure.fromThrownMessage("An error occurred: page-chapter-invalid-error") shouldBe
            RepositoryFailure.PAGE_CHAPTER_INVALID
        RepositoryFailure.fromThrownMessage("database rejected page-chapter-invalid-error") shouldBe null
    }
}
