package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.AudienceManager
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.engine.paper.utils.server
import lirand.api.extensions.events.unregister
import org.bukkit.GameMode
import org.bukkit.NamespacedKey
import org.bukkit.entity.ArmorStand
import org.bukkit.entity.ItemFrame
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.block.Action
import org.bukkit.event.block.BlockPlaceEvent
import org.bukkit.event.entity.PlayerDeathEvent
import org.bukkit.event.inventory.InventoryClickEvent
import org.bukkit.event.inventory.InventoryCloseEvent
import org.bukkit.event.inventory.InventoryDragEvent
import org.bukkit.event.inventory.InventoryType
import org.bukkit.event.player.*
import org.bukkit.inventory.EquipmentSlot
import org.bukkit.inventory.ItemFlag
import org.bukkit.inventory.ItemStack
import org.bukkit.persistence.PersistentDataType
import org.koin.java.KoinJavaComponent.get
import java.util.*
import java.util.concurrent.ConcurrentHashMap

private val inventoryFullMessage by snippet(
    "quest_item.inventory_full",
    "<yellow>Your inventory was full! An item has been dropped to make room for the quest item."
)

private val cooldownMessage by snippet(
    "quest_item.cooldown",
    "<red>You must wait before using this item again."
)

private val itemBreakingMessage by snippet(
    "quest_item.breaking_warning",
    "<red>This item is too fragile to be used anymore!"
)

enum class QuestItemInteractionType {
    LEFT_CLICK,
    RIGHT_CLICK,
    SHIFT_LEFT_CLICK,
    SHIFT_RIGHT_CLICK,
    ALL
}

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
    @Help("If true, the item can be consumed. If false, consumption is blocked.")
    val consumable: Boolean = false,
    @Help("Actions to execute when the item is consumed (if consumable is true).")
    val onConsume: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("Actions to execute when the player interacts with the item.")
    val onInteract: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("Types of interaction that trigger the actions.")
    val interactionTypes: List<QuestItemInteractionType> = listOf(QuestItemInteractionType.ALL),
    @Help("Cooldown in ticks for interaction actions.")
    val interactCooldown: Long = 10L,
    @Help("Fact to track item state (1 = has item, 0 = does not have item). MANDATORY.")
    val stateFact: Ref<FactEntry> = emptyRef(),
    @Help("If true, the item will be unbreakable. If false, durability loss is prevented at 1 durability.")
    val unbreakable: Boolean = true,
    @Help("Optional group to restrict this entry to specific players.")
    val group: Ref<GroupEntry> = emptyRef(),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay {
        return QuestItemAudienceDisplay(ref())
    }
}

