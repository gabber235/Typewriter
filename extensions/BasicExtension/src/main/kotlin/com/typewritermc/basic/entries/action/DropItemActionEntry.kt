package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.engine.paper.utils.toBukkitLocation
import kotlinx.coroutines.Dispatchers
import java.util.*

@Entry("drop_item", "Drop an item at location, or on player", Colors.RED, "fa-brands:dropbox")
/**
 * The `Drop Item Action` is an action that drops an item in the world.
 * This action provides you with the ability to drop an item with a specified Minecraft material, amount, display name, lore, and location.
 *
 * ## How could this be used?
 *
 * This action can be useful in a variety of situations.
 * You can use it to create treasure chests with randomized items, drop loot from defeated enemies, or spawn custom items in the world.
 * The possibilities are endless!
 */
class DropItemActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val item: Var<Item> = ConstVar(Item.Empty),
    @Help("The location to drop the item. (Defaults to the player's location)")
    private val location: Optional<Var<Position>> = Optional.empty(),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        val location = if (location.isPresent) {
            location.get().get(player, context).toBukkitLocation()
        } else {
            player.location
        }
        val item = item.get(player, context).build(player, context)
        // Run on main thread
        Dispatchers.Sync.launch {
            location.world.dropItem(location, item)
        }
    }
}