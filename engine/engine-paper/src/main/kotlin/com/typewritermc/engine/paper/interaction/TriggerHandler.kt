package com.typewritermc.engine.paper.interaction

import com.typewritermc.core.interaction.Interaction
import com.typewritermc.core.interaction.InteractionBound
import com.typewritermc.engine.paper.entry.entries.Event
import com.typewritermc.engine.paper.entry.entries.InteractionEndTrigger

interface TriggerHandler {
    /**
     * Determines the order in which a handler will be triggered for a player
     *
     * Higher priorities get triggered before lower priorities
     */
    val priority: Int get() = 0
    suspend fun trigger(event: Event, currentInteraction: Interaction?): TriggerContinuation
}

class InteractionTriggerHandler : TriggerHandler {
    override suspend fun trigger(event: Event, currentInteraction: Interaction?): TriggerContinuation {
        if (InteractionEndTrigger in event) {
            return TriggerContinuation.EndInteraction
        }
        return TriggerContinuation.Nothing
    }
}

sealed interface TriggerContinuation {
    // Signals that the trigger is completed.
    data object Nothing : TriggerContinuation

    @Deprecated("Use Nothing instead", ReplaceWith("Nothing"), level = DeprecationLevel.ERROR)
    data object Done

    // Processes the event in the current tick.
    data class Append(val events: List<Event>) : TriggerContinuation {
        constructor(vararg events: Event) : this(events.toList())
    }

    data class StartInteraction(val interaction: Interaction) : TriggerContinuation
    data object KeepInteraction : TriggerContinuation
    data object EndInteraction : TriggerContinuation

    data class StartInteractionBound(val bound: InteractionBound) : TriggerContinuation
    data object EndInteractionBound : TriggerContinuation

    data class Multi(val continuations: List<TriggerContinuation>) : TriggerContinuation {
        constructor(vararg continuations: TriggerContinuation) : this(continuations.toList())
    }
}