package com.typewritermc.core.interaction

interface InteractionBound {
    val priority: Int

    suspend fun initialize() {}
    suspend fun tick() {}
    suspend fun boundStateChange(previousBoundState: InteractionBoundState, newBoundState: InteractionBoundState) {}
    suspend fun teardown() {}

    object Empty : InteractionBound {
        override val priority: Int = Int.MIN_VALUE
        override suspend fun initialize() {}
        override suspend fun tick() {}
        override suspend fun teardown() {}
    }
}

enum class InteractionBoundState {
    BLOCKING,
    INTERRUPTING,
    IGNORING,
}