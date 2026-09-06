package com.typewritermc.realm.routes

import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder

/**
 * Registers editor catalog fetching and initial generation observation.
 *
 * The source owns catalog content; generation change publication is handled by the Realm invalidation lifecycle.
 */
internal class EditorCatalogRoutes(
    private val source: RealmEditorCatalogSource,
    private val contracts: LibraryContracts,
    private val realmAddress: RealmAddress,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.fetchEditorCatalog) { call ->
                source.fetch(call.request)
            }
            watch(contracts.watchEditorCatalog) { call ->
                source.initialGeneration(call.request)
            }
        }
}
