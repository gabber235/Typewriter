package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.engine.paper.utils.server
import lirand.api.extensions.events.unregister
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.entity.PlayerDeathEvent
import org.bukkit.event.inventory.InventoryClickEvent
import org.bukkit.event.inventory.InventoryType
import org.bukkit.event.player.PlayerDropItemEvent
import org.bukkit.inventory.ItemStack
import java.util.*
import java.util.concurrent.ConcurrentHashMap

import org.bukkit.NamespacedKey
import org.bukkit.persistence.PersistentDataType
import org.bukkit.event.block.BlockPlaceEvent
import org.bukkit.event.player.PlayerInteractEntityEvent
import org.bukkit.event.player.PlayerInteractAtEntityEvent
import org.bukkit.event.player.PlayerInteractEvent
import org.bukkit.event.inventory.InventoryDragEvent
import org.bukkit.entity.ItemFrame
import org.bukkit.entity.ArmorStand
import org.bukkit.event.block.Action
import org.bukkit.inventory.EquipmentSlot

private val inventoryFullMessage by snippet(
    "quest_item.inventory_full",
    "<yellow>Your inventory was full! An item has been dropped to make space for the quest item."
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
 * The item can be moved freely within the player's inventory but cannot be:
 * - Dropped manually
 * - Moved to containers (chests, shulker boxes, etc.)
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
    private val playerItems = ConcurrentHashMap<UUID, ItemStack>()

    override fun initialize() {
        super.initialize()
        server.pluginManager.registerEvents(this, plugin)
    }

    private fun getNamespacedKey(): NamespacedKey {
        return NamespacedKey(plugin, "quest_item_id")
    }

    private fun getUniqueInstanceKey(): NamespacedKey {
        return NamespacedKey(plugin, "unique_instance")
    }

    private fun tagItem(item: ItemStack, entryId: String): ItemStack {
        val meta = item.itemMeta ?: return item
        meta.persistentDataContainer.set(getNamespacedKey(), PersistentDataType.STRING, entryId)
        // Add a random UUID to ensure uniqueness and prevent stacking with other instances if needed
        // or just to make it unique from vanilla items.
        meta.persistentDataContainer.set(getUniqueInstanceKey(), PersistentDataType.STRING, UUID.randomUUID().toString())
        item.itemMeta = meta
        return item
    }

    private fun isQuestItem(item: ItemStack?, entryId: String): Boolean {
        if (item == null || item.type.isAir) return false
        val meta = item.itemMeta ?: return false
        val storedId = meta.persistentDataContainer.get(getNamespacedKey(), PersistentDataType.STRING)
        return storedId == entryId
    }

    override fun onPlayerAdd(player: Player) {
        val entry = ref.get() ?: return
        val rawItem = entry.item.get(player).build(player)
        val questItem = tagItem(rawItem, entry.id)

        // Ensure we run on the main thread since we are modifying inventory and potentially dropping items
        server.scheduler.runTask(plugin, Runnable {
            // Try adding the item normally first
            val leftOver = player.inventory.addItem(questItem.clone())
            if (leftOver.isNotEmpty()) {
                // Inventory is full. We need to make space.
                // We'll look for the first slot in the main storage (0-35) that isn't empty (which should be all of them if full)
                // and drop that item to place ours.
                
                // Iterate through storage slots to find a candidate to drop
                var slotToSwap = -1
                for (i in 0 until 36) {
                    val item = player.inventory.getItem(i)
                    if (item != null && !item.type.isAir) {
                        slotToSwap = i
                        break
                    }
                }

                if (slotToSwap != -1) {
                    val itemToDrop = player.inventory.getItem(slotToSwap)
                    if (itemToDrop != null) {
                        // Drop the existing item
                        player.world.dropItemNaturally(player.location, itemToDrop)
                        
                        // Set our quest item in that slot
                        player.inventory.setItem(slotToSwap, questItem)
                        
                        // Notify the player
                        player.sendMessage(inventoryFullMessage.parsePlaceholders(player).asMini())
                    }
                }
            }
            playerItems[player.uniqueId] = questItem
        })
    }

    override fun onPlayerRemove(player: Player) {
        val questItem = playerItems.remove(player.uniqueId) ?: return
        val entry = ref.get() ?: return

        // Remove all instances of the quest item from the player's inventory
        player.inventory.contents.forEachIndexed { index, item ->
            if (isQuestItem(item, entry.id)) {
                player.inventory.setItem(index, null)
            }
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onItemDrop(event: PlayerDropItemEvent) {
        val entry = ref.get() ?: return
        if (!contains(event.player)) return
        
        if (isQuestItem(event.itemDrop.itemStack, entry.id)) {
            event.isCancelled = true
        }
    }



    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInventoryClick(event: InventoryClickEvent) {
        val player = event.whoClicked as? Player ?: return
        val entry = ref.get() ?: return
        if (!contains(player)) return
        
        // Handle clicking outside the inventory window (dropping)
        if (event.clickedInventory == null) {
            if (isQuestItem(event.cursor, entry.id)) {
                event.isCancelled = true
            }
            return
        }
        
        val clickedInventory = event.clickedInventory!!

        // Block ANY interaction with crafting slots (slots 1-4 in CRAFTING inventory type)
        if (clickedInventory.type == InventoryType.CRAFTING && event.slot in 1..4) {
            val currentItem = event.currentItem
            val cursorItem = event.cursor
            
            // Check if the item being placed or already in the slot is the quest item
            if (isQuestItem(currentItem, entry.id) || isQuestItem(cursorItem, entry.id)) {
                event.isCancelled = true
                return
            }
        }
        
        val currentItem = event.currentItem
        val cursorItem = event.cursor

        // Prevent placing quest item from cursor into container
        if (clickedInventory.type != InventoryType.PLAYER && clickedInventory.type != InventoryType.CRAFTING) {
            if (isQuestItem(cursorItem, entry.id)) {
                event.isCancelled = true
                return
            }
        }

        // Prevent moving quest item to non-player inventories (containers)
        if (clickedInventory.type == InventoryType.PLAYER && event.view.topInventory.type != InventoryType.PLAYER) {
            if (isQuestItem(currentItem, entry.id)) {
                // Check if player is trying to move item to container
                if (event.click.isShiftClick) {
                    event.isCancelled = true
                }
            }
        }
        
        // Prevent shift-clicking Quest Items (prevents auto-equip and quick move)
        if (event.click.isShiftClick && isQuestItem(currentItem, entry.id)) {
            event.isCancelled = true
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInventoryDrag(event: InventoryDragEvent) {
        val player = event.whoClicked as? Player ?: return
        val entry = ref.get() ?: return
        if (!contains(player)) return

        // If dragging the quest item
        if (isQuestItem(event.oldCursor, entry.id)) {
            // If the top inventory is a container (not player/crafting)
            if (event.view.topInventory.type != InventoryType.PLAYER && event.view.topInventory.type != InventoryType.CRAFTING) {
                // Check if any of the target slots are in the top inventory
                val topSize = event.view.topInventory.size
                if (event.rawSlots.any { it < topSize }) {
                    event.isCancelled = true
                }
            }
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onBlockPlace(event: BlockPlaceEvent) {
        val entry = ref.get() ?: return
        if (!contains(event.player)) return

        if (isQuestItem(event.itemInHand, entry.id)) {
            event.isCancelled = true
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInteractEntity(event: PlayerInteractEntityEvent) {
        val entry = ref.get() ?: return
        if (!contains(event.player)) return

        if (event.rightClicked is ItemFrame || event.rightClicked is ArmorStand) {
            val hand = event.hand
            val item = if (hand == EquipmentSlot.HAND) event.player.inventory.itemInMainHand else event.player.inventory.itemInOffHand
            
            if (isQuestItem(item, entry.id)) {
                event.isCancelled = true
            }
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInteractAtEntity(event: PlayerInteractAtEntityEvent) {
        val entry = ref.get() ?: return
        if (!contains(event.player)) return

        if (event.rightClicked is ArmorStand) {
            val hand = event.hand
            val item = if (hand == EquipmentSlot.HAND) event.player.inventory.itemInMainHand else event.player.inventory.itemInOffHand
            
            if (isQuestItem(item, entry.id)) {
                event.isCancelled = true
            }
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onPlayerInteract(event: PlayerInteractEvent) {
        val entry = ref.get() ?: return
        if (!contains(event.player)) return
        
        if (event.action == Action.RIGHT_CLICK_AIR || event.action == Action.RIGHT_CLICK_BLOCK) {
            val item = event.item
            if (isQuestItem(item, entry.id)) {
                event.isCancelled = true
            }
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onPlayerDeath(event: PlayerDeathEvent) {
        val entry = ref.get() ?: return
        if (!contains(event.entity)) return
        
        // Remove quest item from drops and keep it for the player
        val questItemStacks = event.drops.filter { item ->
            isQuestItem(item, entry.id)
        }
        
        event.drops.removeAll(questItemStacks)
        
       // Re-add the quest item when the player respawns
        val playerId = event.entity.uniqueId
        server.scheduler.runTaskLater(plugin, Runnable {
            val player = server.getPlayer(playerId) ?: return@Runnable
            if (!contains(player)) return@Runnable
            questItemStacks.forEach { item ->
                val leftOver = player.inventory.addItem(item)
                if (leftOver.isNotEmpty()) {
                    // Handle full inventory similar to onPlayerAdd
                    player.world.dropItemNaturally(player.location, item)
                }
            }
         }, 1L)
    }

    override fun dispose() {
        super.dispose()
        unregister()
        playerItems.clear()
    }
}