class QuestItemAudienceDisplay(
    private val ref: Ref<QuestItemAudienceEntry>
) : AudienceDisplay(), Listener, TickableDisplay {
    private val playerItems = ConcurrentHashMap<UUID, ItemStack>()
    private val interactCooldowns = ConcurrentHashMap<UUID, Long>()

    override fun initialize() {
        super.initialize()
        server.pluginManager.registerEvents(this, plugin)
    }

    private fun getNamespacedKey(): NamespacedKey {
        return NamespacedKey(plugin, "quest_item_id")
    }

    private fun tagItem(item: ItemStack, entryId: String, unbreakable: Boolean): ItemStack {
        val meta = item.itemMeta ?: return item
        meta.persistentDataContainer.set(getNamespacedKey(), PersistentDataType.STRING, entryId)
        if (unbreakable) {
            meta.isUnbreakable = true
            meta.addItemFlags(ItemFlag.HIDE_UNBREAKABLE)
        }
        item.itemMeta = meta
        return item
    }

    private fun isQuestItem(item: ItemStack?, entryId: String): Boolean {
        if (item == null || item.type.isAir) return false
        val meta = item.itemMeta ?: return false
        val storedId = meta.persistentDataContainer.get(getNamespacedKey(), PersistentDataType.STRING)
        return storedId == entryId
    }

    private fun getFactValue(player: Player): Int {
        val entry = ref.get() ?: return 0
        val factRef = entry.stateFact
        if (factRef == emptyRef<FactEntry>()) return 0 // Should not happen if mandatory
        
        val factEntry = factRef.get()
        return (factEntry as? ReadableFactEntry)?.readForPlayersGroup(player)?.value ?: 0
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
        // Avoid giving item if player is in Creative mode and holding something, to prevent ghosts
        // But we must enforce it.
        // If creative, try to be less aggressive if they are dragging it?
        
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
        // Initial check is done in tick() or here?
        // Let's do it here to be responsive.
        val factValue = getFactValue(player)
        if (factValue == 1) {
            val entry = ref.get() ?: return
            val rawItem = entry.item.get(player).build(player)
            val questItem = tagItem(rawItem, entry.id, entry.unbreakable)
            forceGiveQuestItem(player, questItem)
        } else if (factValue == 0) {
            removeQuestItem(player)
        }
    }

    override fun onPlayerRemove(player: Player) {
        // When removed from audience, we usually remove the item?
        // User said: "if the fact linked is equal to 0... remove. If 1... possess."
        // If they leave the audience, the entry no longer controls them.
        // But usually we clean up.
        // Let's remove it to be safe, assuming audience membership is the primary scope.
        removeQuestItem(player)
    }

    override fun tick() {
        if (server.currentTick % 20 != 0) return
        
        val entry = ref.get() ?: return
        
        server.onlinePlayers.forEach { player ->
            if (contains(player)) {
                val factValue = getFactValue(player)
                
                var hasItem = false
                for (item in player.inventory.contents) {
                    if (isQuestItem(item, entry.id)) {
                        hasItem = true
                        break
                    }
                }
                if (!hasItem && isQuestItem(player.itemOnCursor, entry.id)) {
                    hasItem = true
                }
                
                if (factValue == 1 && !hasItem) {
                    val rawItem = entry.item.get(player).build(player)
                    val questItem = tagItem(rawItem, entry.id, entry.unbreakable)
                    forceGiveQuestItem(player, questItem)
                } else if (factValue == 0 && hasItem) {
                    removeQuestItem(player)
                }
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
    fun onInventoryClose(event: InventoryCloseEvent) {
        val player = event.player as? Player ?: return
        val entry = ref.get() ?: return
        if (!contains(player)) return

        val cursor = player.itemOnCursor
        if (isQuestItem(cursor, entry.id)) {
            // If fact is 0, we should remove it, but tick will handle it.
            // If fact is 1, we must ensure they keep it.
            // Put it back in inventory.
            player.setItemOnCursor(null)
            forceGiveQuestItem(player, cursor)
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInventoryClick(event: InventoryClickEvent) {
        val player = event.whoClicked as? Player ?: return
        val entry = ref.get() ?: return
        if (!contains(player)) return
        
        // Creative mode handling:
        // In Creative, the client has more control. Cancelling might cause desync/ghost items.
        // However, we still want to prevent them from deleting it or putting it in chests.
        // If they are just moving it around in their inventory, it's fine.
        
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
        
        // If Creative, we might need to be careful about duplication.
        // The duplication usually happens if we cancel the event but the client thinks it succeeded.
        // Or if we forceGive while they are holding it.
        // Our tick check handles re-giving, so we shouldn't need to aggressively cancel moves within player inventory.
        // The logic above only cancels moves to containers or crafting, which is correct.
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
    fun onPlayerInteract(event: PlayerInteractEvent) {
        val entry = ref.get() ?: return
        if (!contains(event.player)) return
        
        val item = event.item ?: return
        if (!isQuestItem(item, entry.id)) return

        val allowedTypes = entry.interactionTypes
        val isAllowed = allowedTypes.contains(QuestItemInteractionType.ALL) || when (event.action) {
            Action.LEFT_CLICK_AIR, Action.LEFT_CLICK_BLOCK -> {
                if (event.player.isSneaking) allowedTypes.contains(QuestItemInteractionType.SHIFT_LEFT_CLICK)
                else allowedTypes.contains(QuestItemInteractionType.LEFT_CLICK)
            }
            Action.RIGHT_CLICK_AIR, Action.RIGHT_CLICK_BLOCK -> {
                if (event.player.isSneaking) allowedTypes.contains(QuestItemInteractionType.SHIFT_RIGHT_CLICK)
                else allowedTypes.contains(QuestItemInteractionType.RIGHT_CLICK)
            }
            else -> false
        }

        if (isAllowed && entry.onInteract.isNotEmpty()) {
            val now = System.currentTimeMillis()
            val lastInteract = interactCooldowns.getOrDefault(event.player.uniqueId, 0L)
            val cooldownMillis = entry.interactCooldown * 50 
            
            if (now - lastInteract >= cooldownMillis) {
                interactCooldowns[event.player.uniqueId] = now
                entry.onInteract.forEach { triggerRef ->
                    triggerRef.triggerFor(event.player, context())
                }
            } else {
                event.player.sendMessage(cooldownMessage.parsePlaceholders(event.player).asMini())
            }
        }

        if (event.action == Action.RIGHT_CLICK_BLOCK && item.type.isBlock) {
            event.isCancelled = true
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onPlayerConsume(event: PlayerItemConsumeEvent) {
        val entry = ref.get() ?: return
        if (!contains(event.player)) return
        
        if (isQuestItem(event.item, entry.id)) {
            if (!entry.consumable) {
                event.isCancelled = true
            } else {
                entry.onConsume.forEach { triggerRef ->
                    triggerRef.triggerFor(event.player, context())
                }
            }
        }
    }
    
    @EventHandler(priority = EventPriority.HIGHEST)
    fun onItemDamage(event: PlayerItemDamageEvent) {
        val entry = ref.get() ?: return
        if (!contains(event.player)) return
        
        if (isQuestItem(event.item, entry.id)) {
            if (entry.unbreakable) {
                // Should be handled by meta, but double check
                event.isCancelled = true
            } else {
                val currentDamage = event.item.durability
                val maxDurability = event.item.type.maxDurability
                val newDamage = currentDamage + event.damage
                
                if (newDamage >= maxDurability - 1) {
                    event.isCancelled = true
                    event.player.sendMessage(itemBreakingMessage.parsePlaceholders(event.player).asMini())
                }
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
            
            // Re-give items if fact is 1. 
            // If fact is 0, we shouldn't give them back (but they shouldn't have had them?)
            // If they had them at death, we assume they should keep them unless fact changed.
            val factValue = getFactValue(player)
            if (factValue == 1) {
                questItemStacks.forEach { item ->
                    forceGiveQuestItem(player, item)
                }
            }
         }, 1L)
    }

    override fun dispose() {
        super.dispose()
        unregister()
        playerItems.clear()
        interactCooldowns.clear()
    }
}
