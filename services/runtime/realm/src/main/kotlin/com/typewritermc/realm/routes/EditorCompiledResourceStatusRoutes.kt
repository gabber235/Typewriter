package com.typewritermc.realm.routes

import com.typewritermc.engine.CompilationRoot
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.compiler.CompilationStatusSelection
import com.typewritermc.realm.compiler.CompiledRootStatuses
import com.typewritermc.realm.compiler.RegisteredCompiledState
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder

/** Returns all requested compiled root states through one repository snapshot query. */
internal class EditorCompiledResourceStatusRoutes(
    private val snapshots: AuthoringViewStore,
    private val statuses: CompiledRootStatuses,
    private val contracts: EditorContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.queryCompiledResourceStatus) { call ->
                val selection =
                    when (val requested = call.request.selection) {
                        skirout.editor.v1.compiled_content.CompilationStatusSelection.ALL_ROOTS -> {
                            CompilationStatusSelection.All
                        }

                        is skirout.editor.v1.compiled_content.CompilationStatusSelection.SuppliedRootsWrapper -> {
                            CompilationStatusSelection.Supplied(requested.value.mapTo(linkedSetOf()) { root -> root.toDomain() })
                        }

                        is skirout.editor.v1.compiled_content.CompilationStatusSelection.Unknown -> {
                            error("Unknown compilation status selection.")
                        }
                    }
                snapshots.capture().use { capture ->
                    skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse.createSuccess(
                        statuses =
                            statuses
                                .query(capture.root, selection)
                                .map { (root, state) -> state.toWire(root) },
                    )
                }
            }
        }
}

private fun skirout.editor.v1.compiled_content.CompilationRoot.toDomain() =
    CompilationRoot(
        projection = com.typewritermc.engine.CompilationProjectionId(projection.value),
        resource = com.typewritermc.types.ResourceId(resource.value),
    )

private fun RegisteredCompiledState.toWire(root: CompilationRoot) =
    skirout.editor.v1.compiled_content.CompiledResourceStatus(
        root =
            skirout.editor.v1.compiled_content.CompilationRoot(
                projection =
                    skirout.editor.v1.compiled_content
                        .CompilationProjectionId(value = root.projection.value),
                resource =
                    skirout.editor.v1.type_catalog
                        .ResourceId(value = root.resource.value),
            ),
        state =
            when (this) {
                RegisteredCompiledState.NotCompiled -> {
                    skirout.editor.v1.compiled_content.CompiledResourceState.NOT_COMPILED
                }

                is RegisteredCompiledState.Active -> {
                    skirout.editor.v1.compiled_content.CompiledResourceState.ActiveWrapper(
                        skirout.editor.v1.type_catalog
                            .PublicationId(value = publication.value),
                    )
                }
            },
    )
