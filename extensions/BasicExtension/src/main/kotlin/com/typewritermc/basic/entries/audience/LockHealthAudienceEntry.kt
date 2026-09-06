package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.TickableDisplay
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.utils.Sync
import kotlinx.coroutines.Dispatchers
import org.bukkit.attribute.Attribute
import org.bukkit.entity.Player

@Entry("lock_health_audience", "Hold the health of players at a set value", Colors.GREEN, "mdi:heart-pulse")
/**
 * The `Lock Health Audience` holds the health of the players in the audience at [health]. Damage
 * still lands, so the hurt animation, the sound and the knockback all play, and the health is put
 * back right after.
 *
 * To stop the damage from landing at all, use `Prevent Damage` instead.
 *
 * A value above the player's maximum health is clamped to it.
 *
 * ## How could this be used?
 * Keep a player on half a heart through a scripted duel they are meant to survive, or hold a boss
 * arena's challengers at a fixed health so the fight is about the mechanics, not the food they
 * brought.
 */
class LockHealthAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The health the players are held at. Two health is one heart.")
    @Default("20.0")
    val health: Var<Double> = ConstVar(20.0),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = LockHealthAudienceDisplay(health)
}

class LockHealthAudienceDisplay(
    private val health: Var<Double>,
) : AudienceDisplay(), TickableDisplay {
    override fun onPlayerAdd(player: Player) {}
    override fun onPlayerRemove(player: Player) {}

    // Reading the maximum health attribute and assigning health are both main thread work,
    // and TickableDisplay.tick runs off it.
    override fun tick() {
        if (players.isEmpty()) return
        Dispatchers.Sync.launch { applyHeldHealth() }
    }

    /** Applies the locked health to every audience player. Must run on the server main thread. */
    internal fun applyHeldHealth() {
        for (player in players) {
            val maximum = player.getAttribute(Attribute.MAX_HEALTH)?.value ?: DEFAULT_MAX_HEALTH
            val target = health.get(player).coerceIn(0.0, maximum)
            if (player.health == target) continue
            player.health = target
        }
    }

    companion object {
        private const val DEFAULT_MAX_HEALTH = 20.0
    }
}
