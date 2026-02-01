package com.typewritermc.basic.entries.audience

import com.github.shynixn.mccoroutine.bukkit.ticks
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.entry.AudienceManager
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.engine.paper.utils.server
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import lirand.api.extensions.events.unregister
import org.bukkit.NamespacedKey
import org.bukkit.entity.ArmorStand
import org.bukkit.entity.ItemFrame
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.block.BlockPlaceEvent
import org.bukkit.event.entity.PlayerDeathEvent
import org.bukkit.event.inventory.InventoryClickEvent
import org.bukkit.event.inventory.InventoryCloseEvent
import org.bukkit.event.inventory.InventoryDragEvent
import org.bukkit.event.inventory.InventoryType
import org.bukkit.event.player.PlayerDropItemEvent
import org.bukkit.event.player.PlayerInteractAtEntityEvent
import org.bukkit.event.player.PlayerInteractEntityEvent
import org.bukkit.inventory.EquipmentSlot
import org.bukkit.inventory.ItemStack
import org.bukkit.persistence.PersistentDataType
import org.koin.java.KoinJavaComponent.get

private val inventoryFullMessage by snippet(
    "quest_item.inventory_full",
    "<yellow>Your inventory was full! An item has been dropped to make room for the quest item."
)

@Entry(
    "quest_item_audience",
    "Forces players to keep a quest item in their inventory",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:treasure-chest"
)
/**
 * The `Quest Item Audience` entry forces players in the audience to keep a specific item in their inventory.
 * 
 * This is the simplified version that gives the item when the player joins the audience and removes it when they leave.
 * 
 * The item can be moved freely within the player's inventory but cannot be:
 * - Dropped manually
 * - Moved to containers (chests, shulker boxes, etc.)
 * - Placed in crafting slots
 * - Lost on death
 * 
 * ## How could this be used?
 * Force the player to carry a quest item, such as a special key or artifact, while they are on a specific quest.
 */
class QuestItemAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    val item: Var<Item> = ConstVar(Item.Empty),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay {
        return QuestItemAudienceDisplay(ref())
    }
}

