package com.typewritermc.engine.panel

import com.typewritermc.engine.panel.testing.PanelEngineHarness
import com.typewritermc.engine.panel.testing.PanelEngineHarness.Companion.realm
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import com.typewritermc.services.libs.communicator.kv.LeaseState
import com.typewritermc.services.libs.communicator.testing.KeyValueStore
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import skirout.organization.v1.presence.PresenceLocation
import kotlin.time.Duration.Companion.milliseconds

/**
 * The panel engine of Realm `realm` on virtual time, over a sessions bucket and a broker in memory: panel tabs publish
 * presence events as the panel does, and every deadline and expiry is set up exactly. Keys live 2 s, a vacancy lasts 1 s.
 */
val PresenceSessionsTest by testSuite {
    test("PANEL-S1 a tab in the engine's Realm is a session of its user held by the panel engine while its heartbeat lasts") {
        val panel = PanelEngineHarness(KeyValueStore.Memory(testScope)).apply { start() }
        val timings = panel.sessions.timings
        panel.tab("tab")

        panel.sessions.store.advance(timings.lease.ttl * 3)

        panel.sessions
            .entry(panel.user, SessionId("tab"))
            .shouldNotBeNull()
            .holder shouldBe EngineId(PanelEngineHarness.ENGINE)
    }

    test("PANEL-S2 a tab that leaves is vacant at once and its session ends after the vacancy") {
        val panel = PanelEngineHarness(KeyValueStore.Memory(testScope)).apply { start() }
        val timings = panel.sessions.timings
        val tab = panel.tab("tab")
        panel.sessions.store.advance(timings.lease.refresh)

        tab.cancel()
        panel.left("tab")

        panel.sessions
            .entry(panel.user, SessionId("tab"))
            .shouldNotBeNull()
            .state shouldBe LeaseState.Vacant
        panel.sessions.store.advance(timings.lease.vacancy)
        panel.sessions.entry(panel.user, SessionId("tab")).shouldBeNull()
    }

    test("PANEL-S3 a tab in another Realm or outside any Realm has no session on this engine") {
        val panel = PanelEngineHarness(KeyValueStore.Memory(testScope)).apply { start() }
        panel.tab("here")
        panel.tab("elsewhere", realm("other"))
        panel.tab("members", PresenceLocation.createMembers())

        panel.sessions.store.advance(panel.sessions.timings.lease.ttl)

        panel.sessions.entry(panel.user, SessionId("here")).shouldNotBeNull()
        panel.sessions.entry(panel.user, SessionId("elsewhere")).shouldBeNull()
        panel.sessions.entry(panel.user, SessionId("members")).shouldBeNull()
    }

    test(
        "PANEL-S4 a tab whose heartbeats stop while the engine changes messaging session leaves at its deadline and its session goes vacant",
    ) {
        val panel = PanelEngineHarness(KeyValueStore.Memory(testScope)).apply { start() }
        val ttl = panel.sessions.timings.lease.ttl
        val tab = Session(panel.user, SessionId("tab"))
        panel.heartbeat(tab.id.value)
        panel.sessions
            .entry(tab.protagonist, tab.id)
            .shouldNotBeNull()
            .holder shouldBe EngineId(PanelEngineHarness.ENGINE)

        panel.connect()
        panel.sessions.store.advance(ttl - 1.milliseconds)
        panel.presence.sessions.value.keys shouldBe setOf(tab)

        panel.sessions.store.advance(1.milliseconds)
        panel.presence.sessions.value.keys shouldBe emptySet()
        panel.sessions
            .entry(tab.protagonist, tab.id)
            .shouldNotBeNull()
            .state shouldBe LeaseState.Vacant
    }
}
