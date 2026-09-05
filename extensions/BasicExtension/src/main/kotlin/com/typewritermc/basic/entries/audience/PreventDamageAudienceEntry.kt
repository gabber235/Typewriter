package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.entity.EntityDamageEvent

@Entry("prevent_damage_audience", "Make players immune to all damage", Colors.GREEN, "mdi:shield-check")
/**
 * The `Prevent Damage Audience` makes the players in the audience immune to every source of damage:
 * falling, mobs, fire, drowning and other players alike. The damage never lands, so there is no hurt
 * animation and no knockback.
 *
 * To let the damage land and restore the health afterwards, which keeps the animation and the
 * knockback, use `Lock Health` instead.
 *
 * ## How could this be used?
 * Put it under an `In Region` audience to make a hub a true safe zone, or wrap a cinematic so a
 * stray skeleton cannot kill a player mid scene.
 */
class PreventDamageAudienceEntry(
    override val id: String = "",
    override val name: String = "",
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = PreventDamageAudienceDisplay()
}

class PreventDamageAudienceDisplay : AudienceDisplay() {
    override fun onPlayerAdd(player: Player) {}
    override fun onPlayerRemove(player: Player) {}

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onDamage(event: EntityDamageEvent) {
        val player = event.entity as? Player ?: return
        if (player !in this) return
        event.isCancelled = true
    }
}
