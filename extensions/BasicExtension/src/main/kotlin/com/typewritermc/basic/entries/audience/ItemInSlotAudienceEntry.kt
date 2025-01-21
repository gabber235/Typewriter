package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.item.Item
import org.bukkit.entity.Player

@Entry(
    "item_in_slot_audience",
    "Filters an audience based on if they have a specific item in a specific slot",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:hand"
)
/**
 * The `Item In Slot Audience` entry filters an audience based on if they have a specific item in a specific slot.
 *
 * ## How could this be used?
 * It can be used to have magnet boots which allow players to move in certain areas.
 */
class ItemInSlotAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    @Help("The item to check for.")
    val item: Var<Item> = ConstVar(Item.Empty),
    @Help("The slot to check.")
    val slot: Var<Int> = ConstVar(0),
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter = ItemInSlotAudienceFilter(ref(), item, slot)
}

class ItemInSlotAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    private val item: Var<Item>,
    private val slot: Var<Int>,
) : AudienceFilter(ref), TickableDisplay {
    override fun filter(player: Player): Boolean {
        val itemInSlot = player.inventory.getItem(slot.get(player)) ?: return false
        return item.get(player).isSameAs(player, itemInSlot)
    }

    override fun tick() {
        consideredPlayers.forEach { it.refresh() }
    }
}