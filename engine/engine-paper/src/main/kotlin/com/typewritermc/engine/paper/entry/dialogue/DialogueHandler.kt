package com.typewritermc.engine.paper.entry.dialogue

import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.priority
import com.typewritermc.core.interaction.Interaction
import com.typewritermc.engine.paper.entry.entries.DialogueEntry
import com.typewritermc.engine.paper.entry.entries.Event
import com.typewritermc.engine.paper.interaction.TriggerContinuation
import com.typewritermc.engine.paper.interaction.TriggerHandler

class DialogueHandler : TriggerHandler {
    override suspend fun trigger(event: Event, currentInteraction: Interaction?): TriggerContinuation {
        if (DialogueTrigger.NEXT_OR_COMPLETE in event) {
            if (currentInteraction.completeDialogue()) return TriggerContinuation.Nothing
            return currentInteraction.triggerNextDialogue(event)
        }
        if (DialogueTrigger.FORCE_NEXT in event) {
            return currentInteraction.triggerNextDialogue(event)
        }

        return currentInteraction.tryTriggerNextDialogue(event)
    }


    /**
     * Check if the dialogue is complete, and if not, complete it.
     * @return true if the dialogue got completed, false otherwise.
     */
    private fun Interaction?.completeDialogue(): Boolean {
        if (this !is DialogueInteraction) return true
        if (isCompleted) return false
        isCompleted = true
        return true
    }

    /**
     * Called when the player clicks the next button.
     * If there is no next dialogue, the interaction
     * will be ended.
     */
    private fun Interaction?.triggerNextDialogue(event: Event): TriggerContinuation {
        if (this !is DialogueInteraction) return TriggerContinuation.Nothing
        isActive = false

        val triggers = this.eventTriggers
        if (triggers.isEmpty()) {
            return TriggerContinuation.EndInteraction
        }
        return TriggerContinuation.Append(Event(event.player, event.context, triggers))
    }

    /**
     * Tries to trigger a new dialogue. If no dialogue can be found, it will end the dialogue
     * interaction.
     */
    private fun Interaction?.tryTriggerNextDialogue(event: Event): TriggerContinuation {
        val nextDialogue = Query.findWhere<DialogueEntry> { it in event }
            .sortedWith { a, b ->
                val priorityDiff = b.priority - a.priority
                if (priorityDiff != 0) return@sortedWith priorityDiff
                b.criteria.size - a.criteria.size
            }
            .firstOrNull()

        if (nextDialogue != null) {
            if (this !is DialogueInteraction) {
                return TriggerContinuation.StartInteraction(DialogueInteraction(event.player, event.context, nextDialogue))
            } else if (!isActive || nextDialogue.priority >= priority) {
                this.next(nextDialogue, event.context)
                return TriggerContinuation.KeepInteraction
            }
        } else if (this is DialogueInteraction && !isActive) {
            return TriggerContinuation.EndInteraction
        }
        return TriggerContinuation.Nothing
    }
}