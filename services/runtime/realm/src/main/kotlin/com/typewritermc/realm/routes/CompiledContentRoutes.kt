package com.typewritermc.realm.routes

import com.typewritermc.realm.compiler.CompiledContentRepository
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.library.v2.authoring.WatchCompiledContentResponse

internal class CompiledContentRoutes(
    private val content: CompiledContentRepository,
    private val contracts: LibraryContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            watch(contracts.watchCompiledContent) {
                WatchCompiledContentResponse.createInitial(activation = content.activeActivation()?.toSkir())
            }
        }
}
