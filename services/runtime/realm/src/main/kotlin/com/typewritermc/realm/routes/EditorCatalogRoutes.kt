package com.typewritermc.realm.routes

import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.realm.authoring.PreparationCatalogChanged
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.catalog.PrepareValueResult

/**
 * Owns the transport adapters for editor catalog fetches and generation watches.
 *
 * [RealmEditorCatalogSource] supplies the retained catalog from the catalog owner. This class binds those
 * operations to the Realm router, so replacing the router does not replace its snapshot owner.
 */
internal class EditorCatalogRoutes(
    private val source: RealmEditorCatalogSource,
    private val preparation: InitializationRuntime,
    private val contracts: EditorContracts,
) {
    /** Registers catalog fetch and initial generation operations on the current Realm router. */
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.fetchEditorCatalog) { call -> source.fetch(call.request) }
            unary(contracts.prepareValue) { call ->
                try {
                    val request = SkirAuthoringOperationCodec.decode(call.request).getOrThrow()
                    PrepareValueResult.PreparedWrapper(
                        SkirAuthoringOperationCodec.encode(preparation.step(request)).getOrThrow(),
                    )
                } catch (changed: PreparationCatalogChanged) {
                    PrepareValueResult.createCatalogChanged(value = changed.actual.value)
                }
            }
            watch(contracts.watchEditorCatalog) { call ->
                source.initialGeneration(call.request)
            }
        }
}
