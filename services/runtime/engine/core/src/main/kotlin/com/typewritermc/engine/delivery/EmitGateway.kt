package com.typewritermc.engine.delivery

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.engine.delivery.Occurrences.First
import com.typewritermc.engine.session.SessionKeeper
import com.typewritermc.engine.session.SessionsCopy
import com.typewritermc.events.Origin
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.HostedRuntimeIdentity
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.eventEmit
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import skirout.editor.v1.event.EmitEventRequest
import skirout.editor.v1.event.EmitEventResponse
import skirout.editor.v1.event.EventStatus
import kotlin.time.Duration.Companion.milliseconds

/**
 * Where clients emit events caused by their own sessions: a panel tab today. The caller is the user the broker bound
 * into the request's subject, never a value from the payload. The gateway checks in its copy of the Realm's sessions
 * that the caller holds the named session, makes that session the origin, and relays the event, still encoded, to
 * every holder of its subject; the client asks again with the same occurrence until the merged result is final. Any
 * engine can be a gateway, since the check needs nothing but the sessions copy.
 */
class EmitGateway(
    private val sessions: SessionsCopy,
    private val delivery: Delivery,
    private val codec: EventCodec,
    private val occurrences: Occurrences,
) {
    suspend fun answer(
        user: String,
        request: EmitEventRequest,
    ): EmitEventResponse =
        occurrences.answer(request.occurrence.value, request.waitMs.coerceAtLeast(0).milliseconds, { first(user, request) }) { result ->
            EmitEventResponse.SuccessWrapper(result?.let { EventStatus.FinalWrapper(it.toWire(codec)) } ?: EventStatus.RUNNING)
        }

    /**
     * What a client's first ask about an occurrence leads to: refused when the client had an answer before, or when
     * [user] holds no session named as the cause; else the relay to every holder of the subject.
     */
    private suspend fun first(
        user: String,
        request: EmitEventRequest,
    ): First<EmitEventResponse> {
        if (request.confirmed) return First.Refused(EmitEventResponse.createForgottenError(occurrence = request.occurrence))
        val principal = PrincipalId(PrincipalId.USER, user)
        val caller = Protagonist(principal)
        val session = SessionId(request.session.value)
        if (sessions.entry(session)?.protagonist != caller) {
            return First.Refused(EmitEventResponse.createSessionNotHeldError(session = request.session))
        }
        val subject = request.subject.toIdentity() ?: return First.Run { UNKNOWN_SUBJECT }
        val origin = Origin(Session(caller, session), principal)
        return First.Run { delivery.relay(request.occurrence, subject, request.event, origin) }
    }

    private companion object {
        val UNKNOWN_SUBJECT = deliveryFailure("unknown_subject", "This gateway does not know the kind of identity the event is about.")
    }
}

/**
 * Serves an [EmitGateway] for every member of the organization in this engine's Realm, through each messaging session
 * the host lends the engine, one at a time. An engine kind whose clients emit events registers it.
 */
class EmitGatewayRegistrar(
    private val host: HostedRuntimeHost,
    private val identity: HostedRuntimeIdentity,
    private val keeper: SessionKeeper,
    private val delivery: Delivery,
    private val codec: EventCodec,
    private val timings: DeliveryTimings,
) : RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() {
        val gateway = EmitGateway(keeper.copy, delivery, codec, Occurrences(scope.coroutineScope, timings))
        scope.coroutineScope.launch {
            host.messaging.collectLatest { messaging -> messaging?.let { serve(it, gateway) } }
        }
    }

    private suspend fun serve(
        messaging: HostedMessagingSession,
        gateway: EmitGateway,
    ): Nothing =
        coroutineScope {
            val realm = RealmRouteScope(messaging.organizationId, identity.realmId)
            val router =
                messaging.communicator.createRouter(
                    communicatorRoutes {
                        unary(realm.eventEmit, parallelism = GATEWAY_PARALLELISM) { call -> gateway.answer(call.address.userId, call.request) }
                    },
                    this,
                )
            val started = router.start()
            check(started == RouterResult.Success) { "The event emit gateway could not start: $started" }
            try {
                awaitCancellation()
            } finally {
                withContext(NonCancellable) { router.stop() }
            }
        }

    private companion object {
        /** How many emits the gateway answers at once; an answer that waits for its result is a suspended coroutine. */
        const val GATEWAY_PARALLELISM = 256
    }
}
