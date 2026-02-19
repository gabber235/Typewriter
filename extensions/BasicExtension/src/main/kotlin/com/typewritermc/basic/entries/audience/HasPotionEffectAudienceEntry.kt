package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.CriteriaOperator
import com.typewritermc.engine.paper.entry.entries.*
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.entity.EntityPotionEffectEvent
import org.bukkit.potion.PotionEffect
import org.bukkit.potion.PotionEffectType
import java.util.*

@Entry(
    "has_potion_effect_audience",
    "Filters an audience based on if they have a specific potion effect",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:flask"
)
/**
 * The `Has Potion Effect Audience` entry filters an audience based on if they have a specific potion effect.
 *
 * ## How could this be used?
 * This could show a sidebar while the player has a specific potion effect active.
 */
class HasPotionEffectAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    val potionEffect: PotionEffectType = PotionEffectType.SPEED,
    val strength: Optional<PotionEffectLevelCriteria> = Optional.empty(),
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter = HasPotionEffectAudienceFilter(ref(), potionEffect, strength)
}

data class PotionEffectLevelCriteria(
    val operator: CriteriaOperator = CriteriaOperator.GREATER_THAN_OR_EQUAL,
    val level: Var<Int> = ConstVar(1),
)

class HasPotionEffectAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    private val potionEffect: PotionEffectType,
    private val strength: Optional<PotionEffectLevelCriteria>,
) : AudienceFilter(ref) {
    override fun filter(player: Player): Boolean {
        return matches(player, player.getPotionEffect(potionEffect))
    }

    private fun matches(player: Player, effect: PotionEffect?): Boolean {
        effect ?: return false
        val currentLevel = effect.amplifier + 1

        return strength.map { criteria ->
            val expectedLevel = criteria.level.get(player)
            criteria.operator.isValid(currentLevel, expectedLevel)
        }.orElse(true)
    }

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    fun onPotionEffectChange(event: EntityPotionEffectEvent) {
        val player = event.entity as? Player ?: return
        if (!canConsider(player)) return
        if (event.modifiedType != potionEffect) return

        val effectAfterChange = when (event.action) {
            EntityPotionEffectEvent.Action.ADDED -> event.newEffect
            EntityPotionEffectEvent.Action.CHANGED -> if (event.isOverride) event.newEffect else event.oldEffect
            EntityPotionEffectEvent.Action.REMOVED -> null
            EntityPotionEffectEvent.Action.CLEARED -> null
        }

        player.updateFilter(matches(player, effectAfterChange))
    }
}
