package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.item.Item
import io.papermc.paper.event.player.PlayerPickItemEvent
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.inventory.*
import org.bukkit.event.player.PlayerDropItemEvent
import org.bukkit.event.player.PlayerItemHeldEvent

@Entry(
    "holding_item_audience",
    "Filters an audience based on if they are holding a specific item",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:hand"
)
/**
 * The `Holding Item Audience` entry is an audience filter that filters an audience based on if they are holding a specific item.
 * The audience will only contain players that are holding the specified item.
 *
 * ## How could this be used?
 * Could show a path stream to a location when the player is holding a map.
 */
class HoldingItemAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    @Help("The item to check for.")
    val item: Var<Item> = ConstVar(Item.Empty),
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible {
    override fun display(): AudienceFilter = HoldingItemAudienceFilter(ref(), item)
}

class HoldingItemAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    private val item: Var<Item>,
) : AudienceFilter(ref) {
    override fun filter(player: Player): Boolean {
        val holdingItem = player.inventory.itemInMainHand
        return item.get(player).isSameAs(player, holdingItem)
    }

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    fun onPlayerItemHeld(event: PlayerItemHeldEvent) {
        val player = event.player
        val newHoldingItem = player.inventory.getItem(event.newSlot)
        player.updateFilter(item.get(player).isSameAs(player, newHoldingItem))
    }

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    fun onInventoryClickEvent(event: InventoryClickEvent) = onInventoryEvent(event)

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    fun onInventoryDragEvent(event: InventoryDragEvent) = onInventoryEvent(event)

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    fun onInventoryOpenEvent(event: InventoryOpenEvent) = onInventoryEvent(event)

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    fun onInventoryCloseEvent(event: InventoryCloseEvent) = onInventoryEvent(event)

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    fun onInventoryEvent(event: InventoryEvent) {
        val player = event.view.player as? Player ?: return
        player.refresh()
    }

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    fun onPickupItem(event: PlayerPickItemEvent) = event.player.refresh()

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    fun onDropItem(event: PlayerDropItemEvent) = event.player.refresh()
}