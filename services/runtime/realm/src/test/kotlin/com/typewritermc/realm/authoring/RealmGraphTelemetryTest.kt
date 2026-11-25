package com.typewritermc.realm.authoring

import com.typewritermc.realm.checking.rename
import com.typewritermc.realm.checking.renumber
import com.typewritermc.realm.checking.rerunCatalog
import com.typewritermc.realm.publication.AuthoringAcceptance
import com.typewritermc.realm.routes.authoringRoutes
import com.typewritermc.realm.routes.state
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.settle
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.longs.shouldBeGreaterThan
import io.kotest.matchers.shouldBe
import skirout.kernel.v1.resource_id.ResourceId

val RealmGraphTelemetryTest by testSuite {
    val first = ResourceId(value = "first")

    test("the live graph counts each computation by query kind in telemetry") {
        TelemetryTestHarness.create().use { harness ->
            val listener = RealmGraphTelemetry(harness.telemetry)
            RealmFixture.of(rerunCatalog(), mapOf(first to record(name = "bad")), listener = listener).use { realm ->
                realm.checks
                realm.settle()
                harness.counts("typewriter.graph.computed", "query.kind")["CheckRun"] shouldBe 4L

                realm.commitChecked(rename(first, "valid"))
                realm.commitChecked(renumber(first))
                harness.counts("typewriter.graph.computed", "query.kind")["CheckRun"] shouldBe 5L
            }
        }
    }

    test("every realm operation that reads the graph records its work under its own operation on one counter") {
        RealmFixture.of(rerunCatalog(), mapOf(first to record(name = "bad"))).use { realm ->
            realm.findings = { realm.checks.findings() }
            realm.settle()
            realm.commitChecked(rename(first, "valid"))
            realm.authoringRoutes(realm.findings).use { wire -> wire.state(realm.views.read { it.catalog.generation }) }
            realm.views.capture().use { captured ->
                val acceptance = AuthoringAcceptance(realm.views, realm.checks)
                acceptance.evaluate(captured)
                acceptance.judged(realm.findings(), captured.root)
            }

            val recorded =
                realm.telemetry
                    .counter("typewriter.realm.graph_work")
                    .entries
                    .groupBy({ it.key["realm.operation"] }, { it.value })
                    .mapValues { (_, steps) -> steps.sum() }
            recorded.keys shouldBe
                setOf(
                    "view.install",
                    "commit.bind",
                    "commit.reply",
                    "checks.pass",
                    "state.reply",
                    "capture.evaluation",
                    "release.judgement",
                )
            recorded.getValue("checks.pass") shouldBeGreaterThan 0
            recorded.getValue("capture.evaluation") shouldBeGreaterThan 0
        }
    }
}
