package com.typewritermc.engine.panel

import com.typewritermc.engine.events.testing.after
import com.typewritermc.engine.events.testing.provided
import com.typewritermc.engine.runtime.testing.WiredEngine
import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.events.AfterHandler
import com.typewritermc.events.HandlerPlan
import com.typewritermc.events.SessionArrived
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import java.util.UUID
import java.util.concurrent.CopyOnWriteArrayList

/** The panel engine as its deployment wires it, on a real nats-server: the chains it queues run without a tick. */
val PanelEngineTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    val harness = testFixture { SessionHarness.start() }

    test("PANEL-E1 a session the panel engine takes reaches an after handler on its arrival") {
        harness().createBucket()
        val arrived = CopyOnWriteArrayList<SessionArrived>()
        val handler = after(SessionArrived::class) { event, _ -> arrived += event }
        WiredEngine(
            panelModule,
            listOf(provided(handler, listOf(AfterHandler::class, HandlerPlan::class))),
            harness().messaging().buckets,
        ).use { panel ->
            val user = Protagonist(PrincipalId(PrincipalId.USER, "user"))
            val tab = SessionId(UUID.randomUUID().toString())

            panel.reporter.connected(user, tab)

            harness().eventually { Session(user, tab) in arrived.map { it.session } }
        }
    }
}
