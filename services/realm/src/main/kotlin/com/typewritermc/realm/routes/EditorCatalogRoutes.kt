package com.typewritermc.realm.routes

import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder

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
                source.watch(call.request) { update ->
                    call.communicator
                        .publishUpdate(contracts.watchEditorCatalog, realmAddress, update)
                        .requirePublished()
                }
            }
        }
}
