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
import org.bukkit.entity.Player
import org.bukkit.event.inventory.CraftItemEvent
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

@EntryListener(CraftItemEventEntry::class)
fun onCraftItem(event: CraftItemEvent, query: Query<CraftItemEventEntry>) {
    val player = event.whoClicked
    if (player !is Player) return

    query.findWhere { it.craftedItem.get(player).isSameAs(player, event.recipe.result, context()) }
        .triggerAllFor(player) {
            CraftItemContextKeys.CRAFTED_ITEM += event.recipe.result
            CraftItemContextKeys.CRAFTED_AMOUNT += event.recipe.result.amount
        }
}