package com.typewritermc.basic.entries.cinematic

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Segments
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.CinematicAction
import com.typewritermc.engine.paper.entry.entries.CinematicEntry
import com.typewritermc.engine.paper.entry.entries.PrimaryCinematicEntry
import com.typewritermc.engine.paper.entry.entries.SpeakerEntry
import com.typewritermc.engine.paper.interaction.acceptActionBarMessage
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.*
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player

@Entry("actionbar_dialogue_cinematic", "Show an action bar typed dialogue", Colors.CYAN, "fa6-solid:xmarks-lines")
/**
 * The `Action Bar Dialogue Cinematic` is a cinematic that shows a dialogue in the action bar.
 * You can specify the speaker and the dialogue.
 *
 * ## How could this be used?
 *
 * This cinematic is useful to display dialogue in combination with a camera path.
 * As the dialogue is displayed in the action bar, the player can still move around and look at the camera path.
 */
class ActionBarDialogueCinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    val speaker: Ref<SpeakerEntry> = emptyRef(),
    @Segments(icon = "fa6-solid:xmarks-lines")
    val segments: List<SingleLineDisplayDialogueSegment> = emptyList(),
) : PrimaryCinematicEntry {
    override fun create(player: Player): CinematicAction {
        return DisplayDialogueCinematicAction(
            player,
            speaker.get(),
            segments,
            actionBarPercentage,
            reset = { sendActionBar(Component.empty()) },
            display = ::displayActionBar,
        )
    }
}

@Deprecated("Use RandomVariable entry with a normal ActionBarDialogue instead")
@Entry(
    "random_actionbar_dialogue_cinematic",
    "Show a random action bar typed dialogue",
    Colors.CYAN,
    "fa6-solid:xmarks-lines"
)
class RandomActionBarDialogueCinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    val speaker: Ref<SpeakerEntry> = emptyRef(),
    @Segments(icon = "fa6-solid:xmarks-lines")
    val segments: List<SingleLineRandomDisplayDialogueSegment> = emptyList(),
) : CinematicEntry {
    override fun create(player: Player): CinematicAction {
        return DisplayDialogueCinematicAction(
            player,
            speaker.get(),
            segments.toDisplaySegments(),
            actionBarPercentage,
            reset = {
                val message = Component.empty()
                acceptActionBarMessage(message)
                sendActionBar(message)
            },
            display = ::displayActionBar,
        )
    }
}


private val actionBarFormat: String by snippet(
    "cinematic.dialogue.actionbar.format",
    "<bold><speaker></bold><reset><gray>: <white><message><padding>"
)
private val actionBarPercentage: Double by snippet(
    "cinematic.dialogue.actionbar.percentage",
    0.4
)

private fun displayActionBar(player: Player, speakerName: String, text: String, displayPercentage: Double) {
    val message = text.asMini()
        .splitPercentage(displayPercentage)

    // Find out how much padding is needed to fill the rest of the action bar.
    // As the action bar is centered, adding padding to the end of the message
    // will make the message appear stationary.
    val paddingSize = text.stripped().length - message.plainText().length
    val padding = " ".repeat(paddingSize)

    val component = actionBarFormat.asMiniWithResolvers(
        Placeholder.parsed("speaker", speakerName),
        Placeholder.component("message", message),
        Placeholder.unparsed("padding", padding),
    )

    player.acceptActionBarMessage(component)
    player.sendActionBar(component)
}
