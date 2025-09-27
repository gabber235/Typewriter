package com.typewritermc.core.interaction

interface InteractionBound {
    val priority: Int

    suspend fun initialize() {}
    suspend fun tick() {}
    suspend fun boundStateChange(previousBoundState: InteractionBoundState, newBoundState: InteractionBoundState) {}
    suspend fun teardown() {}

    /**
     * When the interaction bound wants to change, this will be called on the current bound.
     * If it returns false, the transition will be canceled and this stays the bound.
     */
    suspend fun transitionTo(bound: InteractionBound): Boolean = true

    /**
     * When the interaction bound has changed, this will be called before initialization on this new bound with the old bound
     * as a parameter.
     */
    suspend fun transitionFrom(bound: InteractionBound) {}

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