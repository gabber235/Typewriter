package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.dialogue.isInDialogue
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.AudienceFilterEntry
import com.typewritermc.engine.paper.entry.entries.Invertible
import com.typewritermc.engine.paper.events.AsyncDialogueEndEvent
import com.typewritermc.engine.paper.events.AsyncDialogueStartEvent
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler

@Entry(
    "dialogue_audience",
    "Filters an audience based on if they are in a dialogue",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:chat-processing"
)
/**
 * The `Dialogue Audience` entry filters an audience based on if they are in a dialogue.
 *
 * ## How could this be used?
 * This could be used to hide the sidebar or boss bar when a player is in a dialogue.
 */
class DialogueAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    override val inverted: Boolean = false
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter = DialogueAudienceFilter(
        ref(),
    )
}

class DialogueAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
) : AudienceFilter(ref) {
    override fun filter(player: Player): Boolean {
        return player.isInDialogue
    }

    @EventHandler
    fun onDialogueStart(event: AsyncDialogueStartEvent) {
        event.player.updateFilter(true)
    }

    @EventHandler
    fun onDialogueEnd(event: AsyncDialogueEndEvent) {
        event.player.updateFilter(false)
    }
}