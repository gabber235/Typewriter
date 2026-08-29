package com.typewritermc.realm.routes

import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder

internal class RealmCapabilityInvocationRoutes(
    private val source: RealmCapabilityInvocationSource,
    private val contracts: LibraryContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.invokeRealmComputation) { call -> source.computation(call.request) }
            unary(contracts.invokeRealmCommand) { call -> source.command(call.request) }
        }
}
