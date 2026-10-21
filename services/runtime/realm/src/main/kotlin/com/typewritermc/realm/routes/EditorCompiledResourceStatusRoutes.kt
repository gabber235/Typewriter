package com.typewritermc.realm.routes

import com.typewritermc.engine.requireValid
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringCompiledStatusQuery
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.compiler.CompiledRootStatuses
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.editor.v1.compiled_content.CompilationStatusSelection
import skirout.editor.v1.compiled_content.CompiledResourceStatus
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse

/** Reports roots present in the Realm selected publication; it does not inspect engine application state. */
internal class EditorCompiledResourceStatusRoutes(
    private val views: AuthoringViewStore,
    private val statuses: CompiledRootStatuses,
    private val address: RealmRouteScope,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(address.authoringCompiledStatusQuery) { call ->
                val selection = call.request.selection
                when (selection) {
                    CompilationStatusSelection.ALL_ROOTS -> Unit
                    is CompilationStatusSelection.SuppliedRootsWrapper -> selection.value.forEach { root -> root.requireValid() }
                    else -> error("Unknown compilation status selection.")
                }
                views.capture().use { capture ->
                    QueryCompiledResourceStatusResponse.createSuccess(
                        statuses =
                            statuses
                                .query(capture.root, selection)
                                .map { (root, state) -> CompiledResourceStatus(root = root, state = state) },
                    )
                }
            }
        }
}
