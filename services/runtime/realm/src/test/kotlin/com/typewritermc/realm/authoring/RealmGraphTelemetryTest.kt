package com.typewritermc.realm.authoring

import com.typewritermc.realm.checking.rename
import com.typewritermc.realm.checking.renumber
import com.typewritermc.realm.checking.rerunCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.settle
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
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
                harness.counts("typewriter.realm.graph.computed", "query.kind")["CheckRun"] shouldBe 4L

                realm.commitChecked(rename(first, "valid"))
                realm.commitChecked(renumber(first))
                harness.counts("typewriter.realm.graph.computed", "query.kind")["CheckRun"] shouldBe 5L
            }
        }
    }
}
