package com.typewritermc.citizens.entries.event

import com.typewritermc.citizens.entries.entity.ReferenceNpcEntry
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.startDialogueWithOrNextDialogue
import net.citizensnpcs.api.event.NPCLeftClickEvent
import net.citizensnpcs.api.event.NPCRightClickEvent
import org.bukkit.entity.Player

@Entry("on_npc_interact", "When a player clicks on an NPC", Colors.YELLOW, "fa6-solid:people-robbery")
/**
 * The `NPC Interact Event` is fired when a player interacts with an NPC.
 *
 * ## How could this be used?
 *
 * This can be used to create a variety of interactions that can occur between an NPC and a player. For example, you could create an NPC that gives the player an item when they interact with it.
 */
class NpcInteractEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("The identifier of the NPC.")
    // The NPC that needs to be interacted with.
    val identifier: Ref<ReferenceNpcEntry> = emptyRef(),
) : EventEntry

private fun onReferenceNpcInteract(player: Player, npcId: Int, query: Query<NpcInteractEventEntry>) {
    val references: Sequence<ReferenceNpcEntry> = Query findWhere { it.npcId == npcId }
    val identifiers = references.map { it.id }.toList()

    query.findWhere {
        it.identifier.id in identifiers
    }.startDialogueWithOrNextDialogue(player, context())
}

@EntryListener(NpcInteractEventEntry::class)
fun onNpcRightClick(event: NPCRightClickEvent, query: Query<NpcInteractEventEntry>) =
    onReferenceNpcInteract(event.clicker, event.npc.id, query)

@EntryListener(NpcInteractEventEntry::class)
fun onNpcLeftClick(event: NPCLeftClickEvent, query: Query<NpcInteractEventEntry>) =
    onReferenceNpcInteract(event.clicker, event.npc.id, query)