class QuestItemAudienceDisplay(
    private val ref: Ref<QuestItemAudienceEntry>
) : AudienceDisplay(), Listener {
    override fun initialize() {
        super.initialize()
        server.pluginManager.registerEvents(this, plugin)
    }

    private fun getNamespacedKey(): NamespacedKey {
        return NamespacedKey(plugin, "quest_item_id")
    }

    private fun tagItem(item: ItemStack): ItemStack {
        val meta = item.itemMeta ?: return item
        meta.persistentDataContainer.set(getNamespacedKey(), PersistentDataType.STRING, ref.id)
        item.itemMeta = meta
        return item
    }

    private fun questItemData(itemStack: ItemStack?): String? {
        if (itemStack == null || itemStack.type.isAir) return null
        val meta = itemStack.itemMeta ?: return null
        return meta.persistentDataContainer.get(getNamespacedKey(), PersistentDataType.STRING)
    }

    private fun isQuestItem(itemStack: ItemStack?): Boolean {
        return questItemData(itemStack) == ref.id
    }

    /**
     * Determines the slots in the player's inventory that are considered forbidden for use with quest items.
     * Forbidden slots include:
     * - Slots bound to item binders that the player is part of.
     * - Slots occupied by another quest item
     *
     * @param player The player whose inventory will be checked for forbidden slots.
     * @return A set of integers representing the indices of forbidden slots in the player's inventory.
     */
    private fun forbiddenSlots(player: Player): Set<Int> {
        val manager = get<AudienceManager>(AudienceManager::class.java)
        val itemBinderSlots =
            manager.findDisplays(ItemSlotBinderAudience::class).filter { it.contains(player) }.map { it.key(player) }
                .toSet()

        val takenQuestItemSlots =
            player.inventory.contents.withIndex().filter { (_, item) ->
                val questItemData = questItemData(item) ?: return@filter false
                questItemData != ref.id
            }.map { it.index }

        return itemBinderSlots + takenQuestItemSlots
    }


    /**
     * Forcibly gives a quest item to a player, ensuring the item is added to their inventory or dropped at their location
     * if no eligible slot is available. The method respects forbidden slots and handles replacement or dropping logic.
     *
     * @param player The player who will receive the quest item.
     * @param questItem The quest item to be given to the player. Must be a valid quest item tagged with the appropriate entry ID.
     */
    private fun forceGiveQuestItem(player: Player, questItem: ItemStack) = Dispatchers.Sync.launch {
        if (!player.isOnline) return@launch
        assert(isQuestItem(questItem)) { "Quest item must be tagged with the entry id" }


        if (replaceExistingQuestItem(player, questItem)) return@launch
        if (isQuestItem(player.itemOnCursor)) {
            player.setItemOnCursor(questItem)
            return@launch
        }

        val forbiddenSlots = forbiddenSlots(player)

        val storageContents = player.inventory.storageContents

        if (insertIntoEmptySlot(forbiddenSlots, storageContents, player, questItem)) return@launch
        if (dropAndReplaceNonQuestItem(forbiddenSlots, storageContents, player, questItem)) return@launch

        player.world.dropItemNaturally(player.location, questItem)
    }

    /**
     * Replaces an existing quest item in the player's inventory with a new quest item.
     * If a quest item is found in the inventory, it will be replaced with the provided item.
     * The player's existing quest item reference is also updated.
     *
     * @param player The player whose inventory will be checked and updated.
     * @param questItem The new quest item to replace the existing one in the inventory.
     * @return `true` if a quest item was found and successfully replaced; `false` otherwise.
     */
    private fun replaceExistingQuestItem(player: Player, questItem: ItemStack): Boolean {
        val index = player.inventory.contents.withIndex()
            .firstOrNull { (_, itemStack) -> isQuestItem(itemStack) }?.index
            ?: return false
        player.inventory.setItem(index, questItem)
        return true
    }

    /**
     * Finds the first eligible slot in the storage contents that satisfies the given predicate and is not in the set of forbidden slots.
     *
     * @param forbiddenSlots A set of indices representing slots that cannot be selected.
     * @param storageContents An array of ItemStack objects representing the storage contents to evaluate.
     * @param predicate A function that takes an ItemStack and returns true if it satisfies a given condition.
     * @return The index of the first slot that satisfies the predicate and is not forbidden, or null if no such slot exists.
     */
    private fun findEligibleSlot(
        forbiddenSlots: Set<Int>,
        storageContents: Array<out ItemStack?>,
        predicate: (ItemStack?) -> Boolean,
    ): Int? {
        return storageContents.withIndex()
            .firstOrNull { (index, itemStack) -> index !in forbiddenSlots && predicate(itemStack) }?.index
    }

    /**
     * Attempts to insert a quest item into the first available empty inventory slot of the player,
     * skipping over any forbidden slots. If an eligible slot is found, the item is added to the
     * player's inventory, and their quest item reference is updated.
     *
     * @param forbiddenSlots A set of indices representing inventory slots that should not be used for insertion.
     * @param storageContents An array containing the contents of the player's storage to evaluate for availability.
     * @param player The player whose inventory will be modified.
     * @param questItem The quest item to be inserted into the player's inventory.
     * @return `true` if the item was successfully inserted into an empty slot; `false` otherwise.
     */
    private fun insertIntoEmptySlot(
        forbiddenSlots: Set<Int>,
        storageContents: Array<out ItemStack?>,
        player: Player,
        questItem: ItemStack
    ): Boolean {
        val targetSlot =
            findEligibleSlot(forbiddenSlots, storageContents) { it == null || it.type.isAir } ?: return false

        player.inventory.setItem(targetSlot, questItem)
        return true
    }

    /**
     * Drops a non-quest item from the player's inventory and replaces it with a specified quest item.
     * Ensures that forbidden slots are not modified and only eligible non-quest items are replaced.
     *
     * @param forbiddenSlots A set of indices representing inventory slots that are restricted from use.
     * @param storageContents An array containing the contents of the player's storage to evaluate for eligible items.
     * @param player The player whose inventory will be checked and modified.
     * @param questItem The quest item to replace the non-quest item with. The item must be a valid quest item.
     * @return `true` if an eligible non-quest item was successfully replaced; `false` if no eligible items were found.
     */
    private fun dropAndReplaceNonQuestItem(
        forbiddenSlots: Set<Int>,
        storageContents: Array<out ItemStack?>,
        player: Player,
        questItem: ItemStack
    ): Boolean {
        val slotToSwap =
            findEligibleSlot(forbiddenSlots, storageContents) { it != null && !it.type.isAir && !isQuestItem(it) }
                ?: return false

        val itemToDrop = player.inventory.getItem(slotToSwap)
        assert(itemToDrop != null) { "Item to drop cannot be null" }

        player.world.dropItemNaturally(player.location, itemToDrop!!)
        player.inventory.setItem(slotToSwap, questItem)
        player.sendMessage(inventoryFullMessage.parsePlaceholders(player).asMini())
        return true
    }


    /**
     * Removes all quest items from the specified player's inventory and clears the reference
     * to the player's quest items in the internal tracking system.
     *
     * This method ensures that:
     * - All quest items in the player's inventory are set to null.
     * - The item on the player's cursor is cleared if it is a quest item.
     * - The player's quest item reference is removed from the `playerItems` collection.
     *
     * @param player The player from whose inventory the quest items should be removed.
     */
    private fun removeQuestItem(player: Player) {

        player.inventory.contents.withIndex()
            .filter { (_, item) -> isQuestItem(item) }
            .forEach { (index, _) ->
                player.inventory.setItem(index, null)
            }

        if (isQuestItem(player.itemOnCursor)) {
            player.setItemOnCursor(null)
        }
    }

    override fun onPlayerAdd(player: Player) {
        val entry = ref.get() ?: return
        val rawItem = entry.item.get(player).build(player)
        val questItem = tagItem(rawItem)
        forceGiveQuestItem(player, questItem)
    }

    override fun onPlayerRemove(player: Player) {
        removeQuestItem(player)
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onItemDrop(event: PlayerDropItemEvent) {
        if (!contains(event.player)) return

        if (isQuestItem(event.itemDrop.itemStack)) {
            event.isCancelled = true
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInventoryClose(event: InventoryCloseEvent) {
        val player = event.player as? Player ?: return
        if (!contains(player)) return

        val cursor = player.itemOnCursor
        if (isQuestItem(cursor)) {
            player.setItemOnCursor(null)
            forceGiveQuestItem(player, cursor)
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInventoryClick(event: InventoryClickEvent) {
        val player = event.whoClicked as? Player ?: return
        if (!contains(player)) return

        val cursorItem = event.cursor
        val currentItem = event.currentItem
        val clickedInventory = event.clickedInventory

        // Handle Hotbar Swapping (Number Keys)
        if (event.click == org.bukkit.event.inventory.ClickType.NUMBER_KEY) {
            val hotbarItem = player.inventory.getItem(event.hotbarButton)
            // If the item moving FROM the hotbar is a quest item
            if (isQuestItem(hotbarItem)) {
                // Prevent moving into a non-player container
                if (clickedInventory != null && clickedInventory.type != InventoryType.PLAYER) {
                    event.isCancelled = true
                    return
                }
            }
            // Note: If the item moving TO the hotbar (currentItem) is a quest item, standard checks apply below?
            // Actually, if we swap a quest item meant to stay in inv, it's fine as long as it stays in inv.
            // But we must block moving IT out if it was in the slot.
        }

        val isInteractingWithQuestItem = isQuestItem(currentItem) || isQuestItem(cursorItem)

        // Block splitting (Right Click, Pickup Half, Place One, etc.)
        if (isInteractingWithQuestItem) {
            if (event.click.isRightClick || event.action == org.bukkit.event.inventory.InventoryAction.PICKUP_HALF ||
                event.action == org.bukkit.event.inventory.InventoryAction.PLACE_ONE ||
                event.action == org.bukkit.event.inventory.InventoryAction.PLACE_SOME
            ) {
                event.isCancelled = true
                return
            }
        }

        // If clicked outside the window
        if (clickedInventory == null) {
            if (isQuestItem(cursorItem)) {
                event.isCancelled = true
            }
            return
        }

        // Block interaction with crafting slots
        if (clickedInventory.type == InventoryType.CRAFTING && event.slot in 1..4) {
            if (isInteractingWithQuestItem) {
                event.isCancelled = true
                return
            }
        }

        if (!isInteractingWithQuestItem) return

        // Prevent placing into containers (non-player)
        if (clickedInventory.type != InventoryType.PLAYER && clickedInventory.type != InventoryType.CRAFTING) {
            event.isCancelled = true
            return
        }

        // Prevent shift-clicking into containers from player inventory
        if (clickedInventory.type == InventoryType.PLAYER && event.view.topInventory.type != InventoryType.PLAYER && event.isShiftClick) {
            event.isCancelled = true
            return
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInventoryDrag(event: InventoryDragEvent) {
        val player = event.whoClicked as? Player ?: return
        if (!contains(player)) return

        // Strictly disallow dragging quest items
        if (isQuestItem(event.oldCursor)) {
            event.isCancelled = true
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onBlockPlace(event: BlockPlaceEvent) {
        if (!contains(event.player)) return

        if (!isQuestItem(event.itemInHand)) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInteractEntity(event: PlayerInteractEntityEvent) {
        if (!contains(event.player)) return

        if (event.rightClicked !is ItemFrame && event.rightClicked !is ArmorStand) return
        val hand = event.hand
        val item =
            if (hand == EquipmentSlot.HAND) event.player.inventory.itemInMainHand else event.player.inventory.itemInOffHand

        if (!isQuestItem(item)) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInteractAtEntity(event: PlayerInteractAtEntityEvent) {
        if (!contains(event.player)) return

        if (event.rightClicked !is ArmorStand) return
        val hand = event.hand
        val item =
            if (hand == EquipmentSlot.HAND) event.player.inventory.itemInMainHand else event.player.inventory.itemInOffHand

        if (!isQuestItem(item)) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onPlayerDeath(event: PlayerDeathEvent) {
        if (!contains(event.entity)) return

        val questItemStacks = event.drops.filter { item ->
            isQuestItem(item)
        }
        if (questItemStacks.isEmpty()) return

        event.drops.removeAll(questItemStacks)

        val playerId = event.entity.uniqueId
        Dispatchers.Sync.launch {
            delay(1.ticks)
            val player = server.getPlayer(playerId) ?: return@launch
            if (!contains(player)) return@launch

            questItemStacks.forEach { item ->
                forceGiveQuestItem(player, item)
            }
        }
    }

    override fun dispose() {
        super.dispose()
        unregister()
    }
}
