package com.typewritermc.engine.delivery

import com.typewritermc.identity.EngineId
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.EngineEventAddress
import com.typewritermc.protocol.transport.generated.engineEvent
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.withContext
import skirout.editor.v1.event.DeliverEventRequest
import skirout.editor.v1.event.DeliverEventResponse
import kotlin.time.Duration

/**
 * How deliveries reach the inboxes of other engines. The NATS link sits on the `engine_event` route; a link between
 * engines of one host can replace it, since nothing above assumes NATS.
 */
interface EngineLink {
    /** Asks [engine]'s inbox [request] and returns its answer, or null when none came within [timeout]. */
    suspend fun ask(
        engine: EngineId,
        request: DeliverEventRequest,
        timeout: Duration,
    ): DeliverEventResponse?

    /** Answers every request to this engine's inbox with [answer] until cancelled. */
    suspend fun serve(answer: suspend (DeliverEventRequest) -> DeliverEventResponse)
}

/**
 * Asks and serves inboxes over the host's messaging session of the moment, in Realm [realm]: this engine's inbox is
 * `engine.<self>.event`. While the host has no session, every ask goes unanswered and the inbox waits for the next.
 */
class NatsEngineLink(
    private val messaging: StateFlow<HostedMessagingSession?>,
    private val realm: String,
    private val self: EngineId,
) : EngineLink {
    override suspend fun ask(
        engine: EngineId,
        request: DeliverEventRequest,
        timeout: Duration,
    ): DeliverEventResponse? {
        val session = messaging.value ?: return null
        val scope = RealmRouteScope(session.organizationId, realm)
        val address = EngineEventAddress(scope, engine.value)
        return when (val result = session.communicator.request(scope.engineEvent(engine.value), address, request, timeout = timeout)) {
            is CommunicationResult.Success -> result.value
            is CommunicationResult.Failure -> null
        }
    }

    override suspend fun serve(answer: suspend (DeliverEventRequest) -> DeliverEventResponse) {
        messaging.collectLatest { session ->
            if (session != null) serve(session, answer)
        }
    }

    private suspend fun serve(
        session: HostedMessagingSession,
        answer: suspend (DeliverEventRequest) -> DeliverEventResponse,
    ): Nothing =
        coroutineScope {
            val scope = RealmRouteScope(session.organizationId, realm)
            val router =
                session.communicator.createRouter(
                    communicatorRoutes {
                        unary(scope.engineEvent(self.value), parallelism = INBOX_PARALLELISM) { call -> answer(call.request) }
                    },
                    this,
                )
            val started = router.start()
            check(started == RouterResult.Success) { "The event inbox of ${self.value} could not start: $started" }
            try {
                awaitCancellation()
            } finally {
                withContext(NonCancellable) { router.stop() }
            }
        }

    private companion object {
        /** How many asks the inbox answers at once; an answer that waits for its occurrence is a suspended coroutine. */
        const val INBOX_PARALLELISM = 256
    }
}
