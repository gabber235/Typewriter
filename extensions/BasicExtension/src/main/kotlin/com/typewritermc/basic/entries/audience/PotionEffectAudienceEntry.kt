package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.ThreadType
import lirand.api.extensions.server.server
import org.bukkit.entity.Player
import org.bukkit.potion.PotionEffect
import org.bukkit.potion.PotionEffectType
import java.util.*
import java.util.concurrent.ConcurrentHashMap

@Entry("potion_effect_audience", "Filters an audience based on the potion effect", Colors.GREEN, "ion:flask")
/**
 * The `PotionEffect Audience` entry filters an audience based on the potion effect.
 * When the player is in the audience, the potion effect will be applied to the player infinitely.
 * Then when the player leaves the audience, the potion effect will be removed from the player.
 *
 * ## How could this be used?
 * This could be used to give night vision when wearing goggles.
 * Blindness when you are in a spooky house.
 * Or speed when you hold a talisman.
 */
class PotionEffectAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    val potionEffect: PotionEffectType = PotionEffectType.SPEED,
    @Default("1")
    val strength: Var<Int> = ConstVar(1),
    val ambient: Boolean = false,
    val particles: Boolean = false,
    @Default("true")
    val icon: Boolean = true,
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay {
        return PotionEffectAudienceDisplay(potionEffect, strength, ambient, particles, icon)
    }
}

class PotionEffectAudienceDisplay(
    private val potionEffect: PotionEffectType,
    private val strength: Var<Int>,
    private val ambient: Boolean,
    private val particles: Boolean,
    private val icon: Boolean,
) : AudienceDisplay(), TickableDisplay {
    private val strengths = ConcurrentHashMap<UUID, Int>()
    override fun onPlayerAdd(player: Player) {
        val strength = strength.get(player).coerceAtLeast(1) - 1
        ThreadType.SYNC.launch {
            player.removePotionEffect(potionEffect)
            player.addPotionEffect(PotionEffect(potionEffect, PotionEffect.INFINITE_DURATION, strength, ambient, particles, icon))
        }
        strengths[player.uniqueId] = strength
    }

    override fun tick() {
        strengths.forEach { (playerId, strength) ->
            val player = server.getPlayer(playerId) ?: return@forEach
            val newStrength = this.strength.get(player).coerceAtLeast(1) - 1
            if (strength == newStrength) return@forEach
            ThreadType.SYNC.launch {
                player.removePotionEffect(potionEffect)
                player.addPotionEffect(potionEffect.createEffect(PotionEffect.INFINITE_DURATION, newStrength))
            }
            strengths[playerId] = newStrength
        }
    }

    override fun onPlayerRemove(player: Player) {
        strengths.remove(player.uniqueId)
        ThreadType.SYNC.launch {
            player.removePotionEffect(potionEffect)
        }
    }
}