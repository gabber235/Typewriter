package com.typewritermc.basic.entries.audience

import com.destroystokyo.paper.event.player.PlayerLaunchProjectileEvent
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.item.Item
import io.papermc.paper.event.player.PlayerItemFrameChangeEvent
import kotlinx.coroutines.Dispatchers
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.block.BlockPlaceEvent
import org.bukkit.event.entity.EntityPickupItemEvent
import org.bukkit.event.entity.EntityPlaceEvent
import org.bukkit.event.entity.PlayerDeathEvent
import org.bukkit.event.hanging.HangingPlaceEvent
import org.bukkit.event.inventory.*
import org.bukkit.event.player.*
import org.bukkit.inventory.ItemStack

private const val RECONCILE_INTERVAL_TICKS = 10

@Entry("quest_item_audience", "Gives players an item they cannot lose", Colors.GREEN, "mdi:treasure-chest")
/**
 * The `Quest Item Audience` entry forces players in the audience to carry an item they cannot lose.
 * The item can be moved around the inventory, but it cannot be dropped, moved into a container, used up, or
 * lost on death. Once a player leaves the audience, the item is taken back.
 *
 * If the inventory is full, you can choose what happens:
 *
 * - **Wait For Space**: Wait until a slot frees up, and ask the player to make room in the meantime.
 * - **Drop**: Drop whatever is in the way on the floor.
 * - **Replace**: Take whatever is in the way, and give it back as soon as the player has room for it again.
 *
 * If the item belongs in a slot of its own, use the `Item Slot Binder Audience` instead.
 *
 * ## How could this be used?
 * A key that has to stay with the player until they open the door it belongs to.
 * Or a relic they have to carry back to the temple and cannot stash in a chest along the way.
 */
class QuestItemAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The item the player has to carry.")
    val item: Var<Item> = ConstVar(Item.Empty),
    @Help("What to do when the player's inventory is full.")
    val inventoryFull: InventoryFullStrategy = InventoryFullStrategy.WAIT_FOR_SPACE,
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = QuestItemAudienceDisplay(ref(), item, inventoryFull)
}

/**
 * Refuses every way the item has of leaving the player, and leans on [QuestItemStock] for what they should be
 * holding in the first place.
 *
 * The one rule the refusals are built on is that a quest item may go anywhere in the player's own inventory
 * and nowhere else. Every container in the game takes items through the inventory click event, so
 * [onInventoryClick] covers all of them at once. The handlers after it are the ways an item leaves an
 * inventory without a click.
 */
