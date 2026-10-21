package com.typewritermc.realm.routes

import com.typewritermc.engine.toDomain
import com.typewritermc.engine.toSkir
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringCompiledStatusQuery
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.compiler.CompilationStatusSelection
import com.typewritermc.realm.compiler.CompiledRootStatuses
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.editor.v1.compiled_content.CompiledResourceStatus
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse
import skirout.editor.v1.compiled_content.CompilationStatusSelection as SkirCompilationStatusSelection

/** Reports roots present in the Realm selected publication; it does not inspect engine application state. */
internal class EditorCompiledResourceStatusRoutes(
    private val views: AuthoringViewStore,
    private val statuses: CompiledRootStatuses,
    private val address: RealmRouteScope,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(address.authoringCompiledStatusQuery) { call ->
                val selection =
                    when (val requested = call.request.selection) {
                        SkirCompilationStatusSelection.ALL_ROOTS -> {
                            CompilationStatusSelection.All
                        }

                        is SkirCompilationStatusSelection.SuppliedRootsWrapper -> {
                            CompilationStatusSelection.Supplied(requested.value.mapTo(linkedSetOf()) { root -> root.toDomain() })
                        }

                        is SkirCompilationStatusSelection.Unknown -> {
                            error("Unknown compilation status selection.")
                        }
                    }
                views.capture().use { capture ->
                    QueryCompiledResourceStatusResponse.createSuccess(
                        statuses =
                            statuses
                                .query(capture.root, selection)
                                .map { (root, state) -> CompiledResourceStatus(root = root.toSkir(), state = state) },
                    )
                }
            }
        }
}
