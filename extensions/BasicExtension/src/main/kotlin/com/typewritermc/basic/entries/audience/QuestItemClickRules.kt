package com.typewritermc.basic.entries.audience

import org.bukkit.event.inventory.InventoryAction
import org.bukkit.event.inventory.InventoryAction.*

/**
 * Whether a click would take a quest item out of the player's own inventory, and so has to be cancelled.
 *
 * A quest item may go anywhere in the player's own inventory and nowhere else. Every container in the game
 * takes items through this one event, so that single rule covers all of them. Pickups stay allowed, so a copy
 * that leaked into a container can still be taken back out. A bundle that arrived with a quest item in it
 * counts as the quest item throughout, or it would carry one into a container on the item's behalf.
 *
 * @param inOwnInventory whether the clicked slot is one of the player's own. The armor slots and the offhand
 * are among those, so a quest item that is armor can be worn and any quest item can be held in the offhand.
 * @param ownScreen whether the open screen is the player's own, whose top inventory is the 2x2 crafting grid.
 * Shift clicking moves between the hotbar and the storage rows there, and into the container otherwise.
 * @param swapInIsQuestItem whether the item a swap brings in is a quest item: the offhand for an offhand
 * swap, and otherwise the hotbar slot the number key points at.
 */
internal fun clickEscapesInventory(
    action: InventoryAction,
    inOwnInventory: Boolean,
    ownScreen: Boolean,
    slotIsQuestItem: Boolean,
    cursorIsQuestItem: Boolean,
    swapInIsQuestItem: Boolean,
): Boolean = when (action) {
    DROP_ALL_SLOT, DROP_ONE_SLOT -> slotIsQuestItem
    DROP_ALL_CURSOR, DROP_ONE_CURSOR -> cursorIsQuestItem
    PICKUP_ALL_INTO_BUNDLE, PICKUP_SOME_INTO_BUNDLE -> slotIsQuestItem
    PLACE_ALL_INTO_BUNDLE, PLACE_SOME_INTO_BUNDLE -> cursorIsQuestItem
    PLACE_FROM_BUNDLE -> cursorIsQuestItem && !inOwnInventory
    CLONE_STACK -> slotIsQuestItem
    MOVE_TO_OTHER_INVENTORY -> slotIsQuestItem && inOwnInventory && !ownScreen
    HOTBAR_SWAP -> swapInIsQuestItem && !inOwnInventory
    PLACE_ALL, PLACE_SOME, PLACE_ONE, SWAP_WITH_CURSOR -> cursorIsQuestItem && !inOwnInventory
    else -> false
}
