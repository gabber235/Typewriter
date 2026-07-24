package com.typewritermc.engine.paper.content

/**
 * The window a set slot packet targets to write straight into the player's inventory,
 * bypassing whatever container is currently open.
 */
const val PLAYER_INVENTORY_WINDOW_ID = -2

/**
 * Translates a slot index as used by creative inventory actions into the index the same
 * item has in [org.bukkit.inventory.PlayerInventory].
 *
 * Creative actions count slots in the player inventory container, where the hotbar sits at
 * the end and the armor slots run from helmet to boots. The Bukkit inventory counts the
 * hotbar first and the armor the other way around, so the two never line up.
 *
 * @return the matching inventory slot, or `null` for slots with no inventory equivalent
 * such as the crafting grid, the drop sentinel, or anything out of range
 */
fun creativeSlotToInventorySlot(creativeSlot: Int): Int? = when (creativeSlot) {
    in 36..44 -> creativeSlot - 36
    in 9..35 -> creativeSlot
    in 5..8 -> 44 - creativeSlot
    45 -> 40
    else -> null
}
