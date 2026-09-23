package com.typewritermc.realm.routes

import com.typewritermc.engine.CompilationRoot
import com.typewritermc.realm.compiler.RegisteredCompiledContentRepository
import com.typewritermc.realm.compiler.RegisteredCompiledState
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder

/** Returns all requested compiled root states through one repository snapshot query. */
internal class EditorCompiledResourceStatusRoutes(
    private val repository: RegisteredCompiledContentRepository,
    private val contracts: EditorContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.queryCompiledResourceStatus) { call ->
                val roots =
                    call.request.roots
                        .map { root -> root.toDomain() }
                        .toSet()
                skirout.editor.v1.compiled_content.QueryCompiledResourceStatusResponse.createSuccess(
                    statuses = repository.states(roots).map { (root, state) -> state.toWire(root) },
                )
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
                    skirout.editor.v1.compiled_content.CompiledResourceState.createActive(
                        manifestId = manifestId,
                    )
                }

                is RegisteredCompiledState.Blocked -> {
                    skirout.editor.v1.compiled_content.CompiledResourceState.createBlocked(
                        lastActiveManifestId = lastActiveManifestId,
                        diagnosticCount = diagnosticCount,
                    )
                }
            },
    )
