package com.typewritermc.basic.entries.dialogue.messengers.timed

import com.typewritermc.basic.entries.dialogue.TimedDialogueEntry
import com.typewritermc.core.interaction.InteractionBoundState
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.dialogue.DialogueMessenger
import com.typewritermc.engine.paper.entry.dialogue.MessengerState
import com.typewritermc.engine.paper.entry.dialogue.TickContext
import com.typewritermc.engine.paper.entry.dialogue.typingDurationType
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.boundState
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.legacy
import com.typewritermc.engine.paper.utils.stripped
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import java.time.Duration

private val timedTitle: String by snippet("dialogue.timed.bedrock.title", "<bold><speaker></bold>")
private val timedContent: String by snippet("dialogue.timed.bedrock.content", "<message>\n\n")
private val timedButton: String by snippet("dialogue.timed.bedrock.button", "Continue")

class BedrockTimedDialogueDialogueMessenger(player: Player, context: InteractionContext, entry: TimedDialogueEntry) :
    DialogueMessenger<TimedDialogueEntry>(player, context, entry) {

    private var typingDuration = Duration.ZERO
    private var waitDuration = Duration.ZERO
    private var totalDuration = Duration.ZERO
    private var playedTime = Duration.ZERO
    private var text = ""
    private var speakerDisplayName = ""

    override fun init() {
        super.init()
        speakerDisplayName = entry.speakerDisplayName.get(player).parsePlaceholders(player)
        text = entry.text.get(player).parsePlaceholders(player)
        typingDuration = typingDurationType.totalDuration(text.stripped(), entry.typingDuration.get(player))
        waitDuration = entry.waitDuration.get(player)
        totalDuration = typingDuration + waitDuration
        sendForm()
    }

    fun sendForm() {
        org.geysermc.floodgate.api.FloodgateApi.getInstance().sendForm(
            player.uniqueId,
            org.geysermc.cumulus.form.SimpleForm.builder()
                .title(
                    timedTitle.parsePlaceholders(player).legacy(
                        Placeholder.parsed("speaker", speakerDisplayName)
                    )
                )
                .content(
                    timedContent.parsePlaceholders(player).legacy(
                        Placeholder.parsed("message", text)
                    )
                )
                .button(timedButton.parsePlaceholders(player).legacy())
                .closedOrInvalidResultHandler { _, _ ->
                    when (player.boundState) {
                        InteractionBoundState.BLOCKING -> sendForm()
                        else -> state = MessengerState.CANCELLED
                    }
                }
                .validResultHandler { _, _ ->
                    state = MessengerState.FINISHED
                }
        )
    }

    override fun tick(context: TickContext) {
        if (state != MessengerState.RUNNING) return
        playedTime += context.deltaTime

        if (playedTime >= totalDuration) {
            org.geysermc.floodgate.api.FloodgateApi.getInstance().closeForm(player.uniqueId)
            state = MessengerState.FINISHED
        }
    }

    override fun end() {
    }
}

