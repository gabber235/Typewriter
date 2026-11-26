package com.typewritermc.engine.panel.testing

import com.typewritermc.engine.panel.PresenceSessions
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.protocol.transport.OrganizationActorRouteScope
import com.typewritermc.protocol.transport.generated.organizationPresence
import com.typewritermc.services.libs.communicator.testing.KeyValueStore
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.organization.v1.presence.PresenceEvent
import skirout.organization.v1.presence.PresenceLocation
import java.util.concurrent.atomic.AtomicLong

/**
 * The panel engine of the Realm of [sessions], on [store]: in memory on virtual time, or on a real nats-server. Tabs of
 * [user] publish presence events through the store's broker as the panel does, to the messaging session the host lends
 * the engine now; [connect] lends it a new one, as a reconnect does. Closing stops the engine and the store.
 */
class PanelEngineHarness(
    store: KeyValueStore,
    timings: SessionTimings = SessionHarness.SHORT,
) : AutoCloseable {
    /** The Realm's sessions bucket, the store and the timings every part shares. */
    val sessions: SessionHarness = SessionHarness(store, timings)

    /** The panel engine's sessions. */
    val presence: PresenceSessions = PresenceSessions(sessions.realm, timings, store.scope, store.time, store.clock())

    /** The protagonist every tab belongs to. */
    val user: Protagonist = Protagonist(PrincipalId(PrincipalId.USER, "user"))

    private val actor = OrganizationActorRouteScope(SessionHarness.ORGANIZATION, "user")
    private val sequence = AtomicLong()
    private lateinit var tabs: HostedMessagingSession
    private var serving: Job? = null

    /** Creates the sessions bucket, starts the panel engine's keeper and lends the engine its first messaging session. */
    suspend fun start() {
        sessions.createBucket()
        sessions.keeper(ENGINE, presence)
        tabs = sessions.messaging()
        connect()
    }

    /** The host lends the engine a new messaging session; the one it served presence through before stops. */
    suspend fun connect() {
        serving?.cancel()
        val messaging = sessions.messaging()
        serving = sessions.store.scope.launch { presence.serve(messaging) }
        sessions.store.settle()
    }

    /** One heartbeat of tab [id] at [location]; returns once everything it caused that is due now ran. */
    suspend fun heartbeat(
        id: String,
        location: PresenceLocation = realm(sessions.realm),
    ) = send(PresenceEvent.createActive(sessionId = id, sequence = sequence.getAndIncrement(), location = location))

    /**
     * Tab [id] at [location], sending a heartbeat every refresh until the returned job is cancelled. On a broker, a
     * heartbeat sent before the engine subscribed is followed by the next one.
     */
    fun tab(
        id: String,
        location: PresenceLocation = realm(sessions.realm),
    ): Job =
        sessions.store.scope.launch {
            while (isActive) {
                heartbeat(id, location)
                delay(sessions.timings.lease.refresh)
            }
        }

    /** Tab [id] reports that it left, as the panel does when a tab closes. */
    suspend fun left(id: String) = send(PresenceEvent.createLeft(sessionId = id))

    override fun close() = sessions.close()

    private suspend fun send(event: PresenceEvent) {
        tabs.communicator.publish(actor.organizationPresence, actor, event)
        sessions.store.settle()
    }

    companion object {
        /** The panel engine's id. */
        const val ENGINE: String = "panel.realm"

        /** The location of a tab in Realm [id]. */
        fun realm(id: String): PresenceLocation =
            PresenceLocation.createRealm(realmId = RecordId(table = "realm", key = RecordIdKey.StringWrapper(id)))
    }
}
