package com.typewritermc.realm.routes

import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.editorCatalogFetch
import com.typewritermc.protocol.transport.generated.editorCatalogWatch
import com.typewritermc.protocol.transport.generated.editorValuePrepare
import com.typewritermc.realm.operation.PreparationCatalogChanged
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.requireValid
import skirout.editor.v1.catalog.PrepareValueResult
import skirout.editor.v1.catalog.WatchEditorCatalogResponse

/**
 * Owns the transport adapters for editor catalog fetches and generation watches.
 *
 * [RealmEditorCatalogSource] supplies the retained catalog from the catalog owner. This class binds those
 * operations to the Realm router, so replacing the router does not replace its snapshot owner.
 */
internal class EditorCatalogRoutes(
    private val source: RealmEditorCatalogSource,
    private val preparation: InitializationRuntime,
    private val address: RealmRouteScope,
) {
    /** Registers catalog fetch and initial generation operations on the current Realm router. */
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(address.editorCatalogFetch) { call -> source.fetch(call.request) }
            unary(address.editorValuePrepare) { call ->
                try {
                    preparation.step(call.request.requireValid())
                } catch (changed: PreparationCatalogChanged) {
                    PrepareValueResult.createCatalogChangedError(value = changed.actual.value)
                }
            }
            watch(address.editorCatalogWatch) { call ->
                WatchEditorCatalogResponse.InvalidatedWrapper(source.initialGeneration(call.request))
            }
        }
}
