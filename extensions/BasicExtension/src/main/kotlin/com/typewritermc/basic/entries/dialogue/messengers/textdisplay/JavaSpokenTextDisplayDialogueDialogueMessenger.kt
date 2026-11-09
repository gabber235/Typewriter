package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.basic.entries.dialogue.SpokenTextDisplayDialogueEntry
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.dialogue.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.Confirmation
import com.typewritermc.engine.paper.interaction.awaitConfirmation
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import java.time.Duration

private val spokenTextDisplayFormat: String by snippet(
    "dialogue.textDisplay.spoken.bodyFormat",
    "<white> <message> </white>",
)
private val spokenTextDisplayInstruction: String by snippet(
    "dialogue.textDisplay.spoken.instruction",
    "<white><confirmation_key> to continue</white>",
)

class JavaSpokenTextDisplayDialogueDialogueMessenger(
    player: Player,
    context: InteractionContext,
    entry: SpokenTextDisplayDialogueEntry,
) : DialogueMessenger<SpokenTextDisplayDialogueEntry>(player, context, entry) {
    private var confirmation: Confirmation? = null
    private var display: TextDisplayDialogueDisplay? = null
    private lateinit var typewriter: TextDisplayTypewriter
    private var duration = Duration.ZERO
    private var typingDuration = Duration.ZERO
    private var playedTime = Duration.ZERO
    private var lastVisibleCharacters = -1

    override var animationComplete: Boolean
        get() = playedTime >= typingDuration
        set(value) {
            playedTime = if (value) typingDuration else Duration.ZERO
            lastVisibleCharacters = -1
        }

    override fun init() {
        super.init()
        val text = entry.text.get(player, context).parsePlaceholders(player)
        typewriter = TextDisplayTypewriter(text)
        duration = entry.duration.get(player, context)
        typingDuration = typingDurationType.totalDuration(typewriter.rawText, duration).coerceAtLeast(Duration.ZERO)

        confirmation = player.awaitConfirmation {
            if (state != MessengerState.RUNNING || display?.isClosing == true) return@awaitConfirmation
            if (animationComplete) display?.close()
            else animationComplete = true
        }
        display = TextDisplayDialogueDisplay(
            player,
            context,
            entry.origin,
            entry.orientation,
        ).also {
            it.setInstruction(spokenTextDisplayInstruction.asMiniWithResolvers(player))
            it.spawn(displayText(true)!!)
        }
    }

    override fun tick(context: TickContext) {
        if (state != MessengerState.RUNNING) return

        val text = if (display?.isClosing == true) null else {
            if (display?.ready == true) playedTime += context.deltaTime
            displayText()
        }

        display?.tick(context.deltaTime, text)
        if (display?.finished == true) state = MessengerState.FINISHED
    }

    override fun dispose() {
        super.dispose()
        confirmation?.dispose()
        confirmation = null
        display?.dispose()
        display = null
    }

    private fun displayText(force: Boolean = false): Component? {
        val percentage = if (typingDuration.toMillis() <= 0) {
            1.0
        } else {
            typingDurationType.calculatePercentage(playedTime, duration, typewriter.rawText)
        }
        val visibleCharacters = typewriter.visibleCharacters(percentage)
        if (!force && visibleCharacters == lastVisibleCharacters) return null
        lastVisibleCharacters = visibleCharacters

        return spokenTextDisplayFormat.asMiniWithResolvers(
            player,
            Placeholder.component("message", typewriter.component(percentage)),
        )
    }
}
