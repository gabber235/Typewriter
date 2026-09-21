package com.typewritermc.realm.routes

import com.typewritermc.realm.compiler.CompiledContentRepository
import com.typewritermc.realm.compiler.CompiledResourceState
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.ResourceId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.library.v1.authoring.QueryCompiledResourceStatusResponse
import skirout.library.v1.authoring.CompiledResourceState as WireState
import skirout.library.v1.authoring.CompiledResourceStatus as WireStatus

internal class CompiledResourceStatusRoutes(
    private val repository: CompiledContentRepository,
    private val contracts: LibraryContracts,
    private val generation: () -> String,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.queryCompiledResourceStatus) { call ->
                val actualGeneration = generation()
                if (call.request.generation.value != actualGeneration) {
                    QueryCompiledResourceStatusResponse.createCatalogChanged(
                        actualGeneration = CatalogGeneration(value = actualGeneration),
                    )
                } else {
                    val resources = call.request.resources.map { ResourceId(it.value) }
                    QueryCompiledResourceStatusResponse.createSuccess(
                        statuses =
                            repository.resourceStatuses(resources).map { status ->
                                WireStatus(
                                    resource = status.resource.toWire(),
                                    state =
                                        when (val state = status.state) {
                                            CompiledResourceState.NotCompiled -> {
                                                WireState.NOT_COMPILED
                                            }

                                            is CompiledResourceState.Active -> {
                                                WireState.createActive(manifestId = state.manifestId)
                                            }

                                            is CompiledResourceState.Blocked -> {
                                                WireState.createBlocked(
                                                    lastActiveManifestId = state.lastActiveManifestId,
                                                    diagnosticCount = state.diagnosticCount,
                                                )
                                            }
                                        },
                                )
                            },
                    )
                }
            }
        }
}
