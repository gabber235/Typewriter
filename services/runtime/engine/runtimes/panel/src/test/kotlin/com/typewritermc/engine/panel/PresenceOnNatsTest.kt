package com.typewritermc.engine.panel

import com.typewritermc.engine.panel.testing.PanelEngineHarness
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.SessionId
import com.typewritermc.services.libs.communicator.kv.LeaseTimings
import com.typewritermc.services.libs.communicator.testing.KeyValueStore
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import kotlinx.coroutines.cancelAndJoin
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/**
 * The panel engine through a real nats-server and the client production uses, end to end. Keys live minutes, so
 * whatever must still be there is; what must end is waited for with a bound far above the vacancy. Every deadline and
 * expiry rule is proven on virtual time in PresenceSessionsTest.
 */
val PresenceOnNatsTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    val timings = SessionTimings(LeaseTimings(refresh = 1.seconds, ttl = 5.minutes, vacancy = 1.seconds, retry = 100.milliseconds))
    val panel = testFixture { PanelEngineHarness(KeyValueStore.Broker.start(), timings).apply { start() } }

    test("PANEL-NATS a tab's heartbeats through the broker make it a session of the panel engine, and its leave ends it") {
        val tab = panel().tab("tab")
        panel().sessions.store.eventually {
            panel().sessions.entry(panel().user, SessionId("tab"))?.holder == EngineId(PanelEngineHarness.ENGINE)
        }

        tab.cancelAndJoin()
        panel().left("tab")

        panel().sessions.store.eventually(within = timings.lease.vacancy + 30.seconds) {
            panel().sessions.entry(panel().user, SessionId("tab")) == null
        }
    }
}
