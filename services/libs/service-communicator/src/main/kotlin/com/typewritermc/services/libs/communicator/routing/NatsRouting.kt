package com.typewritermc.services.libs.communicator.routing

import com.typewritermc.services.libs.communicator.interfaces.MessageBus

@NatsRoutingDsl
class NatsRouting(internal val messageBus: MessageBus) {
    internal val routes = mutableListOf<Route>()

    fun route(pattern: String, block: RouteBuilder.() -> Unit) {
        val builder = RouteBuilder(this, pattern)
        builder.block()
    }

    fun handle(pattern: String, handler: suspend NatsContext.() -> Unit) {
        routes.add(Route(
            pattern = SubjectPattern(pattern),
            handler = handler
        ))
    }
}

fun natsRouting(messageBus: MessageBus, block: NatsRouting.() -> Unit): NatsRouting {
    return NatsRouting(messageBus).apply(block)
}
