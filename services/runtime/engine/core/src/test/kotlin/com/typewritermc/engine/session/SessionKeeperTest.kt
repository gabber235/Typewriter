package com.typewritermc.engine.session

import com.typewritermc.engine.session.testing.VirtualSessions
import com.typewritermc.identity.EngineId
import com.typewritermc.services.libs.communicator.testing.VirtualKeyValue
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.comparables.shouldBeGreaterThan
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.toJavaDuration

/**
 * Sessions of engines of one Realm on virtual time, over a memory bucket the bucket contract keeps honest. Who holds a
 * contested key is the lease's rule and proven in LeasesTest; these are the session's own outcomes: what the entry
 * says, when a session began, and which engines hold a protagonist.
 */
val SessionKeeperTest by testSuite {
    test("SESSION-1 a connect writes the session's key naming its protagonist, its engine and when it connected") {
        val sessions = VirtualSessions(testScope).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val (protagonist, session) = sessions.player()

        engine.keeper.connected(protagonist, session)
        engine.keeper.holds(protagonist) shouldBe true
        sessions.keyValue.settle()

        sessions.entry(protagonist, session) shouldBe
            SessionEntry(
                protagonist,
                since = VirtualKeyValue.START,
                state = SessionState.Held(EngineId("engine-a"), connected = VirtualKeyValue.START),
            )
    }

    test("SESSION-2 a rejoin within the vacancy keeps when the session began and stamps the new connection") {
        val sessions = VirtualSessions(testScope).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val (protagonist, session) = sessions.player()
        engine.keeper.connected(protagonist, session)
        sessions.keyValue.advance(sessions.timings.ttl)

        engine.keeper.disconnected(session)
        sessions.keyValue.advance(sessions.timings.vacancy / 2)
        engine.keeper.connected(protagonist, session)
        sessions.keyValue.advance(sessions.timings.ttl * 3)

        val entry = sessions.entry(protagonist, session).shouldNotBeNull()
        entry.since shouldBe VirtualKeyValue.START
        entry.state shouldBe
            SessionState.Held(
                EngineId("engine-a"),
                VirtualKeyValue.START + (sessions.timings.ttl + sessions.timings.vacancy / 2).toJavaDuration(),
            )
    }

    test("SESSION-3 a server move in either order keeps the session and when it began, and lists only the new engine as holder") {
        for (joinFirst in listOf(true, false)) {
            val sessions = VirtualSessions(testScope).apply { createBucket() }
            val old = sessions.engine("engine-a")
            val new = sessions.engine("engine-b")
            val (protagonist, session) = sessions.player()
            old.keeper.connected(protagonist, session)
            sessions.keyValue.advance(sessions.timings.ttl)
            val began = sessions.entry(protagonist, session).shouldNotBeNull().since

            if (joinFirst) new.keeper.connected(protagonist, session)
            old.keeper.disconnected(session)
            if (!joinFirst) new.keeper.connected(protagonist, session)
            sessions.keyValue.advance(sessions.timings.ttl * 3)

            val entry = sessions.entry(protagonist, session).shouldNotBeNull()
            entry.holder shouldBe EngineId("engine-b")
            entry.since shouldBe began
            old.keeper.holders(protagonist) shouldBe setOf(EngineId("engine-b"))
            new.keeper.holds(protagonist) shouldBe true
            old.keeper.holds(protagonist) shouldBe false
        }
    }

    test("SESSION-4 a reloaded engine takes its sessions over without a gap and keeps when they began") {
        val sessions = VirtualSessions(testScope).apply { createBucket() }
        val before = sessions.engine("engine-a")
        val (protagonist, session) = sessions.player()
        before.keeper.connected(protagonist, session)
        sessions.keyValue.advance(sessions.timings.ttl)

        before.keeper.close()
        val after = sessions.engine("engine-a")
        after.keeper.connected(protagonist, session)
        sessions.keyValue.settle()

        val entry = sessions.entry(protagonist, session).shouldNotBeNull()
        entry.holder shouldBe EngineId("engine-a")
        entry.since shouldBe VirtualKeyValue.START
        sessions.keyValue.advance(sessions.timings.ttl * 3)
        sessions.entry(protagonist, session).shouldNotBeNull().holder shouldBe EngineId("engine-a")
    }

    test("SESSION-5 a session whose key expired during an outage starts again once the bucket is back") {
        val sessions = VirtualSessions(testScope).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val (protagonist, session) = sessions.player()
        engine.keeper.connected(protagonist, session)
        sessions.keyValue.settle()

        engine.buckets.unreachable = true
        sessions.keyValue.advance(sessions.timings.ttl * 2)
        engine.buckets.unreachable = false
        sessions.keyValue.advance(sessions.timings.refresh)

        val entry = sessions.entry(protagonist, session).shouldNotBeNull()
        entry.holder shouldBe EngineId("engine-a")
        entry.since shouldBeGreaterThan VirtualKeyValue.START + sessions.timings.ttl.toJavaDuration()
    }

    test("SESSION-6 quits reported right after their joins end every session once the vacancy passed") {
        val sessions = VirtualSessions(testScope).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val players = List(20) { sessions.player() }

        players.forEach { (protagonist, session) ->
            engine.keeper.connected(protagonist, session)
            engine.keeper.disconnected(session)
        }
        sessions.keyValue.advance(sessions.timings.vacancy)

        players.forEach { (protagonist, session) -> sessions.entry(protagonist, session).shouldBeNull() }
    }

    test("SESSION-7 the holders of a protagonist are every engine holding one of its sessions") {
        val sessions = VirtualSessions(testScope).apply { createBucket() }
        val minecraft = sessions.engine("engine-a")
        val panel = sessions.engine("panel.realm")
        val (protagonist, session) = sessions.player()
        val (_, tab) = sessions.player()
        minecraft.keeper.connected(protagonist, session)
        panel.keeper.connected(protagonist, tab)
        sessions.keyValue.settle()

        minecraft.keeper.holders(protagonist) shouldContainExactlyInAnyOrder setOf(EngineId("engine-a"), EngineId("panel.realm"))
    }

    test("SESSION-8 a damaged or cut off value under a joining session's key is written over, and holders skip such values") {
        val sessions = VirtualSessions(testScope).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val (protagonist, session) = sessions.player()
        val (damaged, cutOff) = List(2) { sessions.player().second }
        sessions.unreadable(protagonist, damaged)
        sessions.truncated(protagonist, cutOff)
        sessions.truncated(protagonist, session)

        engine.keeper.connected(protagonist, session)
        sessions.keyValue.advance(1.milliseconds)

        sessions.entry(protagonist, session).shouldNotBeNull().holder shouldBe EngineId("engine-a")
        engine.keeper.holders(protagonist) shouldBe setOf(EngineId("engine-a"))
    }

    test("SESSION-9 right after a quit the session has no holder, while it stays alive and keeps when it began") {
        val sessions = VirtualSessions(testScope).apply { createBucket() }
        val engine = sessions.engine("engine-a")
        val (protagonist, session) = sessions.player()
        engine.keeper.connected(protagonist, session)
        sessions.keyValue.advance(sessions.timings.ttl)

        engine.keeper.disconnected(session)
        sessions.keyValue.settle()

        engine.keeper.holders(protagonist) shouldBe emptySet()
        sessions.entry(protagonist, session) shouldBe SessionEntry(protagonist, since = VirtualKeyValue.START, state = SessionState.Vacant)
    }
}
