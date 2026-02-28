package com.typewritermc.services.libs.communicator.routing

import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain

class SubjectParamsTest : FunSpec({

    context("get operator") {
        test("returns param value when present") {
            val params = SubjectParams(mapOf("realmId" to "abc123"))

            params["realmId"] shouldBe "abc123"
        }

        test("returns null for missing param") {
            val params = SubjectParams(mapOf("realmId" to "abc123"))

            params["worldId"].shouldBeNull()
        }

        test("returns param value with special characters") {
            val params = SubjectParams(mapOf("serviceId" to "svc-123_test"))

            params["serviceId"] shouldBe "svc-123_test"
        }
    }

    context("require function") {
        test("returns param value when present") {
            val params = SubjectParams(mapOf("realmId" to "abc123", "playerId" to "p1"))

            params.require("realmId") shouldBe "abc123"
            params.require("playerId") shouldBe "p1"
        }

        test("throws exception for missing param") {
            val params = SubjectParams(mapOf("realmId" to "abc123"))

            shouldThrow<IllegalStateException> {
                params.require("worldId")
            }
        }

        test("exception message includes the missing key name") {
            val params = SubjectParams(emptyMap())

            val exception = shouldThrow<IllegalStateException> {
                params.require("missingKey")
            }

            exception.message shouldContain "missingKey"
        }
    }

    context("empty params") {
        test("get returns null for any key") {
            val params = SubjectParams(emptyMap())

            params["anything"].shouldBeNull()
        }

        test("require throws for any key") {
            val params = SubjectParams(emptyMap())

            shouldThrow<IllegalStateException> {
                params.require("anyKey")
            }
        }
    }
})
