package com.typewritermc.engine.panel

import com.typewritermc.engine.panel.testing.PanelEngineHarness
import com.typewritermc.engine.panel.testing.PanelEngineHarness.Companion.TIMINGS
import com.typewritermc.engine.panel.testing.PanelEngineHarness.Companion.realm
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.SessionId
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.delay
import skirout.organization.v1.presence.PresenceLocation
import java.util.UUID

/**
 * The panel engine of Realm `realm` on a real nats-server: panel tabs publish the presence heartbeat as the panel does,
 * and the broker decides every key's expiry. Timings are short: heartbeats every 300 ms, keys live 2 s, a vacancy of 1 s.
 */
val PresenceSessionsTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    val panel = testFixture { PanelEngineHarness.start() }

    test("PANEL-S1 a tab in the engine's Realm is a session of its user held by the panel engine while its heartbeat lasts") {
        val id = UUID.randomUUID().toString()
        panel().tab(id, realm("realm"))

        panel().sessions.eventually { panel().sessions.entry(panel().user, SessionId(id)) != null }
        delay(TIMINGS.lease.ttl * 2)

        panel()
            .sessions
            .entry(panel().user, SessionId(id))
            .shouldNotBeNull()
            .holder shouldBe EngineId("panel.realm")
    }

    test("PANEL-S2 a tab that leaves, or whose heartbeat stops, ends its session after the vacancy") {
        val leaving = UUID.randomUUID().toString()
        val closed = UUID.randomUUID().toString()
        val leavingTab = panel().tab(leaving, realm("realm"))
        val closedTab = panel().tab(closed, realm("realm"))
        panel().sessions.eventually {
            panel().sessions.entry(panel().user, SessionId(leaving)) != null &&
                panel().sessions.entry(panel().user, SessionId(closed)) != null
        }

        leavingTab.cancel()
        panel().left(leaving)
        closedTab.cancel()

        panel().sessions.eventually(
            within = TIMINGS.lease.ttl + TIMINGS.lease.vacancy,
        ) { panel().sessions.entry(panel().user, SessionId(leaving)) == null }
        panel().sessions.eventually(within = TIMINGS.lease.ttl * 2 + TIMINGS.lease.vacancy) {
            panel().sessions.entry(panel().user, SessionId(closed)) ==
                null
        }
    }

    test("PANEL-S3 a tab in another Realm or outside any Realm has no session on this engine") {
        val elsewhere = UUID.randomUUID().toString()
        val members = UUID.randomUUID().toString()
        panel().tab(elsewhere, realm("other"))
        panel().tab(members, PresenceLocation.createMembers())

        delay(TIMINGS.lease.ttl)

        panel().sessions.entry(panel().user, SessionId(elsewhere)).shouldBeNull()
        panel().sessions.entry(panel().user, SessionId(members)).shouldBeNull()
    }
}
