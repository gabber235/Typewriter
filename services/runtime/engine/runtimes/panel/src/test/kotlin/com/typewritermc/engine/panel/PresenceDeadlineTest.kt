package com.typewritermc.engine.panel

import com.typewritermc.engine.panel.testing.PanelEngineHarness.Companion.TIMINGS
import com.typewritermc.engine.panel.testing.VirtualPanel
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import com.typewritermc.services.libs.communicator.kv.LeaseState
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import kotlin.time.Duration.Companion.milliseconds

/** When a panel tab leaves the panel engine's sessions, on virtual time over a sessions bucket in memory. */
val PresenceDeadlineTest by testSuite {
    test(
        "PANEL-S4 a tab whose heartbeats stop while the engine changes messaging session leaves at its deadline and its session goes vacant",
    ) {
        val panel = VirtualPanel(testScope).apply { start() }
        val tab = Session(panel.user, SessionId("tab"))
        panel.heartbeat(tab.id.value)
        panel.sessions
            .entry(tab.protagonist, tab.id)
            .shouldNotBeNull()
            .holder shouldBe EngineId(VirtualPanel.ENGINE)

        panel.connect()
        panel.sessions.keyValue.advance(TIMINGS.lease.ttl - 1.milliseconds)
        panel.presence.sessions.value.keys shouldBe setOf(tab)

        panel.sessions.keyValue.advance(1.milliseconds)
        panel.presence.sessions.value.keys shouldBe emptySet()
        panel.sessions
            .entry(tab.protagonist, tab.id)
            .shouldNotBeNull()
            .state shouldBe LeaseState.Vacant
    }
}
