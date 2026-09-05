package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.entity.FoodLevelChangeEvent

@Entry("prevent_hunger_loss_audience", "Stop players from losing hunger", Colors.GREEN, "mdi:food-drumstick-off")
/**
 * The `Prevent Hunger Loss Audience` holds the hunger bar of the players in the audience where it
 * is. They can still fill it by eating; it simply never drops.
 *
 * ## How could this be used?
 * Put it under an `In Region` audience so a safe hub never starves anyone, or wrap a long puzzle so
 * players are not interrupted by hunger halfway through.
 */
class PreventHungerLossAudienceEntry(
    override val id: String = "",
    override val name: String = "",
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = PreventHungerLossAudienceDisplay()
}

class PreventHungerLossAudienceDisplay : AudienceDisplay() {
    override fun onPlayerAdd(player: Player) {}
    override fun onPlayerRemove(player: Player) {}

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onFoodLevelChange(event: FoodLevelChangeEvent) {
        val player = event.entity as? Player ?: return
        if (player !in this) return
        if (event.foodLevel >= player.foodLevel) return
        event.isCancelled = true
    }
}
