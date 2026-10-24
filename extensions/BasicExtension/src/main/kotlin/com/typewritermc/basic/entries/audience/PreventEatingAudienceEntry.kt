package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.player.PlayerItemConsumeEvent

@Entry("prevent_eating_audience", "Stop players from eating or drinking", Colors.GREEN, "mdi:food-off")
/**
 * The `Prevent Eating Audience` stops the players in the audience from consuming anything: food,
 * potions and milk alike. The item stays in their hand.
 *
 * ## How could this be used?
 * Put it under an `In Region` audience so nobody can eat inside a cursed swamp, or wrap it around a
 * boss fight so players cannot heal themselves out of trouble.
 */
class PreventEatingAudienceEntry(
    override val id: String = "",
    override val name: String = "",
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = PreventEatingAudienceDisplay()
}

class PreventEatingAudienceDisplay : AudienceDisplay() {
    override fun onPlayerAdd(player: Player) {}
    override fun onPlayerRemove(player: Player) {}

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onConsume(event: PlayerItemConsumeEvent) {
        if (event.player !in this) return
        event.isCancelled = true
    }
}
