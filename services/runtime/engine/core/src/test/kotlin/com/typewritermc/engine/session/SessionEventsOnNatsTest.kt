package com.typewritermc.engine.session

import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.events.ProtagonistJoined
import com.typewritermc.events.ProtagonistLeft
import com.typewritermc.events.SessionArrived
import com.typewritermc.identity.Session
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.delay

/**
 * The session events two engines of one Realm emit on a real nats-server: the broker alone decides which take wins and
 * when a key expires. Timings are the harness's short ones (refresh 300 ms, live 2 s, grace 1 s).
 */
val SessionEventsOnNatsTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    val harness = testFixture { SessionHarness.start() }

    test("SESSION-E1 a session arrives on the engine that takes it, on a join and again on a server move") {
        harness().createBucket()
        val old = harness().engine("engine-a")
        val new = harness().engine("engine-b")
        val (protagonist, id) = harness().player()

        harness().joined(old, protagonist, id)
        harness().eventually { SessionArrived(Session(protagonist, id)) in old.events.all }

        harness().joined(new, protagonist, id)
        harness().eventually { SessionArrived(Session(protagonist, id)) in new.events.all }
    }

    test("SESSION-E2 a protagonist joins only when it had no session key anywhere, not on a rejoin or a server move") {
        harness().createBucket()
        val old = harness().engine("engine-a")
        val new = harness().engine("engine-b")
        val (protagonist, id) = harness().player()
        harness().joined(old, protagonist, id)
        harness().eventually { ProtagonistJoined(protagonist) in old.events.all }

        old.keeper.disconnected(id)
        old.keeper.connected(protagonist, id)
        harness().eventually { old.events.all.count { it == SessionArrived(Session(protagonist, id)) } == 2 }
        harness().joined(new, protagonist, id)
        harness().eventually { SessionArrived(Session(protagonist, id)) in new.events.all }

        old.events.all.count { it == ProtagonistJoined(protagonist) } shouldBe 1
        new.events.all shouldNotContain ProtagonistJoined(protagonist)
    }

    test("SESSION-E3 a protagonist leaves once its last session expired, emitted by the engine that held it last") {
        harness().createBucket()
        val old = harness().engine("engine-a")
        val new = harness().engine("engine-b")
        val (protagonist, id) = harness().player()
        harness().joined(old, protagonist, id)
        harness().joined(new, protagonist, id)

        new.keeper.disconnected(id)

        harness().eventually { ProtagonistLeft(protagonist) in new.events.all }
        delay(SessionHarness.SHORT.refresh * 2)
        old.events.all shouldNotContain ProtagonistLeft(protagonist)
    }

    test("SESSION-E4 a protagonist does not leave while another of its sessions remains") {
        harness().createBucket()
        val minecraft = harness().engine("engine-a")
        val panel = harness().engine("panel.realm")
        val (protagonist, id) = harness().player()
        val (_, tab) = harness().player()
        harness().joined(minecraft, protagonist, id)
        harness().joined(panel, protagonist, tab)

        minecraft.keeper.disconnected(id)
        harness().eventually(within = SessionHarness.SHORT.ttl * 2) { harness().entry(protagonist, id) == null }
        delay(SessionHarness.SHORT.refresh * 2)
        minecraft.events.all shouldNotContain ProtagonistLeft(protagonist)
        panel.events.all shouldNotContain ProtagonistLeft(protagonist)

        panel.keeper.disconnected(tab)
        harness().eventually { ProtagonistLeft(protagonist) in panel.events.all }
    }
}
