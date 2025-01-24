package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.ContextKeys
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.KeyType
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.engine.paper.utils.item.toItem
import org.bukkit.entity.Player
import org.bukkit.event.entity.EntityDropItemEvent
import java.util.*
import kotlin.reflect.KClass

@Entry("on_item_drop", "When the player drops an item", Colors.YELLOW, "mage:box-3d-minus-fill")
@ContextKeys(DropItemContextKeys::class)
/**
 * The `Drop Item Event` is triggered when the player drops an item.
 *
 * ## How could this be used?
 *
 * This event could be used to trigger a quest or to trigger a cutscene, when the player drops a specific item.
 */
class DropItemEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val item: Optional<Var<Item>> = Optional.empty(),
    @Help(
        """
        Cancel the event when triggered.
        It will only cancel the event if all the criteria are met.
        If set to false, it will not modify the event.
        """
    )
    val cancel: Var<Boolean> = ConstVar(false),
) : EventEntry

enum class DropItemContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Item::class)
    ITEM(Item::class),
}

@EntryListener(DropItemEventEntry::class)
fun onDropItem(event: EntityDropItemEvent, query: Query<DropItemEventEntry>) {
    if (event.entity !is Player) return

    val player = event.entity as Player

    val entries = query.findWhere { entry ->
        if (entry.item.isPresent && !entry.item.get().get(player)
                .isSameAs(player, event.itemDrop.itemStack, context())
        ) return@findWhere false
        true
    }.toList()
    entries.startDialogueWithOrNextDialogue(player) {
        DropItemContextKeys.ITEM += event.itemDrop.itemStack.toItem()
    }
    if (entries.any { it.cancel.get(player) }) event.isCancelled = true
}