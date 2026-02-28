package com.typewritermc.realm.routes

import com.typewritermc.services.libs.communicator.routing.NatsRouting

class RealmRoutes {
    fun configure(): NatsRouting.() -> Unit = {
        route("realm.in.{serviceId}") {
            handle("ping") {
                reply("pong".toByteArray())
            }
        }
    }
}
