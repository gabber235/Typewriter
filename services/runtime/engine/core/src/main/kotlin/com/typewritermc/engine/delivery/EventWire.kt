package com.typewritermc.engine.delivery

import com.typewritermc.events.EventReason
import com.typewritermc.events.EventResult
import com.typewritermc.events.Origin
import com.typewritermc.identity.Engine
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.Identity
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import java.util.logging.Logger
import skirout.editor.v1.event.EventOrigin as WireOrigin
import skirout.editor.v1.event.EventReason as WireReason
import skirout.editor.v1.event.EventResult as WireResult
import skirout.editor.v1.event.EventSubject as WireSubject
import skirout.editor.v1.event.SessionSubject as WireSessionSubject
import skirout.kernel.v1.identity.EngineId as WireEngineId
import skirout.kernel.v1.identity.PrincipalId as WirePrincipalId
import skirout.kernel.v1.identity.Protagonist as WireProtagonist
import skirout.kernel.v1.identity.SessionId as WireSessionId

private val log: Logger = Logger.getLogger("com.typewritermc.engine.delivery.EventWire")

/** The subject an identity is on the wire. */
internal fun Identity.toWire(): WireSubject =
    when (this) {
        is Protagonist -> WireSubject.ProtagonistWrapper(toWireProtagonist())
        is Session -> WireSubject.createSession(protagonist = protagonist.toWireProtagonist(), session = WireSessionId(value = id.value))
        is Engine -> WireSubject.EngineWrapper(WireEngineId(value = id.value))
    }

/** The identity a wire subject names, or null for a kind this engine does not know. */
internal fun WireSubject.toIdentity(): Identity? =
    when (this) {
        is WireSubject.ProtagonistWrapper -> value.toProtagonist()
        is WireSubject.SessionWrapper -> Session(value.protagonist.toProtagonist(), SessionId(value.session.value))
        is WireSubject.EngineWrapper -> Engine(EngineId(value.value))
        else -> null
    }

private fun Protagonist.toWireProtagonist() = WireProtagonist(principal = WirePrincipalId(kind = principal.kind, id = principal.id))

private fun WireProtagonist.toProtagonist() = Protagonist(PrincipalId(principal.kind, principal.id))

internal fun Origin.toWire(): WireOrigin =
    WireOrigin(session = WireSessionId(value = session.id.value), principal = WirePrincipalId(kind = principal.kind, id = principal.id))

/** The origin of a wire origin, whose session belongs to the protagonist of its principal. */
internal fun WireOrigin.toOrigin(): Origin {
    val principal = PrincipalId(principal.kind, principal.id)
    return Origin(Session(Protagonist(principal), SessionId(session.value)), principal)
}

/** [this] on the wire, its detail encoded by [codec]; a detail without a catalog type is logged and left out. */
internal fun EventResult.toWire(codec: EventCodec): WireResult =
    when (this) {
        EventResult.Done -> WireResult.DONE
        EventResult.NotHandled -> WireResult.NOT_HANDLED
        is EventResult.Denied -> WireResult.DeniedWrapper(reason.toWire(codec))
        is EventResult.Failed -> WireResult.FailedWrapper(reason.toWire(codec))
    }

internal fun WireResult.toResult(codec: EventCodec): EventResult =
    when (this) {
        is WireResult.DeniedWrapper -> EventResult.Denied(value.toReason(codec))
        is WireResult.FailedWrapper -> EventResult.Failed(value.toReason(codec))
        WireResult.DONE -> EventResult.Done
        else -> EventResult.NotHandled
    }

private fun EventReason.toWire(codec: EventCodec): WireReason {
    val encoded =
        detail?.let { detail ->
            codec.encode(detail).also {
                if (it == null) log.warning("The detail of reason $code has no catalog type, so it is sent without its detail.")
            }
        }
    return WireReason(code = code, message = message, detail = encoded)
}

private fun WireReason.toReason(codec: EventCodec): EventReason =
    EventReason(code = code, message = message, detail = detail?.let { (codec.decode(it) as? Decoded.Value)?.value })

/** A reason of a failure delivery itself gives. */
internal fun deliveryFailure(
    code: String,
    message: String,
): EventResult.Failed = EventResult.Failed(EventReason(code = code, message = message))
