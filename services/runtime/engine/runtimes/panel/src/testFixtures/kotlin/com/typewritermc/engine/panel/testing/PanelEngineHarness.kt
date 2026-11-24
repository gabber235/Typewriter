package com.typewritermc.engine.panel.testing

import com.typewritermc.engine.panel.PresenceSessions
import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.protocol.transport.OrganizationActorRouteScope
import com.typewritermc.protocol.transport.generated.organizationPresence
import com.typewritermc.services.libs.communicator.kv.LeaseTimings
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
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

/**
 * The panel engine of the [sessions] harness's Realm, fed by panel tabs of [user] that publish the presence heartbeat
 * as the panel does. Heartbeats come every 300 ms, a key lives 2 s, a grace lasts 1 s.
 */
class PanelEngineHarness private constructor(
    val sessions: SessionHarness,
) : AutoCloseable {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val actor = OrganizationActorRouteScope(SessionHarness.ORGANIZATION, "user")

    /** The protagonist every tab belongs to. */
    val user: Protagonist = Protagonist(PrincipalId(PrincipalId.USER, "user"))

    /** A tab of [user] whose heartbeat reports [location] until the returned job is cancelled. */
    suspend fun tab(
        id: String,
        location: PresenceLocation,
    ): Job {
        val messaging = sessions.messaging()
        return scope.launch {
            var sequence = 0L
            while (isActive) {
                messaging.communicator.publish(
                    actor.organizationPresence,
                    actor,
                    PresenceEvent.createActive(sessionId = id, sequence = sequence++, location = location),
                )
                delay(TIMINGS.refresh)
            }
        }
    }

    /** Tab [id] reports that it left, as the panel does when a tab closes. */
    suspend fun left(id: String) {
        sessions.messaging().communicator.publish(actor.organizationPresence, actor, PresenceEvent.createLeft(sessionId = id))
    }

    override fun close() {
        scope.cancel()
        sessions.close()
    }

    /** Starts the panel engine; a heartbeat sent before it subscribed is followed by the next one. */
    private suspend fun startEngine() {
        val engine = sessions.engine("panel.realm", TIMINGS)
        val messaging = sessions.messaging()
        scope.launch { PresenceSessions(sessions.realm, engine.keeper, TIMINGS).serve(messaging) }
    }

    companion object {
        /** The panel engine's timings in the harness. */
        val TIMINGS: LeaseTimings =
            LeaseTimings(refresh = 300.milliseconds, ttl = 2.seconds, grace = 1.seconds, retry = 100.milliseconds)

        /** The location of a tab in Realm [id]. */
        fun realm(id: String): PresenceLocation =
            PresenceLocation.createRealm(realmId = RecordId(table = "realm", key = RecordIdKey.StringWrapper(id)))

        /** A panel engine on a fresh harness whose sessions bucket exists. */
        suspend fun start(): PanelEngineHarness {
            val sessions = SessionHarness.start()
            sessions.createBucket()
            return PanelEngineHarness(sessions).also { it.startEngine() }
        }
    }
}
