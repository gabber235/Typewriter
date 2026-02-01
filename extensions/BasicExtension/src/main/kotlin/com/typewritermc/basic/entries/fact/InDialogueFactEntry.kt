package com.typewritermc.basic.entries.fact

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.dialogue.currentDialogue
import com.typewritermc.engine.paper.entry.dialogue.isInDialogue
import com.typewritermc.engine.paper.entry.entries.DialogueEntry
import com.typewritermc.engine.paper.entry.entries.GroupEntry
import com.typewritermc.engine.paper.entry.entries.ReadableFactEntry
import com.typewritermc.engine.paper.facts.FactData
import org.bukkit.entity.Player

@Entry("in_dialogue_fact", "If the player is in a dialogue", Colors.PURPLE, "bi:chat-square-quote-fill")
/**
 * The 'In Dialogue Fact' is a fact that returns 1 if the player has an active dialogue, and 0 if not.
 *
 * If no dialogue is referenced, it will filter based on if any dialogue is active.
 *
 * <fields.ReadonlyFactInfo />
 *
 * ## How could this be used?
 * With this fact, it is possible to make an entry only take action if the player does not have an active dialogue.
 */
class InDialogueFactEntry(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
    @Help("When not set, it will filter based on if any dialogue is active.")
    val dialogue: Ref<DialogueEntry> = emptyRef(),
) : ReadableFactEntry {
    override fun readSinglePlayer(player: Player): FactData {
        val inDialogue = if (dialogue.isSet) {
            val currentDialogue = player.currentDialogue
            currentDialogue != null && currentDialogue.id == dialogue.id
        } else {
            player.isInDialogue
        }

        return FactData(inDialogue.toInt())
    }
}
