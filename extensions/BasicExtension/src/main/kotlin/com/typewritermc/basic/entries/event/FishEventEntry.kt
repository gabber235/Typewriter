package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.LabelKey
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.engine.paper.utils.item.Item
import org.bukkit.event.player.PlayerFishEvent

@Entry("on_fish", "When the a player caught a fish or an item", Colors.YELLOW, "mdi:fish")
/**
 * The `Player Fish Event` is triggered when a player catches a fish or an item.
 *
 * ## How could this be used?
 * You can create custom fishing mechanics, such as catching a specific item when fishing in a specific location.
 */
class FishEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @LabelKey("basic.fish_event.fields.itemInHand.label")
    @Help(key = "basic.fish_event.fields.itemInHand.help")
    val itemInHand: Var<Item> = ConstVar(Item.Empty),
    @LabelKey("basic.fish_event.fields.hand.label")
    @Help(key = "basic.fish_event.fields.hand.help")
    val hand: HoldingHand = HoldingHand.BOTH,
    val caught: Var<Item> = ConstVar(Item.Empty),
) : EventEntry

@EntryListener(FishEventEntry::class)
fun onPlayerFish(event: PlayerFishEvent, query: Query<FishEventEntry>) {
    if (event.state != PlayerFishEvent.State.CAUGHT_FISH) return
    val player = event.player

    query.findWhere { entry ->
        // Check if the player is holding the correct item
        if (!hasItemInHand(player, entry.hand, entry.itemInHand.get(player))) return@findWhere false

        // Check if the player caught the correct item
        val caughtItem = event.caught as? org.bukkit.entity.Item ?: return@findWhere false
        return@findWhere entry.caught.get(player).isSameAs(player, caughtItem.itemStack)
    }.triggerAllFor(event.player, context())
}