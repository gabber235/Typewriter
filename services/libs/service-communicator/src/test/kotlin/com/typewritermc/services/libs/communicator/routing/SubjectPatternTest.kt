package com.typewritermc.services.libs.communicator.routing

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe

class SubjectPatternTest : FunSpec({

    context("subscription subject generation") {
        test("replaces single param with wildcard") {
            val pattern = SubjectPattern("realm.{realmId}.player")
            pattern.subscriptionSubject shouldBe "realm.*.player"
        }

        test("replaces multiple params with wildcards") {
            val pattern = SubjectPattern("realm.{realmId}.player.{playerId}")
            pattern.subscriptionSubject shouldBe "realm.*.player.*"
        }

        test("handles pattern with no params") {
            val pattern = SubjectPattern("static.subject.here")
            pattern.subscriptionSubject shouldBe "static.subject.here"
        }
    }

    context("pattern matching") {
        test("matches valid subjects with single param") {
            val pattern = SubjectPattern("realm.{realmId}.player")
            pattern.matches("realm.abc123.player") shouldBe true
            pattern.matches("realm.xyz.player") shouldBe true
        }

        test("matches valid subjects with multiple params") {
            val pattern = SubjectPattern("realm.{realmId}.world.{worldId}")
            pattern.matches("realm.r1.world.w2") shouldBe true
        }

        test("rejects subjects with wrong static segments") {
            val pattern = SubjectPattern("realm.{realmId}.player")
            pattern.matches("realm.abc123.world") shouldBe false
            pattern.matches("other.abc123.player") shouldBe false
        }

        test("rejects subjects with wrong segment count") {
            val pattern = SubjectPattern("realm.{realmId}.player")
            pattern.matches("realm.abc.123.player") shouldBe false
            pattern.matches("realm.abc") shouldBe false
        }
    }

    context("param extraction") {
        test("extracts single param") {
            val pattern = SubjectPattern("realm.{realmId}.player")
            val params = pattern.extractParams("realm.abc123.player")

            params["realmId"] shouldBe "abc123"
        }

        test("extracts multiple params") {
            val pattern = SubjectPattern("realm.{realmId}.world.{worldId}")
            val params = pattern.extractParams("realm.r1.world.w2")

            params["realmId"] shouldBe "r1"
            params["worldId"] shouldBe "w2"
        }

        test("extracts params with special characters") {
            val pattern = SubjectPattern("service.{serviceId}.action")
            val params = pattern.extractParams("service.svc-123_abc.action")

            params["serviceId"] shouldBe "svc-123_abc"
        }

        test("extracts consecutive params") {
            val pattern = SubjectPattern("{a}.{b}.{c}")
            val params = pattern.extractParams("x.y.z")

            params["a"] shouldBe "x"
            params["b"] shouldBe "y"
            params["c"] shouldBe "z"
        }

        test("extracts params with hyphens and underscores") {
            val pattern = SubjectPattern("realm.{realmId}.action")
            val params = pattern.extractParams("realm.my-realm_123.action")

            params["realmId"] shouldBe "my-realm_123"
        }

        test("handles long subject chains") {
            val pattern = SubjectPattern("a.b.c.d.e.{id}.f.g")
            val params = pattern.extractParams("a.b.c.d.e.myId.f.g")

            params["id"] shouldBe "myId"
        }

        test("returns empty map for non-matching subject") {
            val pattern = SubjectPattern("realm.{realmId}")
            val params = pattern.extractParams("other.subject")

            params shouldBe emptyMap()
        }
    }

    context("edge cases") {
        test("pattern with only params") {
            val pattern = SubjectPattern("{a}.{b}.{c}")

            pattern.subscriptionSubject shouldBe "*.*.*"
            pattern.matches("x.y.z") shouldBe true
        }

        test("rejects subject with extra trailing segment") {
            val pattern = SubjectPattern("realm.{id}.player")

            pattern.matches("realm.123.player.extra") shouldBe false
        }

        test("rejects subject with missing segment") {
            val pattern = SubjectPattern("realm.{id}.player")

            pattern.matches("realm.123") shouldBe false
        }

        test("single segment pattern") {
            val pattern = SubjectPattern("{id}")

            pattern.subscriptionSubject shouldBe "*"
            pattern.matches("abc") shouldBe true
            pattern.extractParams("abc")["id"] shouldBe "abc"
        }

        test("single static segment pattern") {
            val pattern = SubjectPattern("static")

            pattern.subscriptionSubject shouldBe "static"
            pattern.matches("static") shouldBe true
            pattern.matches("other") shouldBe false
        }

        test("empty subject does not match non-empty pattern") {
            val pattern = SubjectPattern("realm.{id}")

            pattern.matches("") shouldBe false
        }
    }
})
