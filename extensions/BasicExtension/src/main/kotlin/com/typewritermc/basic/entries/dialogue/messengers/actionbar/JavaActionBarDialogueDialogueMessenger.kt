package com.typewritermc.basic.entries.dialogue.messengers.actionbar

import com.typewritermc.basic.entries.dialogue.ActionBarDialogueEntry
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.dialogue.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.acceptActionBarMessage
import com.typewritermc.engine.paper.interaction.chatHistory
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.*
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.format.NamedTextColor
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import java.time.Duration

private val actionBarFormat: String by snippet(
    "dialogue.actionbar.format",
    "<bold><speaker></bold><reset><gray>: <white><message> <gray>[<confirmation_key>]</gray><padding>",
)

class JavaActionBarDialogueDialogueMessenger(
    player: Player,
    context: InteractionContext,
    entry: ActionBarDialogueEntry
) :
    DialogueMessenger<ActionBarDialogueEntry>(player, context, entry) {

    private var confirmationKeyHandler: ConfirmationKeyHandler? = null

    private var speakerDisplayName = ""
    private var text = ""
    private var typingDuration = Duration.ZERO
    private var playTime = Duration.ZERO

    override var isCompleted: Boolean
        get() = playTime >= typingDuration
        set(value) {
            playTime = if (!value) Duration.ZERO
            else typingDuration
        }

    override fun init() {
        super.init()
        speakerDisplayName = entry.speakerDisplayName.get(player).parsePlaceholders(player)
        text = entry.text.get(player).parsePlaceholders(player)
        typingDuration = typingDurationType.totalDuration(text.stripped(), entry.duration.get(player))

        confirmationKeyHandler = confirmationKey.handler(player) {
            completeOrFinish()
        }

        // The player might have had something before this. So we want to clean the chat before sending our message.
        player.chatHistory.resendMessages(player)
    }

    override fun tick(context: TickContext) {
        if (state != MessengerState.RUNNING) return
        playTime += context.deltaTime

        val rawText = text.stripped()
        val percentage = typingDurationType.calculatePercentage(playTime, entry.duration.get(player), rawText)

        // After the message is finished typing, we don't need to send it as often anymore.
        if (percentage > 1.1 && playTime.toTicks() % 40 > 0) {
            return
        }

        val message = text.asMini()
            .splitPercentage(percentage)
            .color(NamedTextColor.WHITE)

        // Find out how much padding is needed to fill the rest of the action bar.
        // As the action bar is centered, adding padding to the end of the message
        // will make the message appear stationary.
        val paddingSize = text.stripped().length - message.plainText().length
        val padding = " ".repeat(paddingSize)

        val component = actionBarFormat.asMiniWithResolvers(
            Placeholder.parsed("speaker", speakerDisplayName),
            Placeholder.component("message", message),
            Placeholder.unparsed("padding", padding),
        )

        player.acceptActionBarMessage(component)
        player.sendActionBar(component)
    }

    override fun end() {
        // Do nothing as we don't need to resend the messages.
    }

    override fun dispose() {
        super.dispose()
        val component = Component.empty()
        player.acceptActionBarMessage(component)
        player.sendActionBar(component)
        confirmationKeyHandler?.dispose()
        confirmationKeyHandler = null
    }
}