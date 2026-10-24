package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.editorCapabilityCommandInvoke
import com.typewritermc.protocol.transport.generated.editorCapabilityComputationInvoke
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder

/**
 * Registers unary computation and command dispatch against the shared Realm capability source.
 *
 * Validation and handler outcome mapping belong to the source; the router owns request context and subscriptions.
 */
internal class RealmCapabilityInvocationRoutes(
    private val source: RealmCapabilityInvocationSource,
    private val address: RealmRouteScope,
) {
    /** Registers computation and command calls while leaving validation and dispatch ownership with [source]. */
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(address.editorCapabilityComputationInvoke) { call -> source.computation(call.request) }
            unary(address.editorCapabilityCommandInvoke) { call -> source.command(call.request) }
        }
}
