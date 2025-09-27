package com.typewritermc.core.interaction

import com.typewritermc.core.utils.tryCatchSuspend
import java.time.Duration
import java.util.*
import java.util.concurrent.ConcurrentHashMap

class InteractionScope(
    var interaction: Interaction,
    var bound: InteractionBound = InteractionBound.Empty,
) {
    private val interactionBoundStateOverrides = ConcurrentHashMap<UUID, InteractionBoundStateOverride>()
    private var previousBoundState = boundState

    val boundState: InteractionBoundState
        get() {
            val override = interactionBoundStateOverrides.values.maxByOrNull { it.priority }
            if (override != null) {
                return override.state
            }

            return if (interaction.priority > bound.priority) {
                InteractionBoundState.BLOCKING
            } else {
                InteractionBoundState.INTERRUPTING
            }
        }

    suspend fun initialize() {
        interaction.initialize()
        bound.initialize()
    }

    suspend fun tick(deltaTime: Duration) {
        tryCatchSuspend { interaction.tick(deltaTime) }
        tryCatchSuspend { refreshBoundState() }
        tryCatchSuspend { bound.tick() }
    }

    private suspend fun refreshBoundState() {
        if (boundState != previousBoundState) {
            tryCatchSuspend { bound.boundStateChange(previousBoundState, boundState) }
            previousBoundState = boundState
        }
    }

    suspend fun swapInteraction(interaction: Interaction) {
        this.interaction.teardown()
        this.interaction = interaction
        interaction.initialize()
    }

    suspend fun swapBound(bound: InteractionBound) {
        val transition = try {
            this.bound.transitionTo(bound)
        } catch (e: Exception) {
            e.printStackTrace()
            true
        }
        if (!transition) {
            return
        }
        tryCatchSuspend { this.bound.teardown() }
        tryCatchSuspend { bound.transitionFrom(this.bound) }
        this.bound = bound
        tryCatchSuspend { bound.initialize() }
    }

    suspend fun teardown() {
        tryCatchSuspend { this.bound.teardown() }
        tryCatchSuspend { interaction.teardown() }
    }

    suspend fun addBoundStateOverride(
        id: UUID = UUID.randomUUID(),
        state: InteractionBoundState,
        priority: Int = 0
    ): UUID {
        interactionBoundStateOverrides[id] = InteractionBoundStateOverride(state, priority)
        refreshBoundState()
        return id
    }

    suspend fun removeBoundStateOverride(id: UUID): Boolean {
        val removed = interactionBoundStateOverrides.remove(id) != null
        refreshBoundState()
        return removed
    }
}

data class InteractionBoundStateOverride(
    val state: InteractionBoundState,
    val priority: Int,
)

data class InteractionBoundStateOverrideSubscription(
    val id: UUID = UUID.randomUUID(),
    val playerUUID: UUID,
)
