package com.typewritermc.engine.paper

/**
 * Gives Paper targeted activators lifecycle aware registration without exposing plugin ownership.
 *
 * Listener identifiers and command names must be unique within the active deployment. Each returned handle unregisters
 * exactly that resource and must be owned by the activation scope for replacement cleanup.
 */
interface PaperEngineGateway {
    fun registerListener(
        id: String,
        listener: suspend (Any) -> Unit,
    ): AutoCloseable

    fun registerCommand(
        name: String,
        command: suspend (List<String>) -> Unit,
    ): AutoCloseable
}
