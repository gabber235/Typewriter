package com.typewritermc.realm.routes

import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.realm.authoring.CreationCatalogChanged
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.catalog.PrepareCreationResult

/**
 * Owns the transport adapters for editor catalog fetches and generation watches.
 *
 * Catalog assembly and generation authority remain in [RealmEditorCatalogSource]. This class only binds those
 * operations to the Realm router, so replacing the router does not replace the source or its snapshot owner.
 */
internal class EditorCatalogRoutes(
    private val source: RealmEditorCatalogSource,
    private val creation: InitializationRuntime,
    private val contracts: EditorContracts,
) {
    /** Registers catalog fetch and initial generation operations on the current Realm router. */
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            watch(contracts.fetchEditorCatalog) { call ->
                val transfer = source.fetch(call.request)
                transfer.updates.forEach { update ->
                    call.publishUpdate(update).requirePublished()
                }
                transfer.initial
            }
            unary(contracts.prepareCreation) { call ->
                try {
                    val request = SkirAuthoringOperationCodec.decode(call.request).getOrThrow()
                    PrepareCreationResult.PreparedWrapper(
                        SkirAuthoringOperationCodec.encode(creation.prepare(request)).getOrThrow(),
                    )
                } catch (changed: CreationCatalogChanged) {
                    PrepareCreationResult.createCatalogChanged(value = changed.actual.value)
                }
            }
            watch(contracts.watchEditorCatalog) { call ->
                source.initialGeneration(call.request)
            }
        }
}
