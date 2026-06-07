package com.typewritermc.entity.entries.event

import com.github.retrooper.packetevents.protocol.player.InteractionHand
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientInteractEntity.InteractAction
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.interaction.GlobalContextKey
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EntityDefinitionEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.startDialogueWithOrNextDialogue
import com.typewritermc.engine.paper.events.AsyncEntityDefinitionInteract

@Entry(
    "entity_interact_event",
    "When the player clicks on an entity",
    Colors.YELLOW,
    "fa6-solid:people-robbery"
)
/**
 * The `EntityInteractEvent` entry is an event triggered when a player interacts with a specific entity.
 *
 * ## How could this be used?
 * This could be used to start dialogue when a player interacts with an entity.
 */
class EntityInteractEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val definition: Ref<EntityDefinitionEntry> = emptyRef(),
    val shiftType: ShiftType = ShiftType.ANY,
    val interactionType: InteractionType = InteractionType.ALL,
) : EventEntry

enum class ShiftType {
    ANY,
    SHIFT,
    NO_SHIFT;

    fun isApplicable(isSneaking: Boolean): Boolean {
        return when (this) {
            ANY -> true
            SHIFT -> isSneaking
            NO_SHIFT -> !isSneaking
        }
    }
}

enum class InteractionType(private vararg val actions: InteractAction) {
    ALL(InteractAction.INTERACT_AT, InteractAction.ATTACK),
    LEFT_CLICK(InteractAction.ATTACK),
    RIGHT_CLICK(InteractAction.INTERACT_AT);

    fun isApplicable(action: InteractAction): Boolean {
        return actions.contains(action)
    }
}


@EntryListener(EntityInteractEventEntry::class)
fun onEntityInteract(event: AsyncEntityDefinitionInteract, query: Query<EntityInteractEventEntry>) {
    if (event.hand != InteractionHand.MAIN_HAND || event.action == InteractAction.INTERACT) return
    val definition = event.definition.ref()

    query.findWhere {
        if (!it.shiftType.isApplicable(event.shift)) return@findWhere false
        if (!it.interactionType.isApplicable(event.action)) return@findWhere false

        it.definition == definition
    }.startDialogueWithOrNextDialogue(event.player, context {
        val instance = event.instance
        InteractingEntityInstance withValue instance.ref()
    })
}

object InteractingEntityInstance : GlobalContextKey<Ref<*>>(Ref::class)
