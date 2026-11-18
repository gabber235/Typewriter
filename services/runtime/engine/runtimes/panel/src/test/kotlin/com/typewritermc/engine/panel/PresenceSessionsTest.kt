package com.typewritermc.engine.panel

import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.protocol.transport.OrganizationActorRouteScope
import com.typewritermc.protocol.transport.generated.organizationPresence
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.organization.v1.presence.PresenceEvent
import skirout.organization.v1.presence.PresenceLocation
import java.util.UUID
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * The panel engine of Realm `realm` on a real nats-server: panel tabs publish the presence heartbeat as the panel does,
 * and the broker decides every key's expiry. Timings are short: heartbeats every 300 ms, keys live 2 s, a grace of 1 s.
 */
val PresenceSessionsTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    val harness = testFixture { SessionHarness.start() }
    val timings = SessionTimings(refresh = 300.milliseconds, ttl = 2.seconds, grace = 1.seconds, retry = 100.milliseconds)

    /** Starts the panel engine's presence sessions and returns the scope that runs them. */
    suspend fun panelEngine(): CoroutineScope {
        val engine = harness().engine("panel.realm", timings)
        val messaging = harness().messaging()
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        scope.launch { PresenceSessions(harness().realm, engine.keeper, timings).serve(messaging) }
        delay(300.milliseconds)
        return scope
    }

    /** A panel tab of `user` whose heartbeat reports [location] until the returned job is cancelled. */
    suspend fun tab(
        id: String,
        location: PresenceLocation,
        scope: CoroutineScope,
    ): Job {
        val messaging = harness().messaging()
        val presence = OrganizationActorRouteScope(SessionHarness.ORGANIZATION, "user").organizationPresence
        return scope.launch {
            var sequence = 0L
            while (isActive) {
                messaging.communicator.publish(
                    presence,
                    OrganizationActorRouteScope(SessionHarness.ORGANIZATION, "user"),
                    PresenceEvent.createActive(sessionId = id, sequence = sequence++, location = location),
                )
                delay(300.milliseconds)
            }
        }
    }

    suspend fun left(id: String) {
        val presence = OrganizationActorRouteScope(SessionHarness.ORGANIZATION, "user").organizationPresence
        harness().messaging().communicator.publish(
            presence,
            OrganizationActorRouteScope(SessionHarness.ORGANIZATION, "user"),
            PresenceEvent.createLeft(sessionId = id),
        )
    }

    val user = Protagonist(PrincipalId(PrincipalId.USER, "user"))
    fun realm(id: String) = PresenceLocation.createRealm(realmId = RecordId(table = "realm", key = RecordIdKey.StringWrapper(id)))

    test("PANEL-S1 a tab in the engine's Realm is a session of its user held by the panel engine while its heartbeat lasts") {
        harness().createBucket()
        val scope = panelEngine()
        try {
            val id = UUID.randomUUID().toString()
            tab(id, realm("realm"), scope)

            harness().eventually { harness().entry(user, SessionId(id)) != null }
            delay(timings.ttl * 2)

            harness().entry(user, SessionId(id)).shouldNotBeNull().holder shouldBe EngineId("panel.realm")
        } finally {
            scope.cancel()
        }
    }

    test("PANEL-S2 a tab that leaves, or whose heartbeat stops, ends its session after the grace") {
        harness().createBucket()
        val scope = panelEngine()
        try {
            val leaving = UUID.randomUUID().toString()
            val closed = UUID.randomUUID().toString()
            val leavingTab = tab(leaving, realm("realm"), scope)
            val closedTab = tab(closed, realm("realm"), scope)
            harness().eventually { harness().entry(user, SessionId(leaving)) != null && harness().entry(user, SessionId(closed)) != null }

            leavingTab.cancel()
            left(leaving)
            closedTab.cancel()

            harness().eventually(within = timings.ttl + timings.grace) { harness().entry(user, SessionId(leaving)) == null }
            harness().eventually(within = timings.ttl * 2 + timings.grace) { harness().entry(user, SessionId(closed)) == null }
        } finally {
            scope.cancel()
        }
    }

    test("PANEL-S3 a tab in another Realm or outside any Realm has no session on this engine") {
        harness().createBucket()
        val scope = panelEngine()
        try {
            val elsewhere = UUID.randomUUID().toString()
            val members = UUID.randomUUID().toString()
            tab(elsewhere, realm("other"), scope)
            tab(members, PresenceLocation.createMembers(), scope)

            delay(timings.ttl)

            harness().entry(user, SessionId(elsewhere)).shouldBeNull()
            harness().entry(user, SessionId(members)).shouldBeNull()
        } finally {
            scope.cancel()
        }
    }
}
