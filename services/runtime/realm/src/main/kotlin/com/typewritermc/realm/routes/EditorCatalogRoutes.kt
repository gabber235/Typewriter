package com.typewritermc.realm.routes

import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder

/**
 * Owns the transport adapters for editor catalog fetches and generation watches.
 *
 * Catalog assembly and generation authority remain in [RealmEditorCatalogSource]. This class only binds those
 * operations to the Realm router, so replacing the router does not replace the source or its snapshot owner.
 */
internal class EditorCatalogRoutes(
    private val source: RealmEditorCatalogSource,
    private val contracts: EditorContracts,
    private val realmAddress: RealmAddress,
) {
    /** Registers catalog fetch and initial generation operations on the current Realm router. */
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.fetchEditorCatalog) { call ->
                source.fetch(call.request)
            }
            unary(contracts.initializeTypedValue) { call ->
                source.initialize(call.request)
            }
            watch(contracts.watchEditorCatalog) { call ->
                source.initialGeneration(call.request)
            }
        }
}
