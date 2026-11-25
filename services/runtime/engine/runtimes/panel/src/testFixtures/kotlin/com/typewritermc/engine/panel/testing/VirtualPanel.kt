package com.typewritermc.engine.panel.testing

import com.typewritermc.engine.panel.PresenceSessions
import com.typewritermc.engine.panel.testing.PanelEngineHarness.Companion.TIMINGS
import com.typewritermc.engine.panel.testing.PanelEngineHarness.Companion.realm
import com.typewritermc.engine.session.testing.VirtualSessions
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.protocol.transport.OrganizationActorRouteScope
import com.typewritermc.protocol.transport.generated.organizationPresence
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.testing.ScriptedBuckets
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.testTimeSource
import skirout.organization.v1.presence.PresenceEvent
import skirout.organization.v1.presence.PresenceLocation

/**
 * The panel engine of Realm `realm` on the virtual time of [scope], over a sessions bucket in memory: tabs of [user]
 * send presence heartbeats through the messaging session the host lends the engine now, and [connect] lends it a new
 * one, as a reconnect does. Timings are [TIMINGS]: a key lives 2 s, a vacancy lasts 1 s.
 */
class VirtualPanel(
    private val scope: TestScope,
) {
    /** The Realm's sessions and the clock every part shares. */
    val sessions: VirtualSessions = VirtualSessions(scope, TIMINGS)

    /** The panel engine's sessions. */
    val presence: PresenceSessions =
        PresenceSessions(REALM, TIMINGS, scope.backgroundScope, scope.testTimeSource, sessions.keyValue.clock())

    /** The protagonist every tab belongs to. */
    val user: Protagonist = Protagonist(PrincipalId(PrincipalId.USER, "user"))

    private val actor = OrganizationActorRouteScope(ORGANIZATION, "user")
    private val telemetry = OpenTelemetry.noop().serviceTelemetry("virtual panel")
    private var transport = FakeMessageTransport()
    private var serving: Job? = null
    private var lent = 0L
    private var sequence = 0L

    /** Creates the sessions bucket, starts the panel engine's keeper and lends the engine its first messaging session. */
    suspend fun start() {
        sessions.createBucket()
        sessions.keeper(ENGINE, presence)
        connect()
    }

    /** The host lends the engine a new messaging session; the one it served presence through before stops. */
    fun connect() {
        serving?.cancel()
        transport = FakeMessageTransport()
        val messaging =
            HostedMessagingSession(
                id = ++lent,
                organizationId = ORGANIZATION,
                communicator = Communicator(transport, telemetry, ContextPropagators.noop()),
                buckets = ScriptedBuckets(sessions.keyValue.store),
            )
        serving = scope.backgroundScope.launch { presence.serve(messaging) }
        sessions.keyValue.settle()
    }

    /** One heartbeat of tab [id] at [location], as the broker hands it to the messaging session lent now. */
    suspend fun heartbeat(
        id: String,
        location: PresenceLocation = realm(REALM),
    ) {
        Communicator(transport, telemetry, ContextPropagators.noop())
            .publish(
                actor.organizationPresence,
                actor,
                PresenceEvent.createActive(sessionId = id, sequence = sequence++, location = location),
            )
        val sent = transport.publications.last()
        transport.deliver(TransportDelivery.Message(InboundMessage(sent.address, sent.payload, headers = sent.headers)))
        sessions.keyValue.settle()
    }

    companion object {
        /** The Realm of the panel engine. */
        const val REALM: String = "realm"

        /** The panel engine's id. */
        const val ENGINE: String = "panel.realm"

        /** The organization the Realm belongs to. */
        const val ORGANIZATION: String = "organization"
    }
}
