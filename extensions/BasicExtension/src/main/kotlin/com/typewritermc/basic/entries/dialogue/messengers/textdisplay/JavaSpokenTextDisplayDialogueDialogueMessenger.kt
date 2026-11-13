package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.basic.entries.dialogue.SpokenTextDisplayDialogueEntry
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import org.bukkit.entity.Player

private val spokenTextDisplayFormat: String by snippet(
    "dialogue.textDisplay.spoken.bodyFormat",
    "<white> <message> </white>",
)
private val spokenTextDisplayInstruction: String by snippet(
    "dialogue.textDisplay.spoken.instruction",
    "<white><confirmation_key> to continue</white>",
)

internal class JavaSpokenTextDisplayDialogueDialogueMessenger(
    player: Player,
    context: InteractionContext,
    entry: SpokenTextDisplayDialogueEntry,
) : JavaTextDisplayDialogueMessenger<SpokenTextDisplayDialogueEntry>(
    player, context, entry, entry.text, entry.duration, entry.origin, entry.orientation,
    spokenTextDisplayFormat,
) {
    override fun prepareDisplay(display: TextDisplayDialogueDisplay) {
        display.setInstruction(spokenTextDisplayInstruction.asMiniWithResolvers(player))
    }
}
