package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.InnerMax
import com.typewritermc.core.extension.annotations.InnerMin
import com.typewritermc.core.extension.annotations.Max
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.engine.paper.entry.audience.MultiKey
import com.typewritermc.engine.paper.entry.audience.PlayerSingleKeyedDisplay
import com.typewritermc.engine.paper.entry.audience.SingleKeyedFilter
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.item.Item
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.server
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.inventory.InventoryClickEvent
import org.bukkit.event.player.PlayerDropItemEvent
import org.bukkit.event.player.PlayerSwapHandItemsEvent
import org.bukkit.inventory.ItemStack
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass

private const val OFFHAND_SLOT = 40

@Entry(
    "item_slot_binder_audience",
    "Forces a specific item in a specific slot for players in the audience",
    Colors.GREEN,
    "mdi:archive-lock"
)
/**
 * The `Item Slot Binder Audience` entry is an audience filter that forces a specific item in a specific slot for players in the audience.
 *
 * If the slot is already occupied, you can choose the replacement strategy:
 *
 * - **Move Or Drop**: Move the item to the next available slot. If the inventory is full, the item will be dropped.
 * - **Move Or Replace**: Move the item to the next available slot. If the inventory is full, the item will be replaced and reset when the player leaves the audience.
 * - **Replace**: Replaces the item with the new item. But resets the old item when the player leaves the audience.
 *
 * ## How could this be used?
 * Force the player to have a quest book in the 9th slot.
 * Or lobby items which the player needs to keep in the correct slots.
 */
class ItemSlotBinderAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    @InnerMin(Min(0))
    @InnerMax(Max(40))
    val slot: Var<Int> = ConstVar(0),
    val item: Var<Item> = ConstVar(Item.Empty),
    val replacementStrategy: SlotReplacementStrategy = SlotReplacementStrategy.MOVE_OR_DROP,
) : AudienceFilterEntry {
    override val children: List<Ref<out AudienceEntry>>
        get() = emptyList()

    override suspend fun display(): AudienceFilter {
        return ItemSlotBinderAudience(slot, ref()) { player ->
            ItemSlotBinderDisplay(player, slot.get(player), ItemSlotBinderAudience::class, ref())
        }
    }
}

// What todo when the slot is already occupied
enum class SlotReplacementStrategy {
    /**
     * Move the item to the next available slot.
     * If the inventory is full, the item will be dropped.
     */
    MOVE_OR_DROP,

    /**
     * Move the item to the next available slot.
     * If the inventory is full, the item will be replaced and reset when the player leaves the audience.
     */
    MOVE_OR_REPLACE,

    /**
     * Replaces the item with the new item.
     * But resets the old item when the player leaves the audience.
     */
    REPLACE,
}

class ItemSlotBinderAudience(
    val slot: Var<Int>,
    ref: Ref<ItemSlotBinderAudienceEntry>,
    createDisplay: (Player) -> ItemSlotBinderDisplay,
) : SingleKeyedFilter<ItemSlotBinderAudienceEntry, Int, ItemSlotBinderDisplay>(ref, createDisplay) {
    override val displays: MutableMap<MultiKey<UUID, Int>, ItemSlotBinderDisplay>
        get() = map

    override fun key(player: Player): Int {
        return slot.get(player).coerceAtLeast(0)
    }

    companion object {
        private val map = ConcurrentHashMap<MultiKey<UUID, Int>, ItemSlotBinderDisplay>()
    }
}

class ItemSlotBinderDisplay(
    player: Player,
    private val slot: Int,
    displayKClass: KClass<out SingleKeyedFilter<ItemSlotBinderAudienceEntry, Int, *>>,
    current: Ref<ItemSlotBinderAudienceEntry>,
) : PlayerSingleKeyedDisplay<ItemSlotBinderAudienceEntry, Int>(player, slot, displayKClass, current), Listener {
    private var resetItem = ItemStack.empty()
    private var lastItem = ItemStack.empty()

    override fun initialize() {
        server.pluginManager.registerEvents(this, plugin)
        super.initialize()
    }

    override fun setup() {
        super.setup()
        val entry = ref.get() ?: throw IllegalStateException("Could not find item slot binder entry, $ref")
        val currentItem = player.inventory.getItem(slot) ?: ItemStack.empty()
        if (currentItem.isEmpty) {
            setItem(item(entry))
            return
        }
        val strategy = entry.replacementStrategy

        if (strategy == SlotReplacementStrategy.REPLACE) {
            resetItem = currentItem
            setItem(item(entry))
            return
        }

        if (strategy == SlotReplacementStrategy.MOVE_OR_DROP || strategy == SlotReplacementStrategy.MOVE_OR_REPLACE) {
            val emptySlot = player.inventory.firstEmpty()
            if (emptySlot >= 0) {
                player.inventory.setItem(emptySlot, currentItem)
                setItem(item(entry))
                return
            }

            // Is there a similar item where we can add the current item?
            val item = player.inventory
                .asSequence()
                .mapIndexed { index, itemStack -> index to itemStack }
                .filter { (slot, _) -> slot != this.slot }
                .filter { (_, itemStack) -> currentItem.isSimilar(itemStack) }
                .firstOrNull { (_, itemStack) -> itemStack.maxStackSize >= currentItem.amount + itemStack.amount }

            if (item != null) {
                val (index, itemStack) = item
                player.inventory.setItem(index, itemStack.clone().apply {
                    amount = itemStack.amount + currentItem.amount
                })
                setItem(item(entry))
                return
            }

            // The inventory is full
            when (strategy) {
                SlotReplacementStrategy.MOVE_OR_DROP -> {
                    player.sendMessage("<red>Some items got dropped because the inventory is full.".asMini())
                    // TODO: Make the player drop the item possible from 1.21.4 onwards
                    player.world.dropItem(player.location, currentItem)
                }

                SlotReplacementStrategy.MOVE_OR_REPLACE -> resetItem = currentItem
                else -> throw IllegalStateException("Impossible to reach this point")
            }
            setItem(item(entry))
        }
    }


    @JvmName("itemNullable")
    private fun item(entry: ItemSlotBinderAudienceEntry? = null): ItemStack? {
        var e = entry
        if (entry == null) {
            e = ref.get() ?: return null
        }
        return item(e!!)
    }

    private fun item(entry: ItemSlotBinderAudienceEntry): ItemStack {
        val item = entry.item.get(player)
        val itemStack = item.build(player)
        return itemStack
    }

    private fun setItem(itemStack: ItemStack) {
        lastItem = itemStack
        player.inventory.setItem(slot, itemStack)
    }

    override fun tick() {
        super.tick()

        val itemStack = item(ref.get()) ?: return
        if (itemStack.isSimilar(lastItem)) {
            return
        }
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onItemClick(event: InventoryClickEvent) {
        if (event.whoClicked.uniqueId != player.uniqueId) return
        if (event.clickedInventory != player.inventory) return
        if (event.slot != slot) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onItemDrop(event: PlayerDropItemEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        if (event.itemDrop.itemStack.isSimilar(item()))
            event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    fun onItemSwap(event: PlayerSwapHandItemsEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        if (slot == OFFHAND_SLOT)
            event.isCancelled = true
        if (event.player.inventory.heldItemSlot == slot)
            event.isCancelled = true
    }

    override fun tearDown() {
        super.tearDown()
        player.inventory.setItem(slot, resetItem)
        resetItem = ItemStack.empty()
    }

    override fun dispose() {
        super.dispose()
        unregister()
    }
}