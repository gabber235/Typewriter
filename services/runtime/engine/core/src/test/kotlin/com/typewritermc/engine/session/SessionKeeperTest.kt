package com.typewritermc.engine.session

import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.identity.EngineId
import com.typewritermc.services.libs.communicator.kv.LeaseState
import com.typewritermc.services.libs.communicator.testing.KeyValueStore
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.comparables.shouldBeGreaterThan
import io.kotest.matchers.comparables.shouldBeLessThanOrEqualTo
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.toJavaDuration

/**
 * Sessions of engines of one Realm on virtual time, over a memory bucket the bucket contract keeps honest. Each engine
 * keeps exactly the sessions its engine kind has, as a test changes them with join and quit. Who holds a contested key
 * is the lease's rule and proven in LeasesTest; these are the session's own outcomes: what the entry says, when a
 * session began, and which engines hold a protagonist.
 */
val SessionKeeperTest by testSuite {
    test("SESSION-1 a join writes the session's key naming its protagonist, its engine and when it connected") {
        val sessions = SessionHarness(KeyValueStore.Memory(testScope)).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val session = sessions.player()

        engine.online.join(session)
        sessions.store.settle()

        sessions.entry(session.protagonist, session.id) shouldBe
            SessionEntry(
                LeaseState.Held(EngineId("engine-a"), KeyValueStore.Memory.START),
                SessionValue(session.protagonist, KeyValueStore.Memory.START),
            )
    }

    test("SESSION-2 a rejoin within the vacancy keeps when the session began and stamps the new connection") {
        val sessions = SessionHarness(KeyValueStore.Memory(testScope)).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val session = sessions.player()
        engine.online.join(session)
        sessions.store.advance(sessions.timings.lease.ttl)

        engine.online.quit(session)
        sessions.store.advance(sessions.timings.lease.vacancy / 2)
        engine.online.join(session)
        sessions.store.advance(sessions.timings.lease.ttl * 3)

        val entry = sessions.entry(session.protagonist, session.id).shouldNotBeNull()
        entry.value.since shouldBe KeyValueStore.Memory.START
        entry.state shouldBe
            LeaseState.Held(
                EngineId("engine-a"),
                KeyValueStore.Memory.START + (sessions.timings.lease.ttl + sessions.timings.lease.vacancy / 2).toJavaDuration(),
            )
    }

    test("SESSION-3 a server move in either order keeps the session and when it began, and lists only the new engine as holder") {
        for (joinFirst in listOf(true, false)) {
            val sessions = SessionHarness(KeyValueStore.Memory(testScope)).apply { createBucket() }
            val old = sessions.engine("engine-a")
            val new = sessions.engine("engine-b")
            val session = sessions.player()
            old.online.join(session)
            sessions.store.advance(sessions.timings.lease.ttl)
            val began =
                sessions
                    .entry(session.protagonist, session.id)
                    .shouldNotBeNull()
                    .value.since

            if (joinFirst) new.online.join(session)
            sessions.store.settle()
            old.online.quit(session)
            sessions.store.settle()
            if (!joinFirst) new.online.join(session)
            sessions.store.advance(sessions.timings.lease.ttl * 3)

            val entry = sessions.entry(session.protagonist, session.id).shouldNotBeNull()
            entry.holder shouldBe EngineId("engine-b")
            entry.value.since shouldBe began
            old.keeper.holders(session.protagonist) shouldBe setOf(EngineId("engine-b"))
        }
    }

    test("SESSION-4 a reloaded engine takes over the sessions it starts with, without a gap, and keeps when they began") {
        val sessions = SessionHarness(KeyValueStore.Memory(testScope)).apply { createBucket() }
        val before = sessions.engine("engine-a")
        val session = sessions.player()
        before.online.join(session)
        sessions.store.advance(sessions.timings.lease.ttl)

        before.keeper.close()
        sessions.engine("engine-a", online = mapOf(session to KeyValueStore.Memory.START))
        sessions.store.settle()

        val entry = sessions.entry(session.protagonist, session.id).shouldNotBeNull()
        entry.state shouldBe LeaseState.Held(EngineId("engine-a"), KeyValueStore.Memory.START)
        entry.value.since shouldBe KeyValueStore.Memory.START
        sessions.store.advance(sessions.timings.lease.ttl * 3)
        sessions.entry(session.protagonist, session.id).shouldNotBeNull().holder shouldBe EngineId("engine-a")
    }

    test("SESSION-5 a session whose key expired during an outage starts again, beginning when the bucket is back") {
        val sessions = SessionHarness(KeyValueStore.Memory(testScope)).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val session = sessions.player()
        engine.online.join(session)
        sessions.store.settle()

        engine.buckets.unreachable = true
        sessions.store.advance(sessions.timings.lease.ttl * 2)
        val back = sessions.store.clock().instant()
        engine.buckets.unreachable = false
        sessions.store.advance(sessions.timings.lease.refresh)

        val entry = sessions.entry(session.protagonist, session.id).shouldNotBeNull()
        entry.holder shouldBe EngineId("engine-a")
        entry.value.since shouldBeGreaterThan back
        entry.value.since shouldBeLessThanOrEqualTo sessions.store.clock().instant()
    }

    test("SESSION-6 sessions that leave right after joining all end once the vacancy passed") {
        val sessions = SessionHarness(KeyValueStore.Memory(testScope)).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val players = List(20) { sessions.player() }

        players.forEach { session ->
            engine.online.join(session)
            sessions.store.settle()
            engine.online.quit(session)
        }
        sessions.store.advance(sessions.timings.lease.vacancy)

        players.forEach { session -> sessions.entry(session.protagonist, session.id).shouldBeNull() }
    }

    test("SESSION-7 the holders of a protagonist are every engine holding one of its sessions") {
        val sessions = SessionHarness(KeyValueStore.Memory(testScope)).apply { createBucket() }
        val minecraft = sessions.engine("engine-a")
        val panel = sessions.engine("panel.realm")
        val session = sessions.player()
        val tab = session.copy(id = sessions.player().id)
        minecraft.online.join(session)
        panel.online.join(tab)
        sessions.store.settle()

        minecraft.keeper.holders(session.protagonist) shouldContainExactlyInAnyOrder setOf(EngineId("engine-a"), EngineId("panel.realm"))
    }

    test("SESSION-8 a damaged or cut off value under a joining session's key is written over, and holders skip such values") {
        val sessions = SessionHarness(KeyValueStore.Memory(testScope)).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val session = sessions.player()
        val (damaged, cutOff) = List(2) { sessions.player().id }
        sessions.unreadable(session.protagonist, damaged)
        sessions.truncated(session.protagonist, cutOff)
        sessions.truncated(session.protagonist, session.id)

        engine.online.join(session)
        sessions.store.advance(1.milliseconds)

        sessions.entry(session.protagonist, session.id).shouldNotBeNull().holder shouldBe EngineId("engine-a")
        engine.keeper.holders(session.protagonist) shouldBe setOf(EngineId("engine-a"))
    }

    test("SESSION-9 right after a quit the session has no holder, while it stays alive and keeps when it began") {
        val sessions = SessionHarness(KeyValueStore.Memory(testScope)).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val session = sessions.player()
        engine.online.join(session)
        sessions.store.advance(sessions.timings.lease.ttl)

        engine.online.quit(session)
        sessions.store.settle()

        engine.keeper.holders(session.protagonist) shouldBe emptySet()
        sessions.entry(session.protagonist, session.id) shouldBe
            SessionEntry(LeaseState.Vacant, SessionValue(session.protagonist, KeyValueStore.Memory.START))
    }

    test("SESSION-10 a quit keeps refreshing the sessions still in the set") {
        val sessions = SessionHarness(KeyValueStore.Memory(testScope)).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val (stays, leaves) = List(2) { sessions.player() }
        engine.online.join(stays)
        engine.online.join(leaves)
        sessions.store.settle()

        engine.online.quit(leaves)
        sessions.store.advance(sessions.timings.lease.ttl * 3)

        sessions.entry(stays.protagonist, stays.id).shouldNotBeNull().holder shouldBe EngineId("engine-a")
    }

    test("SESSION-11 a session that left is vacant at once and never written again, also after its vacancy ended") {
        val sessions = SessionHarness(KeyValueStore.Memory(testScope)).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val session = sessions.player()
        engine.online.join(session)
        sessions.store.advance(sessions.timings.lease.ttl)

        engine.online.quit(session)
        sessions.store.settle()
        sessions.entry(session.protagonist, session.id).shouldNotBeNull().state shouldBe LeaseState.Vacant

        sessions.store.advance(sessions.timings.lease.vacancy)
        sessions.entry(session.protagonist, session.id).shouldBeNull()
        sessions.store.advance(sessions.timings.lease.ttl * 3)
        sessions.entry(session.protagonist, session.id).shouldBeNull()
    }

    test("SESSION-12 an engine that sees an older connection late never displaces the newer one, and its quit leaves the session held") {
        val sessions = SessionHarness(KeyValueStore.Memory(testScope)).apply { createBucket() }
        val old = sessions.engine("engine-a")
        val new = sessions.engine("engine-b")
        val session = sessions.player()
        val connectedToOld = sessions.store.clock().instant()
        sessions.store.advance(sessions.timings.lease.refresh)
        new.online.join(session)
        sessions.store.advance(sessions.timings.lease.refresh)

        old.online.join(session, connected = connectedToOld)
        sessions.store.advance(sessions.timings.lease.ttl)
        old.online.quit(session)
        sessions.store.settle()

        sessions.entry(session.protagonist, session.id).shouldNotBeNull().holder shouldBe EngineId("engine-b")
        old.keeper.holders(session.protagonist) shouldBe setOf(EngineId("engine-b"))
    }

    test("SESSION-13 a new session begins at the instant it connected, however late its engine sees the join") {
        val sessions = SessionHarness(KeyValueStore.Memory(testScope)).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val session = sessions.player()
        val connected = sessions.store.clock().instant()
        sessions.store.advance(sessions.timings.lease.ttl)

        engine.online.join(session, connected = connected)
        sessions.store.settle()

        sessions
            .entry(session.protagonist, session.id)
            .shouldNotBeNull()
            .value.since shouldBe connected
    }
}
