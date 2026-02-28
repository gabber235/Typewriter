package com.typewritermc.services.libs.communicator.routing

class Route(
    val pattern: SubjectPattern,
    val handler: suspend NatsContext.() -> Unit
)
