package com.typewritermc.engine.paper.content

import com.typewritermc.engine.paper.entry.entries.Event
import com.typewritermc.core.interaction.Interaction
import com.typewritermc.engine.paper.interaction.TriggerContinuation
import com.typewritermc.engine.paper.interaction.TriggerHandler
import com.typewritermc.engine.paper.logger

class ContentHandler : TriggerHandler {
    override suspend fun trigger(event: Event, currentInteraction: Interaction?): TriggerContinuation {
        if (ContentPopTrigger in event && currentInteraction is ContentInteraction) {
            if (!currentInteraction.popMode()) return TriggerContinuation.EndInteraction
        }

        val trigger =
            event.triggers.filterIsInstance<ContentModeTrigger>().firstOrNull() ?: return TriggerContinuation.Done

        if (currentInteraction !is ContentInteraction) {
            return TriggerContinuation.StartInteraction(
                ContentInteraction(
                    trigger.context,
                    event.player,
                    trigger.mode,
                    event.context
                )
            )
        }

        val result = if (trigger is ContentModeSwapTrigger) {
            currentInteraction.swapMode(trigger.mode)
        } else {
            currentInteraction.pushMode(trigger.mode)
        }
        return if (result.isFailure) {
            logger.warning("Failed to change content mode: ${result.exceptionOrNull()?.message}")
            TriggerContinuation.EndInteraction
        } else {
            TriggerContinuation.KeepInteraction
        }
    }
}