class QuestItemAudienceDisplay(
    private val ref: Ref<QuestItemAudienceEntry>,
    item: Var<Item>,
    inventoryFull: InventoryFullStrategy,
) : AudienceDisplay(), TickableDisplay {
    private val stock = QuestItemStock(ref, item, inventoryFull)
    private var ticks = 0

    override fun onPlayerAdd(player: Player) {
        Dispatchers.Sync.launch { reconcile(player) }
    }

    override fun onPlayerRemove(player: Player) {
        Dispatchers.Sync.launch { stock.takeBack(player) }
    }

    /** The pass that hands the item out and catches whatever got past the refusals, a /clear or a plugin. */
    override fun tick() {
        if (++ticks % RECONCILE_INTERVAL_TICKS != 0) return
        val audience = players
        if (audience.isEmpty()) return
        Dispatchers.Sync.launch { audience.forEach(::reconcile) }
    }

    /**
     * Call on the main thread, as the audience tick loop does not run there.
     *
     * Whether the player is still in the audience is asked again here rather than taken from whoever queued
     * this. A tick takes the audience as it is and reaches the main thread a moment later, by which time the
     * player may have been let go of and had their item taken back, and handing it over again would leave
     * them with one that nothing is left to take.
     */
    private fun reconcile(player: Player) {
        if (player !in this) return
        stock.reconcile(player)
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onInventoryClick(event: InventoryClickEvent) {
        val player = event.whoClicked as? Player ?: return
        if (event is InventoryCreativeEvent) return guardCreativeWrite(event, player)

        val escapes = clickEscapesInventory(
            action = event.action,
            inOwnInventory = event.rawSlot >= event.view.topInventory.size,
            ownScreen = event.view.topInventory.type == InventoryType.CRAFTING,
            slotIsQuestItem = event.currentItem.carriesQuestItemOf(ref),
            cursorIsQuestItem = event.cursor.carriesQuestItemOf(ref),
            swapInIsQuestItem = event.swappedIn(player).carriesQuestItemOf(ref),
        )
        if (escapes) event.isCancelled = true
    }

    /**
     * A creative client writes inventory slots itself, so it deletes the item by writing nothing over it and
     * duplicates it by writing a copy somewhere else. Both are refused and the inventory is sent again.
     *
     * Moving the item is those same two writes, so a creative player cannot move it either.
     */
    private fun guardCreativeWrite(event: InventoryCreativeEvent, player: Player) {
        if (!event.currentItem.carriesQuestItemOf(ref) && !event.cursor.carriesQuestItemOf(ref)) return
        event.isCancelled = true
        Dispatchers.Sync.launch { player.updateInventory() }
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onInventoryDrag(event: InventoryDragEvent) {
        if (!event.oldCursor.carriesQuestItemOf(ref)) return
        val topSize = event.view.topInventory.size
        if (event.rawSlots.none { it < topSize }) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onDropItem(event: PlayerDropItemEvent) {
        if (!event.itemDrop.itemStack.carriesQuestItemOf(ref)) return
        event.isCancelled = true
    }

    /**
     * Whatever is on the cursor is dropped when the window closes, so it goes back into the inventory first.
     *
     * It goes back the way it is handed out in the first place, so that a full inventory is met with the same
     * strategy rather than with the item quietly going nowhere.
     */
    @EventHandler(priority = EventPriority.HIGHEST)
    fun onInventoryClose(event: InventoryCloseEvent) {
        val player = event.player as? Player ?: return
        val cursor = player.itemOnCursor
        if (!cursor.carriesQuestItemOf(ref)) return
        player.setItemOnCursor(null)
        stock.handOut(player, cursor)
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onPlayerDeath(event: PlayerDeathEvent) {
        val drops = event.drops.iterator()
        while (drops.hasNext()) {
            val drop = drops.next()
            if (!drop.carriesQuestItemOf(ref)) continue
            drops.remove()
            event.itemsToKeep.add(drop)
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onItemConsume(event: PlayerItemConsumeEvent) {
        if (event.item.isQuestItemOf(ref)) event.isCancelled = true
    }

    /** Breaking cannot be cancelled, so the durability is never allowed to drop in the first place. */
    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onItemDamage(event: PlayerItemDamageEvent) {
        if (event.item.isQuestItemOf(ref)) event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onBlockPlace(event: BlockPlaceEvent) {
        if (event.itemInHand.isQuestItemOf(ref)) event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onEntityPlace(event: EntityPlaceEvent) {
        val player = event.player ?: return
        if (player.inventory.getItem(event.hand).isQuestItemOf(ref)) event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onHangingPlace(event: HangingPlaceEvent) {
        if (event.itemStack.carriesQuestItemOf(ref)) event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onItemFrameChange(event: PlayerItemFrameChangeEvent) {
        if (event.action != PlayerItemFrameChangeEvent.ItemFrameChangeAction.PLACE) return
        if (event.itemStack.carriesQuestItemOf(ref)) event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onArmorStandManipulate(event: PlayerArmorStandManipulateEvent) {
        if (event.playerItem.carriesQuestItemOf(ref)) event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onLaunchProjectile(event: PlayerLaunchProjectileEvent) {
        if (event.itemStack.isQuestItemOf(ref)) event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onBucketEmpty(event: PlayerBucketEmptyEvent) {
        if (event.player.inventory.getItem(event.hand).isQuestItemOf(ref)) event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onBucketFill(event: PlayerBucketFillEvent) {
        if (event.player.inventory.getItem(event.hand).isQuestItemOf(ref)) event.isCancelled = true
    }

    /**
     * Signing turns a writable book into a written one, which is a different item.
     *
     * A book can be signed from either hand and the event does not say which, so both are matched against the
     * meta the book had before.
     */
    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onEditBook(event: PlayerEditBookEvent) {
        if (!event.isSigning) return
        val inventory = event.player.inventory
        val hands = sequenceOf(inventory.itemInMainHand, inventory.itemInOffHand)
        if (hands.none { it.isQuestItemOf(ref) && it.itemMeta == event.previousBookMeta }) return
        event.isCancelled = true
    }

    /** A copy that leaked into the world still belongs to the player it was given to. */
    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    fun onPickupItem(event: EntityPickupItemEvent) {
        val carried = event.item.itemStack.carriedQuestItemOf(ref) ?: return
        val picker = event.entity as? Player
        if (picker != null && carried.questItemOwner == picker.uniqueId) return
        event.isCancelled = true
    }
}

/** The item a swap brings in: the offhand for an offhand swap, and otherwise the hotbar slot the key names. */
private fun InventoryClickEvent.swappedIn(player: Player): ItemStack? = when {
    click == ClickType.SWAP_OFFHAND -> player.inventory.itemInOffHand
    hotbarButton >= 0 -> player.inventory.getItem(hotbarButton)
    else -> null
}
