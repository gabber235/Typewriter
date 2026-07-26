package com.typewritermc.basic.entries.audience

import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

/** The last slot of the storage rows, the bottom right of the inventory screen. */
private const val LAST_STORAGE_SLOT = 35

/**
 * What to do when a player has to be given a quest item and every slot is taken.
 *
 * A quest item is free to sit wherever the player puts it, so none of these name a slot to give up. Whichever
 * one is taken comes from the hotbar or the storage rows, as those are the only slots an item is given into.
 */
enum class InventoryFullStrategy {
    /** Wait for the player to make room themselves, and ask them to in the meantime. */
    WAIT_FOR_SPACE,

    /** Drop whatever is in the way on the floor. */
    DROP,

    /** Take whatever is in the way, and give it back as soon as the player has room for it again. */
    REPLACE;

    /** Frees a slot for the quest item, or null when the player has to make room themselves. */
    fun makeRoom(player: Player): FreedSlot? {
        if (this == WAIT_FOR_SPACE) return null
        val slot = player.slotToGiveUp() ?: return null
        val occupant = player.inventory.getItem(slot)
        player.inventory.setItem(slot, null)
        if (this == REPLACE) return FreedSlot(slot, occupant)
        occupant?.let { player.world.dropItemNaturally(player.location, it) }
        return FreedSlot(slot, null)
    }
}

/** A slot the quest item may take, and the item that has to go back to the player, if any. */
class FreedSlot(val slot: Int, val restore: ItemStack?)

/**
 * The slot to take, counting back from the end of the storage rows so that the hotbar is the last to go.
 *
 * Armor and the offhand are not in here, and taking one would be no help if they were: an item is handed out
 * with [org.bukkit.inventory.Inventory.addItem], which only ever fills the storage rows and the hotbar. It
 * would take the player's armor off for nothing. Wearing the quest item is a separate matter and is allowed.
 *
 * Null when every slot holds a quest item, as taking one of those to make room for another gets nowhere.
 */
private fun Player.slotToGiveUp(): Int? =
    (LAST_STORAGE_SLOT downTo 0).firstOrNull { !inventory.getItem(it).isQuestItem }
