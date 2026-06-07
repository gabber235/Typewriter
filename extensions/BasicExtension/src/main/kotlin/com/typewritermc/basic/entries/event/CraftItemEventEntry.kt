package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.ContextKeys
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.extension.annotations.KeyType
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.engine.paper.utils.item.Item
import org.bukkit.Bukkit
import org.bukkit.entity.Player
import org.bukkit.event.inventory.CraftItemEvent
import org.bukkit.inventory.ItemStack
import kotlin.math.min
import kotlin.reflect.KClass

@Entry("craft_item_event", "Called when a player crafts an item", Colors.YELLOW, "mdi:hammer-wrench")
@ContextKeys(CraftItemContextKeys::class)
/**
 * The `Craft Item Event` is triggered when a player crafts an item.
 * This can be from a crafting table, a furnace, smiting table, campfire, or any other crafting method.
 *
 * ## How could this be used?
 * This could be used to complete a quest where the player has to craft a certain item, or to give the player a reward when they craft a certain item.
 */
class CraftItemEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val craftedItem: Var<Item> = ConstVar(Item.Empty),
) : EventEntry

enum class CraftItemContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Item::class)
    CRAFTED_ITEM(Item::class),

    @KeyType(Int::class)
    CRAFTED_AMOUNT(Int::class),
}

// TODO: Use ItemCraftedEvent when we support version dependent listener registration.
@EntryListener(CraftItemEventEntry::class)
fun onCraftItem(event: CraftItemEvent, query: Query<CraftItemEventEntry>) {
    val player = event.whoClicked
    if (player !is Player) return

    val entries =
        query.findWhere { it.craftedItem.get(player).isSameAs(player, event.recipe.result, context()) }.toList()

    if (entries.isEmpty()) return
    val craftedAmount = computeCraftedAmount(event, player)

    entries.triggerAllFor(player) {
        CraftItemContextKeys.CRAFTED_ITEM += event.recipe.result
        CraftItemContextKeys.CRAFTED_AMOUNT += craftedAmount
    }
}

/**
 * Because the CraftItemEvent doesn't do a calculation when shift clicking for the total amount of items crafted,
 * we have to simulate this ourselves.
 *
 * This has been fixed for 1.21.11+ with the new [ItemCraftedEvent] but because we still support 1.21.3-10,
 * we cant use it without version dependent listener registration.
 */
private fun computeCraftedAmount(event: CraftItemEvent, player: Player): Int {
    val recipeResult = event.recipe.result
    if (!event.isShiftClick) return recipeResult.amount

    val targetResult = recipeResult.clone()
    if (targetResult.isEmptyStack()) return 0

    var matrix = normalizeCraftingMatrix(event.inventory.matrix)
    val simulatedInventory = QuickMoveCraftDestination.from(player)

    var craftedAmount = 0
    while (true) {
        val craftResult = Bukkit.getServer().craftItemResult(matrix, player.world, player)
        val produced = craftResult.result

        if (produced.isEmptyStack()) break
        if (!produced.isSimilar(targetResult)) break
        if (!simulatedInventory.moveItemStackTo(produced.clone(), backwards = true)) break

        craftedAmount += produced.amount
        matrix = normalizeCraftingMatrix(craftResult.resultingMatrix)
    }

    return craftedAmount
}

private fun normalizeCraftingMatrix(matrix: Array<out ItemStack?>): Array<ItemStack> {
    if (matrix.size == 9) {
        return Array(9) { index -> matrix[index]?.clone() ?: ItemStack.empty() }
    }

    val normalized = Array(9) { ItemStack.empty() }
    if (matrix.size == 4) {
        normalized[0] = matrix[0]?.clone() ?: ItemStack.empty()
        normalized[1] = matrix[1]?.clone() ?: ItemStack.empty()
        normalized[3] = matrix[2]?.clone() ?: ItemStack.empty()
        normalized[4] = matrix[3]?.clone() ?: ItemStack.empty()
    }

    return normalized
}

private fun ItemStack.isEmptyStack(): Boolean = type.isAir || amount <= 0

private class QuickMoveCraftDestination(
    private val slots: MutableList<ItemStack>,
) {

    fun moveItemStackTo(stack: ItemStack, backwards: Boolean): Boolean {
        var changed = false
        val iteration = if (backwards) slots.indices.reversed() else slots.indices

        if (stack.maxStackSize > 1) {
            for (index in iteration) {
                if (stack.isEmptyStack()) break

                val target = slots[index]
                if (target.isEmptyStack()) continue
                if (!target.isSimilar(stack)) continue

                val maxStackSize = target.maxStackSize
                if (target.amount >= maxStackSize) continue

                val transferAmount = min(stack.amount, maxStackSize - target.amount)
                if (transferAmount <= 0) continue

                target.amount += transferAmount
                stack.amount -= transferAmount
                changed = true
            }
        }

        if (!stack.isEmptyStack()) {
            for (index in iteration) {
                val target = slots[index]
                if (!target.isEmptyStack()) continue

                val transferAmount = min(stack.amount, stack.maxStackSize)
                val placed = stack.clone()
                placed.amount = transferAmount
                slots[index] = placed
                stack.amount -= transferAmount
                changed = true
                break
            }
        }

        return changed
    }

    companion object {
        fun from(player: Player): QuickMoveCraftDestination {
            val storageContents = player.inventory.storageContents
            val slots = MutableList(36) { ItemStack.empty() }

            for (menuSlot in 0 until 36) {
                val storageSlot = if (menuSlot < 27) menuSlot + 9 else menuSlot - 27
                slots[menuSlot] = storageContents.getOrNull(storageSlot)?.clone() ?: ItemStack.empty()
            }

            return QuickMoveCraftDestination(slots)
        }
    }
}
