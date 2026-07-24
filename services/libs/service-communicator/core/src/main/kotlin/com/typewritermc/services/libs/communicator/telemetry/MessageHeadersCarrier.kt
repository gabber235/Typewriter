package com.typewritermc.services.libs.communicator.telemetry

import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import io.opentelemetry.context.propagation.TextMapGetter
import io.opentelemetry.context.propagation.TextMapSetter

/** Case-insensitive propagator getter for immutable message headers. */
object MessageHeadersGetter : TextMapGetter<MessageHeaders> {
    override fun keys(carrier: MessageHeaders): Iterable<String> = carrier.map { it.first }

    override fun get(carrier: MessageHeaders?, key: String): String? = carrier?.first(key)
}

/** Propagator setter that immutably replaces values owned by the propagator. */
class MessageHeadersSetter(initial: MessageHeaders, ownedFields: Collection<String> = emptyList()) :
    TextMapSetter<Unit> {
    /** Current immutable headers after all injections. */
    var headers: MessageHeaders = ownedFields.fold(initial) { headers, field -> headers.remove(field) }
        private set

    override fun set(carrier: Unit?, key: String, value: String) {
        headers = headers.set(key, value)
    }
}
