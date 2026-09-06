package com.typewritermc.realm.routes

import com.typewritermc.realm.compiler.CompiledContentRepository
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.library.v1.compiled_content.WatchCompiledContentResponse

/**
 * Provides the initial compiled activation for the watch protocol.
 *
 * Later notifications come from [CompiledContentEvents]. Initial state and events are separate observations, so
 * consumers use activation revisions to ignore stale delivery.
 */
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
