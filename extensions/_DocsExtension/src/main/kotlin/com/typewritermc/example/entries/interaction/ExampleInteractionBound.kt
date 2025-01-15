package com.typewritermc.example.entries.interaction

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.interaction.InteractionBound
import com.typewritermc.core.interaction.InteractionBound.Empty.priority
import com.typewritermc.core.interaction.InteractionBoundState
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entries.InteractionEndTrigger
import com.typewritermc.engine.paper.interaction.ListenerInteractionBound
import com.typewritermc.engine.paper.interaction.boundState
import org.bukkit.entity.Player
import org.bukkit.event.Cancellable
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.HandlerList
import org.bukkit.event.player.PlayerEvent

//<code-block:interaction_bound>
@Entry("example_bound", "An example interaction bound", Colors.MEDIUM_PURPLE, "mdi:square-rounded")
class ExampleBoundEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : InteractionBoundEntry {
    override fun build(player: Player): InteractionBound =
        ExampleBound(player, priority)
}

class ExampleBound(
    private val player: Player,
    override val priority: Int
) : ListenerInteractionBound {

    override suspend fun initialize() {
        super.initialize()
        // Setup initial state
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    private fun onPlayerAction(event: SomeCancellablePlayerEvent) {
        if (event.player.uniqueId != player.uniqueId) return

        if (boundConditionBroken()) {
            // For PlayerEvents, we have a handy method to handle the breaking
            handleEvent(event)

            // A manual version of the above
            when (event.player.boundState) {
                InteractionBoundState.BLOCKING -> event.isCancelled = true
                InteractionBoundState.INTERRUPTING -> InteractionEndTrigger.triggerFor(event.player, context())
                InteractionBoundState.IGNORING -> {}
            }
        }
    }

    private fun boundConditionBroken(): Boolean {
        // Check if the bound condition is broken
        return false
    }

    override suspend fun tick() {
        // Do something every tick
    }

    override suspend fun teardown() {
        // Cleanup any state
        super.teardown()
    }
}
//</code-block:interaction_bound>

class SomeCancellablePlayerEvent(player: Player) : PlayerEvent(player, true), Cancellable {
    override fun getHandlers(): HandlerList = HANDLER_LIST

    companion object {
        @JvmStatic
        val HANDLER_LIST = HandlerList()
    }

    override fun isCancelled(): Boolean = false
    override fun setCancelled(p0: Boolean) {}
}