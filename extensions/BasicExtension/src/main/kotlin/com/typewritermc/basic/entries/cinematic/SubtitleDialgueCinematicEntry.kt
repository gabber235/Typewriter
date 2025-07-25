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
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import com.typewritermc.engine.paper.utils.splitPercentage
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import net.kyori.adventure.title.Title
import net.kyori.adventure.title.Title.Times
import org.bukkit.entity.Player
import java.time.Duration

@Entry("subtitle_dialogue_cinematic", "Show an subtitle message", Colors.CYAN, "fa6-solid:diagram-next")
/**
 * The `Subtitle Dialogue Cinematic Entry` is a cinematic entry that displays an animated subtitle message.
 * The speaker is displayed in the action bar, and the dialogue is displayed in the subtitle.
 *
 * ## How could this be used?
 *
 * This could be used to display a dialogue between two characters, where the speaker is displayed in the action bar, and the dialogue is displayed in the subtitle.
 */
class SubtitleDialogueCinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    val speaker: Ref<SpeakerEntry> = emptyRef(),
    @Segments(icon = "fa6-solid:diagram-next")
    val segments: List<SingleLineDisplayDialogueSegment> = emptyList(),
) : CinematicEntry {

    override fun create(player: Player): CinematicAction {
        return DisplayDialogueCinematicAction(
            player,
            speaker.get(),
            segments,
            subtitlePercentage,
            reset = {
                val emptyActionBar = Component.empty()
                player.acceptActionBarMessage(emptyActionBar)
                sendActionBar(emptyActionBar)
                player.clearTitle()
            },
            display = ::displaySubTitle
        )
    }
}

val subtitleFormat: String by snippet(
    "cinematic.dialogue.subtitle.format",
    "<white><message>"
)
val subtitleSpeakerFormat: String by snippet(
    "cinematic.dialogue.subtitle.speaker.format",
    "<gray>[ <reset><bold><speaker></bold><reset><gray> ]"
)
val subtitlePercentage: Double by snippet(
    "cinematic.dialogue.subtitle.percentage",
    0.4
)

private val times = Times.times(Duration.ZERO, Duration.ofDays(1), Duration.ZERO)

private fun displaySubTitle(player: Player, speakerName: String, text: String, displayPercentage: Double) {
    val message = text.asMini()
        .splitPercentage(displayPercentage)

    val component = subtitleFormat.asMiniWithResolvers(
        Placeholder.component("message", message),
    )

    val actionBarComponent = subtitleSpeakerFormat.asMiniWithResolvers(
        Placeholder.parsed("speaker", speakerName),
    )

    player.showTitle(Title.title(Component.empty(), component, times))
    player.acceptActionBarMessage(actionBarComponent)
    player.sendActionBar(actionBarComponent)
}