package com.typewritermc.realm.routes

import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.compiler.CompilationStatusSelection
import com.typewritermc.realm.compiler.CompiledRootStatuses
import com.typewritermc.realm.compiler.RegisteredCompiledState
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.ResourceId
import skirout.editor.v1.compiled_content.CompiledResourceState
import skirout.editor.v1.compiled_content.CompiledResourceStatus
import skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse
import skirout.editor.v1.type_catalog.PublicationId
import skirout.editor.v1.compilation_root.CompilationProjectionId as SkirCompilationProjectionId
import skirout.editor.v1.compilation_root.CompilationRoot as SkirCompilationRoot
import skirout.editor.v1.compiled_content.CompilationStatusSelection as SkirCompilationStatusSelection
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId

/** Reports roots present in the Realm selected publication; it does not inspect engine application state. */
internal class EditorCompiledResourceStatusRoutes(
    private val views: AuthoringViewStore,
    private val statuses: CompiledRootStatuses,
    private val contracts: EditorContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.queryCompiledResourceStatus) { call ->
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
                                .map { (root, state) -> state.toWire(root) },
                    )
                }
            }
        }
}

private fun SkirCompilationRoot.toDomain() =
    CompilationRoot(
        projection = CompilationProjectionId(projection.value),
        resource = ResourceId(resource.value),
    )

private fun RegisteredCompiledState.toWire(root: CompilationRoot) =
    CompiledResourceStatus(
        root =
            SkirCompilationRoot(
                projection =
                    SkirCompilationProjectionId(value = root.projection.value),
                resource =
                    SkirResourceId(value = root.resource.value),
            ),
        state =
            when (this) {
                RegisteredCompiledState.NotCompiled -> {
                    CompiledResourceState.NOT_COMPILED
                }

                is RegisteredCompiledState.Active -> {
                    CompiledResourceState.ActiveWrapper(
                        PublicationId(value = publication.value),
                    )
                }
            },
    )
