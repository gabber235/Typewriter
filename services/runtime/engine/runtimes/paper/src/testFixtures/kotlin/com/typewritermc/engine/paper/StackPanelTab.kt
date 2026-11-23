package com.typewritermc.engine.paper

import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.protocol.transport.OrganizationActorRouteScope
import com.typewritermc.protocol.transport.RealmActorRouteScope
import com.typewritermc.protocol.transport.generated.eventEmit
import com.typewritermc.protocol.transport.generated.organizationPresence
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import skirout.editor.v1.event.EmitEventRequest
import skirout.editor.v1.event.EmitEventResponse
import skirout.editor.v1.event.EventResult
import skirout.editor.v1.event.EventStatus
import skirout.editor.v1.event.EventSubject
import skirout.editor.v1.event.OccurrenceId
import skirout.editor.v1.type_catalog.DataValue
import skirout.kernel.v1.identity.SessionId
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.organization.v1.presence.PresenceEvent
import skirout.organization.v1.presence.PresenceLocation
import java.util.UUID
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * A panel tab of the stack owner, open on the stack's Realm as the panel opens one: while it is open its presence
 * heartbeat keeps it a session at the Realm's panel engine, and it emits events through `event_emit` as the owner, asking
 * again with the same occurrence until the answer is final. Opened by [StackAuthor.panelTab].
 */
class StackPanelTab internal constructor(
    private val stack: StackConnection,
    private val actor: RealmActorRouteScope,
) {
    /** The tab's session id, which its heartbeat and its emits name. */
    val session: String = UUID.randomUUID().toString().replace("-", "")

    /** The owner as the panel engine reports the tab's session: a panel user. */
    val protagonist: Protagonist = Protagonist(PrincipalId(PrincipalId.USER, actor.userId))

    /** Sends the heartbeat every [HEARTBEAT] in [scope] until [scope] ends, as an open tab of the panel does. */
    internal fun beat(scope: CoroutineScope) =
        scope.launch {
            val presence = OrganizationActorRouteScope(actor.organizationId, actor.userId)
            val location =
                PresenceLocation.createRealm(realmId = RecordId(table = "realm", key = RecordIdKey.StringWrapper(actor.realmId)))
            var sequence = 0L
            while (isActive) {
                stack.communicator.publish(
                    presence.organizationPresence,
                    presence,
                    PresenceEvent.createActive(sessionId = session, sequence = sequence++, location = location),
                )
                delay(HEARTBEAT)
            }
        }

    /** Says the tab left, as the panel does when a tab closes, so the panel engine ends its session at once. */
    internal suspend fun leave() {
        val presence = OrganizationActorRouteScope(actor.organizationId, actor.userId)
        stack.communicator.publish(presence.organizationPresence, presence, PresenceEvent.createLeft(sessionId = session))
    }

    /**
     * Emits [event], an event encoded as the Realm's catalog types it, at [subject] and returns its final result. Until
     * the panel engine reports the tab's first heartbeat it answers that the tab holds no session; the tab asks again
     * then, for up to [SESSION_LIMIT]. Fails after [RESULT_LIMIT] without a final answer.
     */
    suspend fun emit(
        subject: EventSubject,
        event: DataValue,
    ): EventResult {
        val occurrence = OccurrenceId(value = UUID.randomUUID().toString())
        val started = TimeSource.Monotonic.markNow()
        var confirmed = false
        while (started.elapsedNow() < RESULT_LIMIT) {
            val request =
                EmitEventRequest(
                    occurrence = occurrence,
                    session = SessionId(value = session),
                    subject = subject,
                    event = event,
                    waitMs = WAIT.inWholeMilliseconds.toInt(),
                    confirmed = confirmed,
                )
            val response =
                when (val result = stack.communicator.request(actor.eventEmit, actor, request)) {
                    is CommunicationResult.Success -> result.value
                    is CommunicationResult.Failure -> error("the tab's event emit failed: ${result.error}")
                }
            when (response) {
                is EmitEventResponse.SuccessWrapper -> {
                    confirmed = true
                    val status = response.value
                    if (status is EventStatus.FinalWrapper) return status.value
                }

                is EmitEventResponse.SessionNotHeldErrorWrapper -> {
                    check(!confirmed && started.elapsedNow() < SESSION_LIMIT) {
                        "the panel engine reports no session for tab $session"
                    }
                    delay(SESSION_RETRY)
                }

                else -> {
                    error("the panel engine answered the tab's event emit with $response")
                }
            }
        }
        error("the tab's event got no final answer within $RESULT_LIMIT")
    }

    private companion object {
        /** How often an open tab sends its heartbeat; the panel sends one every 15 seconds. */
        val HEARTBEAT: Duration = 15.seconds

        /** How long the panel engine may answer later than at once, while the event runs. */
        val WAIT: Duration = 200.milliseconds

        /** How long the tab waits before asking again while the panel engine reports no session for it yet. */
        val SESSION_RETRY: Duration = 200.milliseconds

        /** How long the panel engine may take to report the tab's first heartbeat. */
        val SESSION_LIMIT: Duration = 10.seconds

        /** How long an event may take to end on every engine that holds its subject. */
        val RESULT_LIMIT: Duration = 60.seconds
    }
}
