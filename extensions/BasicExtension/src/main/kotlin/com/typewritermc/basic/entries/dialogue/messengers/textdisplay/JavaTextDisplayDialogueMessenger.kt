package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.dialogue.DialogueMessenger
import com.typewritermc.engine.paper.entry.dialogue.MessengerState
import com.typewritermc.engine.paper.entry.dialogue.TickContext
import com.typewritermc.engine.paper.entry.dialogue.typingDurationType
import com.typewritermc.engine.paper.entry.entries.DialogueEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.Confirmation
import com.typewritermc.engine.paper.interaction.awaitConfirmation
import com.typewritermc.engine.paper.logger
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.player.PlayerRespawnEvent
import java.time.Duration
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

internal abstract class JavaTextDisplayDialogueMessenger<E : DialogueEntry>(
    player: Player,
    context: InteractionContext,
    entry: E,
    private val text: Var<String>,
    private val duration: Var<Duration>,
    private val origin: Var<Position>,
    private val orientation: TextDisplayOrientation,
    private val format: String,
) : DialogueMessenger<E>(player, context, entry) {
    private val confirmed = AtomicBoolean()
    private val respawned = AtomicBoolean()
    private val animationRequest = AtomicReference<Boolean?>()
    @Volatile
    private var animationDone = false
    private var confirmation: Confirmation? = null
    private lateinit var typewriter: TextDisplayTypewriter
    private var durationConfig = Duration.ZERO
    protected var typingDuration: Duration = Duration.ZERO
        private set
    protected var playedTime: Duration = Duration.ZERO
    protected var display: TextDisplayDialogueDisplay? = null
        private set
    protected open val canConfirm: Boolean get() = true
    protected open val completionTime: Duration get() = typingDuration
    protected open val animationEnd: Duration get() = completionTime
    protected open val autoContinue: Boolean get() = false

    override var animationComplete: Boolean
        get() = animationDone
        set(value) {
            animationRequest.set(value)
        }

    final override fun init() {
        super.init()
        typewriter = TextDisplayTypewriter(text.get(player, context).parsePlaceholders(player), player)
        durationConfig = duration.get(player, context)
        typingDuration = typingDurationType.totalDuration(typewriter.rawText, durationConfig)
            .coerceAtLeast(Duration.ZERO)
        if (!prepareDialogue()) return
        refreshConfirmation(canConfirm)
        val activeDisplay = TextDisplayDialogueDisplay(player, context, origin, orientation)
        display = activeDisplay
        prepareDisplay(activeDisplay)
        updateDialogue()
        animationDone = canConfirm && playedTime >= animationEnd
        activeDisplay.spawn(render(force = true)!!)
        if (activeDisplay.invalid) {
            logger.warning("Dialogue '${entry.id}' cannot display: its origin must be in the player's world.")
            state = MessengerState.CANCELLED
        }
    }

    protected open fun prepareDialogue(): Boolean = true

    protected open fun prepareDisplay(display: TextDisplayDialogueDisplay) {}

    protected open fun updateDialogue() {}

    protected open fun stopInput() {}

    final override fun tick(context: TickContext) {
        if (state != MessengerState.RUNNING) return
        if (respawned.get()) {
            state = MessengerState.CANCELLED
            return
        }
        val activeDisplay = display ?: return
        var close = false
        val text = if (activeDisplay.isClosing) null else {
            val canConfirm = canConfirm
            val pressed = confirmed.getAndSet(false)
            refreshConfirmation(canConfirm)
            if (activeDisplay.ready) playedTime += context.deltaTime
            animationRequest.getAndSet(null)?.let {
                if (canConfirm) playedTime = if (it) animationEnd else Duration.ZERO
            }
            updateDialogue()
            if (state != MessengerState.RUNNING) return
            if (pressed && canConfirm) {
                if (playedTime >= animationEnd) close = true
                else {
                    playedTime = animationEnd
                    updateDialogue()
                    if (state != MessengerState.RUNNING) return
                }
            }
            animationDone = canConfirm && playedTime >= animationEnd
            render()
        }
        activeDisplay.tick(context.deltaTime, text)
        if (activeDisplay.invalid) {
            state = MessengerState.CANCELLED
            return
        }
        if (close || (autoContinue && activeDisplay.ready && playedTime >= completionTime)) {
            stopInput()
            activeDisplay.close()
        }
        if (activeDisplay.finished) state = MessengerState.FINISHED
    }

    @EventHandler
    fun onPlayerRespawn(event: PlayerRespawnEvent) {
        if (event.player.uniqueId == player.uniqueId) respawned.set(true)
    }

    final override fun dispose() {
        stopInput()
        super.dispose()
        confirmation?.dispose()
        confirmation = null
        display?.dispose()
        display = null
    }

    private fun refreshConfirmation(enabled: Boolean) {
        if (enabled && confirmation == null) {
            confirmation = player.awaitConfirmation { confirmed.set(true) }
        } else if (!enabled && confirmation != null) {
            confirmation?.dispose()
            confirmation = null
            confirmed.set(false)
        }
    }

    private fun render(force: Boolean = false) = typewriter.render(
        format,
        if (playedTime >= typingDuration) 1.0
        else typingDurationType.calculatePercentage(playedTime, durationConfig, typewriter.rawText),
        force,
    )
}
