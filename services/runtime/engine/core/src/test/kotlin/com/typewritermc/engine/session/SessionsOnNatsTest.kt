package com.typewritermc.engine.session

import com.typewritermc.engine.session.testing.LateFirstWrite
import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.identity.EngineId
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.delay
import kotlin.time.Duration.Companion.seconds

/**
 * Sessions of engines of one Realm on a real nats-server: the broker alone decides which write wins and when a key
 * expires. Timings are the harness's short ones (refresh 300 ms, live 2 s, grace 1 s).
 */
val SessionsOnNatsTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    val harness = testFixture { SessionHarness.start() }

    test("SESSION-1 a protagonist connecting on an engine writes a sessions key naming it and that engine as holder") {
        harness().createBucket()
        val engine = harness().engine("engine-a")
        val (protagonist, session) = harness().player()

        engine.keeper.connected(protagonist, session)

        harness().eventually { harness().entry(protagonist, session) != null }
        val entry = harness().entry(protagonist, session).shouldNotBeNull()
        entry.protagonist shouldBe protagonist
        entry.holder shouldBe EngineId("engine-a")
    }

    test("SESSION-2 a held session outlives its key's time to live") {
        harness().createBucket()
        val engine = harness().engine("engine-a")
        val (protagonist, session) = harness().player()
        harness().joined(engine, protagonist, session)

        delay(SessionHarness.SHORT.ttl * 2)

        harness().entry(protagonist, session).shouldNotBeNull().holder shouldBe EngineId("engine-a")
    }

    test("SESSION-3 a session ends after the grace once its protagonist quits") {
        harness().createBucket()
        val engine = harness().engine("engine-a")
        val (protagonist, session) = harness().player()
        harness().joined(engine, protagonist, session)

        engine.keeper.disconnected(session)

        harness().eventually(within = SessionHarness.SHORT.ttl) { harness().entry(protagonist, session) == null }
    }

    test("SESSION-4 a rejoin within the grace keeps the session and when it began") {
        harness().createBucket()
        val engine = harness().engine("engine-a")
        val (protagonist, session) = harness().player()
        harness().joined(engine, protagonist, session)
        val since = harness().entry(protagonist, session).shouldNotBeNull().since

        engine.keeper.disconnected(session)
        engine.keeper.connected(protagonist, session)
        delay(SessionHarness.SHORT.ttl * 2)

        harness().entry(protagonist, session).shouldNotBeNull().since shouldBe since
    }

    test("SESSION-5 a server move keeps the session when the new engine's join comes before the old one's quit") {
        harness().createBucket()
        val old = harness().engine("engine-a")
        val new = harness().engine("engine-b")
        val (protagonist, session) = harness().player()
        harness().joined(old, protagonist, session)

        harness().joined(new, protagonist, session)
        old.keeper.disconnected(session)
        delay(SessionHarness.SHORT.ttl * 2)

        harness().entry(protagonist, session).shouldNotBeNull().holder shouldBe EngineId("engine-b")
    }

    test("SESSION-6 a server move keeps the session when the old engine's quit comes before the new one's join") {
        harness().createBucket()
        val old = harness().engine("engine-a")
        val new = harness().engine("engine-b")
        val (protagonist, session) = harness().player()
        harness().joined(old, protagonist, session)

        old.keeper.disconnected(session)
        new.keeper.connected(protagonist, session)
        delay(SessionHarness.SHORT.ttl * 2)

        harness().entry(protagonist, session).shouldNotBeNull().holder shouldBe EngineId("engine-b")
    }

    test("SESSION-7 a crashed engine's sessions end on their own within the time to live") {
        harness().createBucket()
        val engine = harness().engine("engine-a")
        val (protagonist, session) = harness().player()
        harness().joined(engine, protagonist, session)

        engine.crash()

        harness().eventually(within = SessionHarness.SHORT.ttl + 2.seconds) { harness().entry(protagonist, session) == null }
    }

    test("SESSION-8 a reloaded engine takes its online protagonists' sessions over without a gap") {
        harness().createBucket()
        val before = harness().engine("engine-a")
        val (protagonist, session) = harness().player()
        harness().joined(before, protagonist, session)
        val since = harness().entry(protagonist, session).shouldNotBeNull().since

        before.keeper.close()
        val after = harness().engine("engine-a")
        after.keeper.connected(protagonist, session)
        delay(SessionHarness.SHORT.ttl * 2)

        val entry = harness().entry(protagonist, session).shouldNotBeNull()
        entry.holder shouldBe EngineId("engine-a")
        entry.since shouldBe since
    }

    test("SESSION-9 an engine that starts before the Realm created the bucket writes its sessions once it exists") {
        val engine = harness().engine("engine-a")
        val (protagonist, session) = harness().player()
        engine.keeper.connected(protagonist, session)
        delay(SessionHarness.SHORT.refresh)

        harness().createBucket()

        harness().eventually { harness().entry(protagonist, session)?.holder == EngineId("engine-a") }
    }

    test("SESSION-11 a quit reported right after its join ends the session, in the order the engine reported them") {
        harness().createBucket()
        val engine = harness().engine("engine-a")
        val players = List(20) { harness().player() }

        players.forEach { (protagonist, session) ->
            engine.keeper.connected(protagonist, session)
            engine.keeper.disconnected(session)
        }
        delay(SessionHarness.SHORT.ttl * 2)

        players.forEach { (protagonist, session) -> harness().entry(protagonist, session).shouldBeNull() }
    }

    test("SESSION-12 an engine that missed its protagonist's quit lets the session go once another engine took it") {
        harness().createBucket()
        val old = harness().engine("engine-a")
        val new = harness().engine("engine-b")
        val (protagonist, session) = harness().player()
        harness().joined(old, protagonist, session)

        harness().joined(new, protagonist, session)
        delay(SessionHarness.SHORT.refresh * 2)
        new.keeper.disconnected(session)
        delay(SessionHarness.SHORT.ttl * 2)

        harness().entry(protagonist, session).shouldBeNull()
    }

    test("SESSION-13 an engine whose protagonist left before its take reached the broker leaves the session to the engine it moved to") {
        harness().createBucket()
        lateinit var late: LateFirstWrite
        val old = harness().engine("engine-a") { buckets -> LateFirstWrite(buckets).also { late = it } }
        val new = harness().engine("engine-b")
        val (protagonist, session) = harness().player()

        old.keeper.connected(protagonist, session)
        late.reached.await()
        old.keeper.disconnected(session)
        harness().joined(new, protagonist, session)
        val taken = harness().entry(protagonist, session).shouldNotBeNull()
        late.release()

        harness().keeps(new, protagonist, session, taken)
    }

    test("SESSION-14 an engine whose take is still under way when another engine takes the session lets it go instead of writing over it") {
        harness().createBucket()
        lateinit var late: LateFirstWrite
        val old = harness().engine("engine-a") { buckets -> LateFirstWrite(buckets).also { late = it } }
        val new = harness().engine("engine-b")
        val (protagonist, session) = harness().player()

        old.keeper.connected(protagonist, session)
        late.reached.await()
        harness().joined(new, protagonist, session)
        val taken = harness().entry(protagonist, session).shouldNotBeNull()
        late.release()

        harness().keeps(new, protagonist, session, taken)
        old.holding.holds(protagonist) shouldBe false
    }

    test("SESSION-10 the holders of a protagonist are every engine holding one of its sessions, and none once it left") {
        harness().createBucket()
        val minecraft = harness().engine("engine-a")
        val panel = harness().engine("panel.realm")
        val (protagonist, session) = harness().player()
        val (_, tab) = harness().player()
        minecraft.keeper.connected(protagonist, session)
        panel.keeper.connected(protagonist, tab)
        harness().eventually { harness().entry(protagonist, session) != null && harness().entry(protagonist, tab) != null }

        minecraft.keeper.holders(protagonist) shouldContainExactlyInAnyOrder setOf(EngineId("engine-a"), EngineId("panel.realm"))

        minecraft.keeper.disconnected(session)
        panel.keeper.disconnected(tab)
        harness().eventually(within = SessionHarness.SHORT.ttl) { minecraft.keeper.holders(protagonist).isEmpty() }
        harness().entry(protagonist, session).shouldBeNull()
    }
}
