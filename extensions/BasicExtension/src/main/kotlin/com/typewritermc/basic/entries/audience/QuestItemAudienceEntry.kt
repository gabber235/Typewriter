package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.AudienceManager
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.engine.paper.utils.server
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
import org.bukkit.event.player.*
import org.bukkit.inventory.EquipmentSlot
import org.bukkit.inventory.ItemStack
import org.bukkit.persistence.PersistentDataType
import org.koin.java.KoinJavaComponent.get
import java.util.*
import java.util.concurrent.ConcurrentHashMap

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
    private val playerItems = ConcurrentHashMap<UUID, ItemStack>()

    override fun initialize() {
        super.initialize()
        server.pluginManager.registerEvents(this, plugin)
    }

    private fun getNamespacedKey(): NamespacedKey {
        return NamespacedKey(plugin, "quest_item_id")
    }

    private fun tagItem(item: ItemStack, entryId: String): ItemStack {
        val meta = item.itemMeta ?: return item
        meta.persistentDataContainer.set(getNamespacedKey(), PersistentDataType.STRING, entryId)
        item.itemMeta = meta
        return item
    }

    private fun isQuestItem(item: ItemStack?, entryId: String): Boolean {
        if (item == null || item.type.isAir) return false
        val meta = item.itemMeta ?: return false
        val storedId = meta.persistentDataContainer.get(getNamespacedKey(), PersistentDataType.STRING)
        return storedId == entryId
    }

    private fun getForbiddenSlots(player: Player): Set<Int> {
        val manager = get<AudienceManager>(AudienceManager::class.java)
        val forbidden = mutableSetOf<Int>()
        // Find all ItemSlotBinderAudience displays
        manager.findDisplays(ItemSlotBinderAudience::class).forEach { display ->
             if (display.contains(player)) {
                 forbidden.add(display.key(player))
             }
        }
        return forbidden
    }

    private fun forceGiveQuestItem(player: Player, questItem: ItemStack) {
        server.scheduler.runTask(plugin, Runnable {
            if (!player.isOnline) return@Runnable
            
            val forbiddenSlots = getForbiddenSlots(player)
            
            // Check if player already has it (double check inside task)
            if (player.inventory.contents.any { isQuestItem(it, ref.get()?.id ?: "") }) return@Runnable
            if (isQuestItem(player.itemOnCursor, ref.get()?.id ?: "")) return@Runnable

            var targetSlot = -1
            val storageContents = player.inventory.storageContents
            
            // 1. Try to find empty, non-forbidden slot
            for (i in 0 until 36) {
                if (i in forbiddenSlots) continue
                val item = storageContents[i]
                if (item == null || item.type.isAir) {
                    targetSlot = i
                    break
                }
            }
            
            if (targetSlot != -1) {
                player.inventory.setItem(targetSlot, questItem)
                playerItems[player.uniqueId] = questItem
                return@Runnable
            }
            
            // 2. Swap with non-forbidden slot
            var slotToSwap = -1
            for (i in 0 until 36) {
                if (i in forbiddenSlots) continue
                val item = storageContents[i]
                if (item != null && !item.type.isAir && !isQuestItem(item, ref.get()?.id ?: "")) {
                    slotToSwap = i
                    break
                }
            }

            if (slotToSwap != -1) {
                val itemToDrop = player.inventory.getItem(slotToSwap)
                if (itemToDrop != null) {
                    player.world.dropItemNaturally(player.location, itemToDrop)
                    player.inventory.setItem(slotToSwap, questItem)
                    player.sendMessage(inventoryFullMessage.parsePlaceholders(player).asMini())
                    playerItems[player.uniqueId] = questItem
                }
            } else {
                 // 3. Drop quest item if absolutely no space
                 player.world.dropItemNaturally(player.location, questItem)
            }
        })
    }
    
    private fun removeQuestItem(player: Player) {
        val entry = ref.get() ?: return
        playerItems.remove(player.uniqueId)
        
        player.inventory.contents.forEachIndexed { index, item ->
            if (isQuestItem(item, entry.id)) {
                player.inventory.setItem(index, null)
            }
        }
        
        if (isQuestItem(player.itemOnCursor, entry.id)) {
            player.setItemOnCursor(null)
        }
    }

    override fun onPlayerAdd(player: Player) {
        val entry = ref.get() ?: return
        val rawItem = entry.item.get(player).build(player)
        val questItem = tagItem(rawItem, entry.id)
        forceGiveQuestItem(player, questItem)
    }

    override fun onPlayerRemove(player: Player) {
        removeQuestItem(player)
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
    fun onInventoryClose(event: InventoryCloseEvent) {
        val player = event.player as? Player ?: return
        val entry = ref.get() ?: return
        if (!contains(player)) return

        val cursor = player.itemOnCursor
        if (isQuestItem(cursor, entry.id)) {
            player.setItemOnCursor(null)
            forceGiveQuestItem(player, cursor)
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInventoryClick(event: InventoryClickEvent) {
        val player = event.whoClicked as? Player ?: return
        val entry = ref.get() ?: return
        if (!contains(player)) return
        
        if (event.clickedInventory == null) {
            if (isQuestItem(event.cursor, entry.id)) {
                event.isCancelled = true
            }
            return
        }
        
        val clickedInventory = event.clickedInventory!!
        val currentItem = event.currentItem
        val cursorItem = event.cursor

        // Block interaction with crafting slots
        if (clickedInventory.type == InventoryType.CRAFTING && event.slot in 1..4) {
            if (isQuestItem(currentItem, entry.id) || isQuestItem(cursorItem, entry.id)) {
                event.isCancelled = true
                return
            }
        }
        
        // Prevent placing into containers
        if (clickedInventory.type != InventoryType.PLAYER && clickedInventory.type != InventoryType.CRAFTING) {
            if (isQuestItem(cursorItem, entry.id)) {
                event.isCancelled = true
                return
            }
        }

        // Prevent shift-clicking into containers
        if (clickedInventory.type == InventoryType.PLAYER && event.view.topInventory.type != InventoryType.PLAYER) {
            if (isQuestItem(currentItem, entry.id) && event.click.isShiftClick) {
                event.isCancelled = true
                return
            }
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInventoryDrag(event: InventoryDragEvent) {
        val player = event.whoClicked as? Player ?: return
        val entry = ref.get() ?: return
        if (!contains(player)) return

        if (isQuestItem(event.oldCursor, entry.id)) {
            if (event.view.topInventory.type != InventoryType.PLAYER && event.view.topInventory.type != InventoryType.CRAFTING) {
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
    fun onPlayerDeath(event: PlayerDeathEvent) {
        val entry = ref.get() ?: return
        if (!contains(event.entity)) return
        
        val questItemStacks = event.drops.filter { item ->
            isQuestItem(item, entry.id)
        }
        
        event.drops.removeAll(questItemStacks)
        
        val playerId = event.entity.uniqueId
        server.scheduler.runTaskLater(plugin, Runnable {
            val player = server.getPlayer(playerId) ?: return@Runnable
            if (!contains(player)) return@Runnable
            
            questItemStacks.forEach { item ->
                forceGiveQuestItem(player, item)
            }
         }, 1L)
    }

    override fun dispose() {
        super.dispose()
        unregister()
        playerItems.clear()
    }
}
