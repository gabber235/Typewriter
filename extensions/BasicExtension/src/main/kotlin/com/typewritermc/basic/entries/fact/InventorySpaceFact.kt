package com.typewritermc.basic.entries.fact

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.GroupEntry
import com.typewritermc.engine.paper.entry.entries.ReadableFactEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.facts.FactData
import com.typewritermc.engine.paper.utils.item.Item
import org.bukkit.entity.Player
import java.util.*

@Entry(
    "inventory_space_fact",
    "Check how many items a player can receive",
    Colors.PURPLE,
    "fa6-solid:box-open"
)
/**
 * The `Inventory Space Fact` calculates how many items a player can receive in their inventory.
 * If an item is specified, it checks stackable space for that specific item type.
 *
 * <fields.ReadonlyFactInfo />
 *
 * ## How could this be used?
 * Check if a player has enough space before giving them items.
 * Verify inventory capacity before giving the player their reward.
 */
class InventorySpaceFact(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
    @Help("If specified, checks space for this specific item type")
    val item: Optional<Var<Item>> = Optional.empty(),
) : ReadableFactEntry {
    override fun readSinglePlayer(player: Player): FactData {
        if (item.isEmpty) {
            return FactData(player.inventory.contents.count { it == null || it.isEmpty } * 64)
        }
        val targetItem = item.get().get(player)
        val prototype = targetItem.build(player)
        val maxStack = prototype.maxStackSize

        return FactData(
            player.inventory.contents.sumOf { slot ->
                when {
                    slot == null -> maxStack
                    slot.isEmpty -> maxStack
                    targetItem.isSameAs(player, slot) -> maxStack - slot.amount
                    else -> 0
                }
            }
        )
    }
}