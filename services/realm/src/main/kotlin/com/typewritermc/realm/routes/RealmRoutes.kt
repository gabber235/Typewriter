package com.typewritermc.realm.routes

import com.typewritermc.services.libs.communicator.routing.NatsRouting
import com.typewritermc.services.libs.registrar.Credential
import com.typewritermc.services.libs.registrar.RegistrationState
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.StateProvider

class RealmRoutes(
    private val credentials: DeferredProvider<Credential>,
    private val registrationStateProvider: StateProvider<RegistrationState>,
) {
    fun configure(): NatsRouting.() -> Unit = {
        val serviceId = credentials.require { "RealmRoutes requires the credentials to be set to register" }.id
        val orgId = when (val state = registrationStateProvider.get()) {
            is RegistrationState.Bound -> state.organizationId
            else -> error("Service must be bound to an organization before routes can be configured")
        }
        route("realm.to.${serviceId}.organization.${orgId}") {
            handle("ping") {
                span.setAttribute("operation", "ping")
                reply("pong".toByteArray())
            }
        }
    }
}
