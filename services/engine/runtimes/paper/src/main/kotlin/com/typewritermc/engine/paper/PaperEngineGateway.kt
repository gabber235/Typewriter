package com.typewritermc.engine.paper

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
