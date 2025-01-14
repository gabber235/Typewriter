package com.typewritermc.engine.paper.entry.temporal

import com.typewritermc.engine.paper.entry.entries.Event
import com.typewritermc.core.interaction.Interaction
import com.typewritermc.engine.paper.interaction.TriggerContinuation
import com.typewritermc.engine.paper.interaction.TriggerHandler

class TemporalHandler : TriggerHandler {
    override suspend fun trigger(event: Event, currentInteraction: Interaction?): TriggerContinuation {
        if (TemporalStopTrigger in event && currentInteraction is TemporalInteraction) {
            return TriggerContinuation.Multi(
                TriggerContinuation.EndInteraction,
                TriggerContinuation.Append(Event(event.player, currentInteraction.context, currentInteraction.eventTriggers)),
            )
        }

        val setFrameTriggers = event.triggers.filterIsInstance<TemporalSetFrameTrigger>().maxByOrNull { it.frame }
        if (setFrameTriggers != null && currentInteraction is TemporalInteraction) {
            currentInteraction.frame(setFrameTriggers.frame)
        }

        return tryStartTemporalInteraction(event)
    }

    private fun tryStartTemporalInteraction(event: Event): TriggerContinuation {
        val triggers = event.triggers.filterIsInstance<TemporalStartTrigger>()
        if (triggers.isEmpty()) return TriggerContinuation.Done

        val trigger = triggers.maxBy { it.priority }
        return TriggerContinuation.StartInteraction(
            TemporalInteraction(
                trigger.pageId,
                event.player,
                event.context,
                trigger.eventTriggers,
                trigger.settings
            )
        )
    }
}