package com.typewritermc.basic.entries.audience

import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.item.Item
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import org.bukkit.inventory.PlayerInventory
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.time.Clock
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

private val WARNING_INTERVAL = 10.seconds

private val inventoryFullMessage by snippet(
    "quest_item.inventory_full",
    "<gray>Make room in your inventory, you are missing a quest item."
)

/**
 * Keeps a player holding what the entry asks for: the right amount of the right item, and no quest items
 * they have no business with.
 *
 * Everything here writes to an inventory, so call it on the main thread.
 */
internal class QuestItemStock(
    private val ref: Ref<QuestItemAudienceEntry>,
    private val item: Var<Item>,
    private val inventoryFull: InventoryFullStrategy,
) {
    private val replacedItems = ConcurrentHashMap<UUID, MutableList<ItemStack>>()
    private val nextWarnings = ConcurrentHashMap<UUID, Instant>()
    private var warnedAboutEmptyItem = false

    /**
     * Brings the inventory back in line with the entry.
     *
     * Handing the item over for the first time is the same work as correcting it later, so both go through
     * here.
     */
    fun reconcile(player: Player) {
        unbundle(player) { it.isQuestItemOf(ref) || it.isStaleQuestItem(player) }
        clearStaleQuestItems(player)
        settle(player, buildItem(player))
        restoreReplaced(player)
    }

    /**
     * Brings what the player carries in line with [required], which is null when the entry asks for nothing.
     *
     * An item that turns empty is taken back rather than left behind, as a `Var<Item>` can answer with
     * nothing for a player it answered with something for a moment ago.
     */
    private fun settle(player: Player, required: ItemStack?) {
        val carried = countCarried(player)
        if (required == null) {
            trim(player, carried)
            return
        }

        when {
            carried < required.amount -> handOut(player, required.withAmount(required.amount - carried))
            carried > required.amount -> trim(player, carried - required.amount)
            else -> refresh(player, required)
        }
    }

    /**
     * Puts [stack] in the player's inventory, making room for it the way the entry asks for if there is none.
     *
     * The stack goes back as it is, so a quest item has to be tagged before it gets here.
     */
    fun handOut(player: Player, stack: ItemStack) {
        val leftOver = player.inventory.addItem(stack).values.firstOrNull() ?: return

        val freed = inventoryFull.makeRoom(player)
        if (freed == null) {
            warnInventoryFull(player)
            return
        }

        freed.restore?.let { keepUntilThereIsRoom(player, it) }
        player.inventory.setItem(freed.slot, leftOver)
    }

    /** Takes the item back, and hands over whatever a replacement was still holding on to. */
    fun takeBack(player: Player) {
        unbundle(player) { it.isQuestItemOf(ref) }
        val inventory = player.inventory
        for (slot in 0 until inventory.size) {
            if (inventory.getItem(slot).isQuestItemOf(ref)) inventory.setItem(slot, null)
        }
        if (player.itemOnCursor.isQuestItemOf(ref)) player.setItemOnCursor(null)

        nextWarnings.remove(player.uniqueId)
        val replaced = replacedItems.remove(player.uniqueId) ?: return
        replaced.forEach { player.giveOrDrop(it) }
    }

    /** How much of the entry's item the player has, counting what they are holding on the cursor. */
    private fun countCarried(player: Player): Int {
        val inventory = player.inventory
        val inSlots = (0 until inventory.size)
            .mapNotNull { inventory.getItem(it) }
            .filter { it.belongsTo(player) }
            .sumOf { it.amount }
        val onCursor = if (player.itemOnCursor.belongsTo(player)) player.itemOnCursor.amount else 0
        return inSlots + onCursor
    }

    /**
     * Clears the quest items the player has no business holding: another player's, or one belonging to an
     * audience that is not around any more to ask for it back.
     */
    private fun clearStaleQuestItems(player: Player) {
        val inventory = player.inventory
        for (slot in 0 until inventory.size) {
            val stack = inventory.getItem(slot) ?: continue
            if (stack.belongsTo(player)) continue
            if (stack.isStaleQuestItem(player)) inventory.setItem(slot, null)
        }

        val cursor = player.itemOnCursor
        if (cursor.belongsTo(player)) return
        if (cursor.isStaleQuestItem(player)) player.setItemOnCursor(null)
    }

    /**
     * Takes the stacks [matches] answers for out of every bundle the player carries.
     *
     * A bundle keeps what it holds out of a count of the inventory and takes it along wherever it goes, so a
     * quest item that turns up in one is taken out of it. Nothing is allowed to put one in, but a bundle can
     * arrive with one already inside. Ours is handed out again in the open by the rest of the pass this is
     * part of, and a stale one is gone, which is what would have become of it in a slot of its own.
     */
    private fun unbundle(player: Player, matches: (ItemStack) -> Boolean) {
        val inventory = player.inventory
        for (slot in 0 until inventory.size) {
            val stack = inventory.getItem(slot) ?: continue
            if (stack.removeBundled(matches)) inventory.setItem(slot, stack)
        }

        val cursor = player.itemOnCursor
        if (cursor.removeBundled(matches)) player.setItemOnCursor(cursor)
    }

    /**
     * Removes the excess, taking the copy the player is least likely to have meant to keep.
     *
     * That is the back of the storage rows first and the hotbar after it, then what they wear or hold in the
     * offhand. A quest item that is armor can be worn, and taking it off their head before a spare copy sat
     * in the backpack is not what anyone means.
     */
    private fun trim(player: Player, excess: Int) {
        var left = excess
        val inventory = player.inventory

        for (slot in inventory.trimOrder()) {
            if (left <= 0) return
            if (!inventory.getItem(slot).isQuestItemOf(ref)) continue
            left -= inventory.takeFromSlot(slot, left)
        }

        trimCursor(player, left)
    }

    /**
     * Empties the cursor last of all, as it is not a slot and it is the copy the player is holding.
     *
     * It counts towards what they carry, so leaving it out of a trim would have the next pass hand them a
     * replacement for an item still in their hand.
     */
    private fun trimCursor(player: Player, excess: Int) {
        if (excess <= 0) return
        val cursor = player.itemOnCursor
        if (!cursor.isQuestItemOf(ref)) return
        if (excess >= cursor.amount) player.setItemOnCursor(null)
        else player.setItemOnCursor(cursor.withAmount(cursor.amount - excess))
    }

    /** Rewrites the stacks when the item changed, keeping each one in the slot the player left it in. */
    private fun refresh(player: Player, fresh: ItemStack) {
        if (item is ConstVar) return
        val inventory = player.inventory
        for (slot in 0 until inventory.size) {
            val stack = inventory.getItem(slot) ?: continue
            if (!stack.isQuestItemOf(ref)) continue
            val updated = fresh.withAmount(stack.amount)
            if (stack == updated) continue
            inventory.setItem(slot, updated)
        }
    }

    private fun keepUntilThereIsRoom(player: Player, item: ItemStack) {
        replacedItems.getOrPut(player.uniqueId) { mutableListOf() } += item
    }

    /**
     * Hands back what a replacement took, as soon as the player has room for it.
     *
     * This runs after the quest item is settled, so room that opens up goes to the quest item first and to
     * what made way for it after. A player who empties the slot the quest item went into gets their own item
     * straight back into it, rather than having to wait out the audience for it.
     */
    private fun restoreReplaced(player: Player) {
        val replaced = replacedItems[player.uniqueId] ?: return
        while (replaced.isNotEmpty()) {
            val leftOver = player.inventory.addItem(replaced.removeAt(0)).values.firstOrNull()
            if (leftOver != null) {
                replaced.add(0, leftOver)
                return
            }
        }
        replacedItems.remove(player.uniqueId)
    }

    private fun buildItem(player: Player): ItemStack? {
        val stack = item.get(player).build(player)
        if (stack.isEmpty) {
            warnAboutEmptyItem()
            return null
        }
        stack.tagAsQuestItem(ref, player)
        return stack
    }

    /** Whether the stack is this entry's item and was given to this player rather than to somebody else. */
    private fun ItemStack?.belongsTo(player: Player): Boolean =
        isQuestItemOf(ref) && questItemOwner == player.uniqueId

    private fun warnAboutEmptyItem() {
        if (warnedAboutEmptyItem) return
        warnedAboutEmptyItem = true
        logger.warning("The quest item audience $ref has no item set, so its players are given nothing.")
    }

    private fun warnInventoryFull(player: Player) {
        val now = Clock.System.now()
        val nextWarning = nextWarnings[player.uniqueId]
        if (nextWarning != null && now < nextWarning) return
        nextWarnings[player.uniqueId] = now + WARNING_INTERVAL
        player.sendMessage(inventoryFullMessage.parsePlaceholders(player).asMini())
    }
}

private fun ItemStack.withAmount(amount: Int): ItemStack = clone().apply { this.amount = amount }

private fun Player.giveOrDrop(item: ItemStack) {
    inventory.addItem(item).values.forEach { world.dropItemNaturally(location, it) }
}

/** Takes up to [wanted] off the stack in [slot], and answers with how much of it it took. */
private fun PlayerInventory.takeFromSlot(slot: Int, wanted: Int): Int {
    val stack = getItem(slot) ?: return 0
    val taken = minOf(wanted, stack.amount)
    if (taken == stack.amount) setItem(slot, null)
    else setItem(slot, stack.withAmount(stack.amount - taken))
    return taken
}

/**
 * Every slot, the storage rows and hotbar first and the armor slots and the offhand after them, each counting
 * back from its own end.
 *
 * The two halves come from the inventory itself rather than from written down slot numbers, so between them
 * they name every slot exactly once whatever the size turns out to be.
 */
private fun PlayerInventory.trimOrder(): List<Int> {
    val stored = storageContents.size
    return (stored - 1 downTo 0) + (size - 1 downTo stored)
}
