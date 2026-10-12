package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import org.bukkit.event.entity.EntityDamageEvent

@Entry("region_player_damage_modifier", "Decide whether players may be hurt at all in a region", Colors.PURPLE, "mdi:shield-check")
/**
 * Decides whether the players inside the region may be hurt by anything at all: falling, drowning,
 * fire, mobs and other players alike.
 *
 * It covers every cause at once. To allow mobs but not other players, use the PvP and mob damage
 * flags instead.
 *
 * ## How could this be used?
 *
 * Make a hub a true safe zone where nothing can kill anyone, however hard they try.
 */
class PlayerDamageModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether the players inside the region may be hurt by anything.")
    @Default("false")
    override val allowed: Var<Boolean> = ConstVar(false),
    @Help("The damage causes this decides about. Leave it empty to decide about every cause.")
    val causes: List<EntityDamageEvent.DamageCause> = emptyList(),
) : AllowanceModifierEntry {
    /** Whether this flag has anything to say about damage of this [cause]. */
    fun decidesAbout(cause: EntityDamageEvent.DamageCause): Boolean =
        causes.isEmpty() || cause in causes
}
