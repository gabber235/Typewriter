package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Sync
import kotlinx.coroutines.Dispatchers
import org.bukkit.potion.PotionEffectType

@Entry(
    "remove_potion_effect",
    "Remove a potion effect from the player",
    Colors.RED,
    "mdi:flask-empty-off"
)
/**
 * The `Remove Potion Effect Action` is an action that removes a potion effect from the player.
 *
 * ## How could this be used?
 *
 * This action can be useful in a variety of situations. You can use it to remove buffs or debuffs from players, such as speed or slowness, or to create custom effects.
 */
class RemovePotionEffectActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val potionEffect: Var<PotionEffectType> = ConstVar(PotionEffectType.SPEED),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        Dispatchers.Sync.launch {
            player.removePotionEffect(potionEffect.get(player, context))
        }
    }
}