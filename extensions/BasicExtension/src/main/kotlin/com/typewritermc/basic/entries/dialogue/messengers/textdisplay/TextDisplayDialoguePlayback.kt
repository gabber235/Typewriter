package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.dialogue.MessengerState
import com.typewritermc.engine.paper.entry.dialogue.TickContext
import com.typewritermc.engine.paper.entry.dialogue.typingDurationType
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.Confirmation
import com.typewritermc.engine.paper.interaction.awaitConfirmation
import com.typewritermc.engine.paper.logger
import org.bukkit.entity.Player
import java.time.Duration
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

internal class TextDisplayDialoguePlayback(
    private val player: Player,
    context: InteractionContext,
    origin: Var<Position>,
    orientation: TextDisplayOrientation,
    private val format: String,
    createDisplay: () -> TextDisplayDialogueDisplay = { TextDisplayDialogueDisplay(player, context, origin, orientation) },
) {
    private val displayDelegate = lazy(createDisplay)
    val display: TextDisplayDialogueDisplay by displayDelegate
    private val confirmed = TextDisplayConfirmationInput()
    private val respawned = AtomicBoolean()
    private val animationRequest = AtomicReference<Boolean?>()
    @Volatile
    var animationComplete = false
        private set
    private var confirmation: Confirmation? = null
    private lateinit var typewriter: TextDisplayTypewriter
    private var durationConfig = Duration.ZERO
    var typingDuration: Duration = Duration.ZERO
        private set
    var playedTime: Duration = Duration.ZERO
        private set

    fun prepare(text: String, duration: Duration) {
        typewriter = TextDisplayTypewriter(text.parsePlaceholders(player), player)
        durationConfig = duration
        typingDuration = typingDurationType.totalDuration(typewriter.rawText, duration).coerceAtLeast(Duration.ZERO)
    }

    fun spawn(entryId: String, canConfirm: Boolean, animationEnd: Duration, readTarget: () -> Any? = { Unit }): MessengerState {
        refreshConfirmation(canConfirm, readTarget)
        animationComplete = canConfirm && playedTime >= animationEnd
        display.spawn(checkNotNull(render(force = true)))
        if (!display.invalid) return MessengerState.RUNNING
        logger.warning("Dialogue '$entryId' cannot display: its origin must be in the player's world.")
        return MessengerState.CANCELLED
    }

    fun requestAnimationCompletion(value: Boolean) {
        animationRequest.set(value)
    }

    fun playerRespawned() {
        respawned.set(true)
    }

    fun tick(
        context: TickContext,
        canConfirm: Boolean = true,
        animationEnd: Duration = typingDuration,
        autoContinueAt: Duration? = null,
        target: Any? = Unit,
        readTarget: () -> Any? = { Unit },
        renderOptions: () -> Unit = {},
    ): MessengerState {
        if (respawned.get()) return MessengerState.CANCELLED
        if (display.isClosing) {
            display.tick(context.deltaTime, null)
            return displayState()
        }
        val pressed = confirmed.consume()
        refreshConfirmation(canConfirm, readTarget)
        if (display.ready) playedTime += context.deltaTime
        animationRequest.getAndSet(null)?.let {
            if (canConfirm) playedTime = if (it) animationEnd else Duration.ZERO
        }
        val confirmedCurrent = canConfirm && pressed != null && pressed === target
        val close = confirmedCurrent && playedTime >= animationEnd
        if (confirmedCurrent && !close) playedTime = animationEnd
        animationComplete = canConfirm && playedTime >= animationEnd
        renderOptions()
        display.tick(context.deltaTime, render())
        if (!display.invalid && (close || (autoContinueAt != null && display.ready && playedTime >= autoContinueAt))) {
            display.close()
        }
        return displayState()
    }

    private fun displayState(): MessengerState = when {
        display.invalid -> MessengerState.CANCELLED
        display.finished -> MessengerState.FINISHED
        else -> MessengerState.RUNNING
    }

    fun dispose() {
        confirmation?.dispose()
        confirmation = null
        if (displayDelegate.isInitialized()) display.dispose()
    }

    private fun refreshConfirmation(enabled: Boolean, target: () -> Any?) {
        if (enabled && confirmation == null) {
            confirmation = player.awaitConfirmation { confirmed.press(target()) }
        } else if (!enabled && confirmation != null) {
            confirmation?.dispose()
            confirmation = null
            confirmed.consume()
        }
    }

    private fun render(force: Boolean = false) = typewriter.render(
        format,
        if (playedTime >= typingDuration) 1.0
        else typingDurationType.calculatePercentage(playedTime, durationConfig, typewriter.rawText),
        force,
    )
}
