package com.typewritermc.services.libs.communicator.routing

interface NatsHandler {
    suspend fun handle(ctx: NatsContext)
}
