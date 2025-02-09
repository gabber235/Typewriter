package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.CancelableEventEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.shouldCancel
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.engine.paper.utils.toPosition
import org.bukkit.event.player.PlayerInteractEvent
import java.util.*

@Entry("interact_event_entry", "triggers when a player clicks", Colors.YELLOW, "hugeicons:touch-interaction-02")
class InteractEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val location: Optional<Var<Position>> = Optional.empty(),
    @Help("The item the player must be holding when the block is interacted with.")
    val itemInHand: Var<Item> = ConstVar(Item.Empty),
    @Help("The hand the player must be holding the item in")
    val hand: HoldingHand = HoldingHand.BOTH,
    override val cancel: Var<Boolean> = ConstVar(false),
    val interactionType: InteractionType = InteractionType.ALL,
    val shiftType: ShiftType = ShiftType.ANY,
) : CancelableEventEntry

@EntryListener(InteractEventEntry::class)
fun onInteract(event: PlayerInteractEvent, query: Query<InteractEventEntry>) {
    val player = event.player
    val block = event.clickedBlock
    val location = block?.location ?: player.location
    // The even triggers twice. Both for the main hand and offhand.
    // We only want to trigger once.
    if (event.hand == org.bukkit.inventory.EquipmentSlot.OFF_HAND) return // Disable off-hand interactions
    val entries = query.findWhere { entry ->
        // Check if the player is sneaking
        if (!entry.shiftType.isApplicable(player)) return@findWhere false

        // Check if the player is interacting with the block in the correct way
        if (!entry.interactionType.actions.contains(event.action)) return@findWhere false

        // Check if the player clicked on the correct location
        if (!entry.location.map { it.get(player).sameBlock(location.toPosition()) }
                .orElse(true)) return@findWhere false

        // Check if the player is holding the correct item
        if (!hasItemInHand(player, entry.hand, entry.itemInHand.get(player))) return@findWhere false

        true
    }.toList()
    if (entries.isEmpty()) return
    entries.triggerAllFor(player, context())
    if (entries.shouldCancel(player)) event.isCancelled = true
}