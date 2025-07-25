package com.typewritermc.basic.entries.cinematic

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Segments
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.CinematicAction
import com.typewritermc.engine.paper.entry.entries.CinematicEntry
import com.typewritermc.engine.paper.entry.entries.SpeakerEntry
import com.typewritermc.engine.paper.interaction.acceptActionBarMessage
import com.typewritermc.engine.paper.interaction.chatHistory
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import com.typewritermc.engine.paper.utils.asPartialFormattedMini
import com.typewritermc.engine.paper.utils.isFloodgate
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player

@Entry("spoken_dialogue_cinematic", "Play a spoken dialogue cinematic", Colors.CYAN, "mingcute:message-4-fill")
/**
 * The `Spoken Dialogue Cinematic` is a cinematic that displays an animated message in chat.
 *
 * ## How could this be used?
 *
 * When a NPC is talking to the player, this can be used to display the NPC's dialogue.
 */
class SpokenDialogueCinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    val speaker: Ref<SpeakerEntry> = emptyRef(),
    @Segments(icon = "mingcute:message-4-fill")
    val segments: List<MultiLineDisplayDialogueSegment> = emptyList(),
) : CinematicEntry {
    override fun create(player: Player): CinematicAction {
        return DisplayDialogueCinematicAction(
            player,
            speaker.get(),
            segments,
            spokenPercentage,
            setup = {},
            reset = { chatHistory.resendMessages(this) },
            display = ::displaySpokenDialogue,
        )
    }
}

val spokenFormat: String by snippet(
    "cinematic.dialogue.spoken.format",
    """
		|<gray><st>${" ".repeat(60)}</st>
		|
		|<gray><padding>[ <bold><speaker></bold><reset><gray> ]
		|
		|<message>
		|
		|<gray><st>${" ".repeat(60)}</st>
		""".trimMargin()
)

val spokenPadding: String by snippet("cinematic.dialogue.spoken.padding", "    ")
val spokenMinLines: Int by snippet("cinematic.dialogue.spoken.minLines", 4)
val spokenMaxLineLength: Int by snippet("cinematic.dialogue.spoken.maxLineLength", 40)
val spokenPercentage: Double by snippet("cinematic.dialogue.spoken.percentage", 0.5)

private fun displaySpokenDialogue(player: Player, speakerName: String, text: String, displayPercentage: Double) {

    val message = text.asPartialFormattedMini(
        displayPercentage,
        padding = spokenPadding,
        minLines = spokenMinLines,
        maxLineLength = spokenMaxLineLength,
    )

    val component = spokenFormat.asMiniWithResolvers(
        Placeholder.parsed("speaker", speakerName),
        Placeholder.component("message", message),
        Placeholder.parsed("padding", spokenPadding),
    )

    // Bedrock clients don't like chat animations, but they can have multiline actionbars.
    if (player.isFloodgate) {
        player.acceptActionBarMessage(component)
        player.sendActionBar(component)
        return
    }

    val componentWithDarkMessages = player.chatHistory.composeDarkMessage(component)
    player.sendMessage(componentWithDarkMessages)
}