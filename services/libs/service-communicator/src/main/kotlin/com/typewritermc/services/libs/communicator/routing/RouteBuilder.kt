package com.typewritermc.services.libs.communicator.routing

@DslMarker
annotation class NatsRoutingDsl

@NatsRoutingDsl
class RouteBuilder(
    private val routing: NatsRouting,
    private val prefix: String
) {
    fun handle(action: String, handler: suspend NatsContext.() -> Unit) {
        routing.routes.add(Route(
            pattern = SubjectPattern(prefix.join(action)),
            handler = handler
        ))
    }

    fun route(pattern: String, block: RouteBuilder.() -> Unit) {
        val nested = RouteBuilder(routing, prefix.join(pattern))
        nested.block()
    }

    fun handler(action: String, handlerProvider: () -> NatsHandler) {
        routing.routes.add(Route(
            pattern = SubjectPattern(prefix.join(action)),
            handler = { handlerProvider().handle(this) }
        ))
    }
}
