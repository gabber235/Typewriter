package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
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

@Entry("set_item", "Set an item in a specific slot", Colors.RED, "fluent:tray-item-add-24-filled")
/**
 * The `Set Item Action` is an action that sets an item in a specific slot in the player's inventory.
 *
 * ## How could this be used?
 *
 * This can be used to equip a player with an elytra, or give them a weapon.
 */
class SetItemActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val item: Var<Item> = ConstVar(Item.Empty),
    val slot: Var<Int> = ConstVar(0),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        Dispatchers.Sync.launch {
            player.inventory.setItem(slot.get(player, context), item.get(player, context).build(player, context))
        }
    }
}