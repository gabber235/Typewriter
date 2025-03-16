package com.typewritermc.example.entries.interaction

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.core.interaction.Interaction
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.Event
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.interaction.TriggerContinuation
import com.typewritermc.engine.paper.interaction.TriggerHandler
import org.bukkit.entity.Player
import java.time.Duration
import kotlin.random.Random

//<code-block:basic_interaction>
class ExampleInteraction(
    val player: Player,
    override val context: InteractionContext,
    override val priority: Int,
    val eventTriggers: List<EventTrigger>
) : Interaction {
    override suspend fun initialize(): Result<Unit> {
        if (Random.nextBoolean()) {
            // Failing during initialization makes it so that the interaction will be stopped.
            return failure("Failed to initialize")
        }

        // Setup your interaction state
        player.sendMessage("Starting interaction!")

        return ok(Unit)
    }

    override suspend fun tick(deltaTime: Duration) {
        // Update your interaction state
        if (shouldEnd()) {
            // Trigger the stop event when done
            ExampleStopTrigger.triggerFor(player, context)
        }
    }

    override suspend fun teardown(force: Boolean) {
        // Cleanup your interaction state
        player.sendMessage("Ending interaction!")
    }

    private fun shouldEnd(): Boolean = false // Your end condition
}
//</code-block:basic_interaction>

//<code-block:interaction_triggers>
// Trigger to start the interaction
data class ExampleStartTrigger(
    val priority: Int,
    val eventTriggers: List<EventTrigger> = emptyList()
) : EventTrigger {
    override val id: String = "example.start"
}

// Trigger to stop the interaction
data object ExampleStopTrigger : EventTrigger {
    override val id: String = "example.stop"
}
//</code-block:interaction_triggers>

//<code-block:interaction_trigger_handler>
@Singleton // This registers the handler to Typewriter
class ExampleTriggerHandler : TriggerHandler {
    override suspend fun trigger(event: Event, currentInteraction: Interaction?): TriggerContinuation {
        // Handle stopping the interaction
        if (ExampleStopTrigger in event && currentInteraction is ExampleInteraction) {
            return TriggerContinuation.Multi(
                TriggerContinuation.EndInteraction,
                TriggerContinuation.Append(Event(event.player, currentInteraction.context, currentInteraction.eventTriggers)),
            )
        }

        // Handle starting the interaction
        return tryStartExampleInteraction(event)
    }

    private fun tryStartExampleInteraction(
        event: Event
    ): TriggerContinuation {
        // Find all start triggers in the event
        val triggers = event.triggers
            .filterIsInstance<ExampleStartTrigger>()

        if (triggers.isEmpty()) return TriggerContinuation.Done

        // Use the highest priority trigger
        val trigger = triggers.maxBy { it.priority }

        // Start the interaction
        return TriggerContinuation.StartInteraction(
            ExampleInteraction(
                event.player,
                event.context,
                trigger.priority,
                trigger.eventTriggers
            )
        )
    }
}
//</code-block:interaction_trigger_handler>

//<code-block:interaction_entry>
@Entry("example_interaction", "Start an example interaction", Colors.RED, "mdi:play")
class ExampleInteractionActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : ActionEntry {
    // Preventing the `triggers` from being used, instead we pass them to the interaction
    // And also start the interaction when the entry is triggered.
    override val eventTriggers: List<EventTrigger>
        get() = listOf(
            ExampleStartTrigger(
                this.priority,
                super.eventTriggers
            )
        )

    override fun ActionTrigger.execute() {}
}
//</code-block:interaction_entry>