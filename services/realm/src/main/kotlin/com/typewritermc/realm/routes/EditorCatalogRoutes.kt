package com.typewritermc.realm.routes

import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder

internal class EditorCatalogRoutes(
    private val source: RealmEditorCatalogSource,
    private val elements: RealmElementCatalogSource,
    private val contracts: LibraryContracts,
    private val realmAddress: RealmAddress,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.fetchEditorCatalog) { call ->
                source.fetch(call.request)
            }
            unary(contracts.fetchElementCatalog) { call ->
                elements.fetch(call.request)
            }
            watch(contracts.watchEditorCatalog) { call ->
                source.initialGeneration(call.request)
            }
        }
}
