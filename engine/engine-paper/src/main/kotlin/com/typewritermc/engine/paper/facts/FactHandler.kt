package com.typewritermc.engine.paper.facts

import com.typewritermc.core.interaction.Interaction
import com.typewritermc.engine.paper.entry.entries.Event
import com.typewritermc.engine.paper.interaction.TriggerContinuation
import com.typewritermc.engine.paper.interaction.TriggerHandler

class FactHandler : TriggerHandler {
    override suspend fun trigger(event: Event, currentInteraction: Interaction?): TriggerContinuation {
        val triggers = event.triggers.filterIsInstance<RefreshFactTrigger>()
        if (triggers.isEmpty()) return TriggerContinuation.Nothing

        for (trigger in triggers) {
            event.player.factTracker?.refreshFact(trigger.fact)
        }
        return TriggerContinuation.Nothing
    }
}