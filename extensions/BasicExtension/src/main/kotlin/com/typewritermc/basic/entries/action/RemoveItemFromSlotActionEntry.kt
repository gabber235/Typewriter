package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.item.Item
import kotlinx.coroutines.Dispatchers
import lirand.api.extensions.inventory.get
import lirand.api.extensions.inventory.set
import org.bukkit.inventory.ItemStack
import java.util.*

@Entry(
    "remove_item_from_slot",
    "Remove an item from a specific slot in the players inventory",
    Colors.RED,
    "icomoon-free:user-minus"
)
/**
 * The `Remove Item From Slot Action` is an action that removes an item from a specific slot in the player's inventory.
 * This action provides you with the ability to remove items from specific slots in the player's inventory in response to specific events.
 * <Admonition type="caution">
 *     This action will try to remove "as much as possible" but does not verify if the player has enough items in their inventory.
 *     If you want to guarantee that the player has enough items in their inventory, add an
 *     <Link to='../fact/inventory_item_count_fact'>Inventory Item Count Fact</Link> to the criteria.
 * </Admonition>
 *
 * ## How could this be used?
 * This can be used when `giving` an NPC an item, and you want to remove the item from a specific slot in the player's inventory.
 * Or when you want to remove a key from a specific slot in the player's inventory after they use it to unlock a door.
 */
class RemoveItemFromSlotActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val slot: Var<Int> = ConstVar(0),
    @Help("If not specified, any item will be removed from the slot")
    val item: Optional<Var<Item>> = Optional.empty(),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        Dispatchers.Sync.launch {
            val slot = slot.get(player, context)
            if (item.isPresent) {
                val item = item.get().get(player, context)
                val current = player.inventory[slot] ?: return@launch
                if (!item.isSameAs(player, current, context)) {
                    return@launch
                }
                val itemStack = item.build(player, context)
                val remaining = (current.amount - itemStack.amount).coerceAtLeast(0)
                if (remaining == 0) {
                    player.inventory[slot] = ItemStack.empty()
                } else {
                    player.inventory[slot] = itemStack.clone().apply { amount = remaining }
                }
            } else {
                player.inventory[slot] = ItemStack.empty()
            }
        }
    }
}