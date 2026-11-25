package com.typewritermc.realm.authoring

import com.typewritermc.authoring.of
import com.typewritermc.realm.checking.nameFinding
import com.typewritermc.realm.checking.rename
import com.typewritermc.realm.checking.renumber
import com.typewritermc.realm.checking.rerunCatalog
import com.typewritermc.realm.publication.PUBLICATION_PAGE_ID
import com.typewritermc.realm.publication.PublicationFixture
import com.typewritermc.realm.routes.authoringRoutes
import com.typewritermc.realm.routes.state
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.settle
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.ValueLocation
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

    test("every commit, check pass and state reply records its graph work under its own operation on one counter") {
        RealmFixture.of(rerunCatalog(), mapOf(first to record(name = "bad"))).use { realm ->
            val generation = realm.views.read { it.catalog.generation }
            // Judging this set reads what a name means, which no check reads, so every reply judges it on the graph.
            realm.findings = { listOf(nameFinding(generation, ValueLocation.of(first))) }
            realm.settle()
            realm.authoringRoutes(realm.findings).use { wire -> wire.state(generation) }
            realm.commitChecked(rename(first, "valid"))

            val recorded = realm.telemetry.counts("typewriter.realm.graph_work", "realm.operation")
            recorded.keys shouldBe setOf("commit.bind", "commit.reply", "checks.pass", "state.reply")
            recorded.filterValues { it <= 0 }.keys.shouldBeEmpty()
        }
    }

    test("a release records the graph work of evaluating its capture and judging its findings") {
        val publication = PublicationFixture()
        try {
            val generation = publication.views.read { it.catalog.generation }
            publication.findings = listOf(nameFinding(generation, ValueLocation.of(PUBLICATION_PAGE_ID)))
            publication.release()

            val recorded = publication.telemetry.counts("typewriter.realm.graph_work", "realm.operation")
            recorded.keys shouldBe setOf("capture.evaluation", "release.judgement")
            recorded.filterValues { it <= 0 }.keys.shouldBeEmpty()
        } finally {
            publication.close()
        }
    }
}
