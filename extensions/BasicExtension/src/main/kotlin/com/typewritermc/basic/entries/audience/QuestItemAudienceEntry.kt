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

    override fun onPlayerAdd(player: Player) {
        val entry = ref.get() ?: return
        val questItem = entry.item.get(player).build(player)
        
        val leftOver = player.inventory.addItem(questItem)
        if (leftOver.isNotEmpty()) {
            // Inventory is full, force placement by dropping the first non-empty slot item
            val firstNonEmptySlot = player.inventory.storageContents.indexOfFirst { it != null && !it.isEmpty }
            if (firstNonEmptySlot >= 0) {
                val droppedItem = player.inventory.storageContents[firstNonEmptySlot]
                if (droppedItem != null) {
                    player.world.dropItemNaturally(player.location, droppedItem)
                    player.inventory.storageContents[firstNonEmptySlot] = questItem
                    player.sendMessage(inventoryFullMessage.parsePlaceholders(player).asMini())
                }
            }
        }
        
        playerItems[player.uniqueId] = questItem
    }

    override fun onPlayerRemove(player: Player) {
        val questItem = playerItems.remove(player.uniqueId) ?: return
        val entry = ref.get() ?: return
        
        // Remove all instances of the quest item from the player's inventory
        player.inventory.contents.forEachIndexed { index, item ->
            if (item != null && entry.item.get(player).isSameAs(player, item)) {
                player.inventory.setItem(index, null)
            }
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onItemDrop(event: PlayerDropItemEvent) {
        val entry = ref.get() ?: return
        if (!contains(event.player)) return
        
        if (entry.item.get(event.player).isSameAs(event.player, event.itemDrop.itemStack)) {
            event.isCancelled = true
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInventoryClick(event: InventoryClickEvent) {
        val player = event.whoClicked as? Player ?: return
        val entry = ref.get() ?: return
        if (!contains(player)) return
        
        val clickedInventory = event.clickedInventory ?: return
        
        // Block ANY interaction with crafting slots (slots 1-4 in CRAFTING inventory type)
        if (clickedInventory.type == InventoryType.CRAFTING && event.slot in 1..4) {
            val currentItem = event.currentItem
            val cursorItem = event.cursor
            
            // Check if the item being placed or already in the slot is the quest item
            if ((currentItem != null && entry.item.get(player).isSameAs(player, currentItem)) ||
                (cursorItem != null && entry.item.get(player).isSameAs(player, cursorItem))) {
                event.isCancelled = true
                return
            }
        }
        
        val currentItem = event.currentItem ?: return
        
        // Prevent moving quest item to non-player inventories (containers)
        if (clickedInventory.type == InventoryType.PLAYER && event.view.topInventory.type != InventoryType.PLAYER) {
            if (entry.item.get(player).isSameAs(player, currentItem)) {
                // Check if player is trying to move item to container
                if (event.click.isShiftClick) {
                    event.isCancelled = true
                }
            }
        }
        
        // Prevent moving quest item from player inventory to container
        if (clickedInventory.type == InventoryType.PLAYER) {
            if (entry.item.get(player).isSameAs(player, currentItem)) {
                val topInventory = event.view.topInventory
                if (topInventory.type != InventoryType.PLAYER && topInventory.type != InventoryType.CRAFTING) {
                    event.isCancelled = true
                }
            }
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onPlayerDeath(event: PlayerDeathEvent) {
        val entry = ref.get() ?: return
        if (!contains(event.entity)) return
        
        // Remove quest item from drops and keep it for the player
        val questItemStacks = event.drops.filter { item ->
            entry.item.get(event.entity).isSameAs(event.entity, item)
        }
        
        event.drops.removeAll(questItemStacks)
        
        // Re-add the quest item when the player respawns
        server.scheduler.runTaskLater(plugin, Runnable {
            questItemStacks.forEach { item ->
                event.entity.inventory.addItem(item)
            }
        }, 1L)
    }

    override fun dispose() {
        super.dispose()
        unregister()
        playerItems.clear()
    }
}
