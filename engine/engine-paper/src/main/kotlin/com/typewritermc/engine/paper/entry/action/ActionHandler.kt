package com.typewritermc.engine.paper.entry.action

import com.typewritermc.core.interaction.Interaction
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.Event
import com.typewritermc.engine.paper.entry.entries.entries
import com.typewritermc.engine.paper.interaction.TriggerContinuation
import com.typewritermc.engine.paper.interaction.TriggerHandler

class ActionHandler : TriggerHandler {
    override val priority: Int
        get() = 10

    override suspend fun trigger(event: Event, currentInteraction: Interaction?): TriggerContinuation {
        val actions = event.entries<ActionEntry>()
        if (actions.isEmpty()) return TriggerContinuation.Nothing

        val events = actions.mapNotNull { action ->
            val trigger = ActionTrigger(event.player, event.context, action)
            with(action) {
                trigger.execute()
            }

            if (trigger.automaticModifiers) {
                trigger.applyModifiers()
            }

            trigger.executed = true
            val nextTriggers = trigger.eventTriggers.filter { it !in event } // Stops infinite loops
            if (nextTriggers.isEmpty()) return@mapNotNull null

            Event(event.player, trigger.context, nextTriggers)
        }

        if (events.isEmpty()) return TriggerContinuation.Nothing
        return TriggerContinuation.Append(events)
    }
}