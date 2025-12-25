package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.ContextKeys
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.KeyType
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.item.CustomItem
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.engine.paper.utils.item.SerializedItem
import com.typewritermc.engine.paper.utils.item.components.ItemAmountComponent
import kotlinx.coroutines.Dispatchers
import kotlin.reflect.KClass

@Entry("remove_item", "Remove an item from the players inventory", Colors.RED, "icomoon-free:user-minus")
@ContextKeys(RemoveItemContextKeys::class)
/**
 * The `Remove Item Action` is an action that removes an item from the player's inventory.
 * This action provides you with the ability to remove items from the player's inventory in response to specific events.
 * <Admonition type="caution">
 *     This action will try to remove "as much as possible" but does not verify if the player has enough items in their inventory.
 *     If you want to guarantee that the player has enough items in their inventory, add an
 *     <Link to='../fact/inventory_item_count_fact'>Inventory Item Count Fact</Link> to the criteria.
 * </Admonition>
 *
 * ## How could this be used?
 *
 * This can be used when `giving` an NPC an item, and you want to remove the item from the player's inventory.
 * Or when you want to remove a key from the player's inventory after they use it to unlock a door.
 */
class RemoveItemActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val item: Var<Item> = ConstVar(Item.Empty),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        Dispatchers.Sync.launch {
            val item = item.get(player, context)
            var removedAmount = 0
            var remainingAmount = 0

            when (item) {
                is SerializedItem -> {
                    val itemStack = item.build(player, context).clone()
                    val totalToRemove = itemStack.amount
                    val result = player.inventory.removeItemAnySlot(itemStack)
                    remainingAmount = result.values.sumOf { it.amount }
                    removedAmount = totalToRemove - remainingAmount
                }

                is CustomItem -> {
                    val amountComponents = item.components<ItemAmountComponent>()
                    val totalToRemove = if (amountComponents.isNotEmpty()) amountComponents.sumOf {
                        it.amount.get(
                            player,
                            context
                        )
                    } else Int.MAX_VALUE
                    var amountLeft = totalToRemove
                    val content = player.inventory.contents
                    val maxSlot = content.size

                    for (i in 0 until maxSlot) {
                        val slotItem = content[i] ?: continue
                        if (!item.isSameAs(player, slotItem, context)) {
                            continue
                        }
                        val slotAmount = slotItem.amount
                        if (slotAmount <= amountLeft) {
                            player.inventory.clear(i)
                            amountLeft -= slotAmount
                        } else {
                            slotItem.amount = slotAmount - amountLeft
                            player.inventory.setItem(i, slotItem)
                            amountLeft = 0
                        }

                        if (amountLeft == 0) {
                            break
                        }
                    }
                    removedAmount = totalToRemove - amountLeft
                    remainingAmount = amountLeft
                }
            }

            context[RemoveItemContextKeys.REMOVED_AMOUNT] = removedAmount
            context[RemoveItemContextKeys.REMAINING_AMOUNT] = remainingAmount
        }
    }
}

enum class RemoveItemContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Int::class)
    REMOVED_AMOUNT(Int::class),

    @KeyType(Int::class)
    REMAINING_AMOUNT(Int::class)
}