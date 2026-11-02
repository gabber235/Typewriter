package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.region.flag.responsibleAttacker

@Entry("region_pvp_modifier", "Decide whether players may fight each other in a region", Colors.PURPLE, "mdi:sword-cross")
/**
 * Decides whether players may hurt each other inside the region.
 *
 * Whatever the attacker used counts as theirs: a fist, an arrow, TNT they primed, a lingering
 * potion they threw, or a pet they set on someone. Machinery counts even when the game records
 * no owner for it, so a TNT cannon fired by a lever is still PvP. Only damage nobody set in
 * motion falls to the Mob Damage and Player Damage flags.
 *
 * The VICTIM's location decides, so an attacker standing outside cannot shoot into a protected
 * region, and an arrow loosed from inside it still lands on someone outside.
 *
 * ## How could this be used?
 *
 * Make a hub a truce, and give the arena inside it a higher priority region that allows PvP again.
 */
class PvpModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether players may hurt each other inside the region.")
    @Default("false")
    override val allowed: Var<Boolean> = ConstVar(false),
) : AllowanceModifierEntry
