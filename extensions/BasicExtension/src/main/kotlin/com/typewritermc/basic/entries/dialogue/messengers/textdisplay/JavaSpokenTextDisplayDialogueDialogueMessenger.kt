package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.basic.entries.dialogue.SpokenTextDisplayDialogueEntry
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import com.typewritermc.engine.paper.entry.dialogue.DialogueMessenger
import com.typewritermc.engine.paper.entry.dialogue.TickContext
import com.typewritermc.engine.paper.entry.dialogue.MessengerState
import org.bukkit.event.EventHandler
import org.bukkit.entity.Player
import org.bukkit.event.player.PlayerRespawnEvent

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
) : DialogueMessenger<SpokenTextDisplayDialogueEntry>(player, context, entry) {
    private val playback = TextDisplayDialoguePlayback(player, context, entry.origin, entry.orientation, spokenTextDisplayFormat)

    override var animationComplete: Boolean
        get() = playback.animationComplete
        set(value) = playback.requestAnimationCompletion(value)

    @EventHandler
    private fun onPlayerRespawn(event: PlayerRespawnEvent) {
        if (event.player.uniqueId == player.uniqueId) playback.playerRespawned()
    }

    override fun dispose() {
        super.dispose()
        playback.dispose()
    }

    override fun init() {
        super.init()
        playback.prepare(entry.text.get(player, context), entry.duration.get(player, context))
        playback.display.setInstruction(spokenTextDisplayInstruction.asMiniWithResolvers(player))
        state = playback.spawn(entry.id, canConfirm = true, animationEnd = playback.typingDuration)
    }

    override fun tick(context: TickContext) {
        if (state == MessengerState.RUNNING) state = playback.tick(context)
    }
}
