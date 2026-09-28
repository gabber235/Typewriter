package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.region.flag.responsibleAttacker

@Entry("region_mob_damage_modifier", "Decide whether mobs may hurt players in a region", Colors.PURPLE, "mdi:shield-bug")
/**
 * Decides whether the players inside the region may be hurt by anything that is not another
 * player: mobs, but also falling anvils, dispenser arrows and every other entity that deals
 * damage with nobody behind it.
 *
 * The VICTIM's location decides, so a skeleton outside cannot shoot a player standing inside a
 * protected region.
 *
 * A player hurting a player is the PvP flag's business, and so is anything that player set in
 * motion: their TNT, their lingering potion, their pet. Damage with no entity behind it at all,
 * like falling or drowning, is the Player Damage flag's.
 *
 * ## How could this be used?
 *
 * Let players walk through a monster infested cave unharmed during a scripted escort, without
 * removing the mobs.
 */
class MobDamageModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether mobs may hurt the players inside the region.")
    @Default("false")
    override val allowed: Var<Boolean> = ConstVar(false),
) : AllowanceModifierEntry
