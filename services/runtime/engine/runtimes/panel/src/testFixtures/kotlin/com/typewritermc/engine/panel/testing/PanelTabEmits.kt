package com.typewritermc.engine.panel.testing

import com.typewritermc.engine.delivery.testing.TestEventCodec
import com.typewritermc.events.Event
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.protocol.transport.RealmActorRouteScope
import com.typewritermc.protocol.transport.generated.eventEmit
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.event.EmitEventRequest
import skirout.editor.v1.event.EmitEventResponse
import skirout.editor.v1.event.EventResult
import skirout.editor.v1.event.EventStatus
import skirout.editor.v1.event.OccurrenceId
import java.util.UUID
import skirout.editor.v1.event.EventSubject as WireSubject
import skirout.kernel.v1.identity.PrincipalId as WirePrincipalId
import skirout.kernel.v1.identity.SessionId as WireSessionId

/** The panel user `user` of organization `organization`, whose tabs [emit] through Realm `realm`. */
val PANEL_USER = Protagonist(PrincipalId(PrincipalId.USER, "user"))

/** Emits [event] at [subject] as caused by this tab's [session], as panel user `user`, waiting long enough for a final answer. */
suspend fun Communicator.emit(
    session: String,
    subject: Protagonist,
    event: Event,
): EmitEventResponse {
    val actor = RealmActorRouteScope("organization", "realm", "user")
    val request =
        EmitEventRequest(
            occurrence = OccurrenceId(value = UUID.randomUUID().toString()),
            session = WireSessionId(value = session),
            subject = WireSubject.createProtagonist(principal = WirePrincipalId(kind = subject.principal.kind, id = subject.principal.id)),
            event = TestEventCodec().encode(event),
            waitMs = 3000,
            confirmed = false,
        )
    return when (val result = request(actor.eventEmit, actor, request)) {
        is CommunicationResult.Success -> result.value
        is CommunicationResult.Failure -> error("the tab's emit failed: ${result.error}")
    }
}

/** The final result this answer carries; fails when it carries none. */
fun EmitEventResponse.finalResult(): EventResult {
    val status = shouldBeInstanceOf<EmitEventResponse.SuccessWrapper>().value
    return status.shouldBeInstanceOf<EventStatus.FinalWrapper>().value
}
