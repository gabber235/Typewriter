package com.typewritermc.services.libs.communicator.routing

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe

class SubjectExtensionsTest : FunSpec({

    context("join extension") {
        test("joins non-empty paths with dot") {
            "prefix".join("suffix") shouldBe "prefix.suffix"
        }

        test("handles empty prefix") {
            "".join("suffix") shouldBe "suffix"
        }

        test("handles empty suffix") {
            "prefix".join("") shouldBe "prefix"
        }

        test("handles both empty") {
            "".join("") shouldBe ""
        }

        test("joins multiple segments") {
            "cloud.from".join("realm.{realmId}") shouldBe "cloud.from.realm.{realmId}"
        }
    }
})
