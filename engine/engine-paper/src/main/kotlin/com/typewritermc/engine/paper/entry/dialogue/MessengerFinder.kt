package com.typewritermc.engine.paper.entry.dialogue

import com.github.shynixn.mccoroutine.bukkit.ticks
import com.typewritermc.core.interaction.ContextModifier
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.entries.DialogueEntry
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.interaction.chatHistory
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.ThreadType.SYNC
import kotlinx.coroutines.delay
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.registerEvents
import org.bukkit.entity.Player
import org.bukkit.event.Listener
import java.time.Duration

enum class MessengerState {
    RUNNING,
    FINISHED,
    CANCELLED,
}

open class DialogueMessenger<DE : DialogueEntry>(
    val player: Player,
    context: InteractionContext,
    val entry: DE,
) : ContextModifier(context), Listener {
    open var state: MessengerState = MessengerState.RUNNING
        protected set

    open var isCompleted = true

    open fun init() {
        plugin.registerEvents(this)
    }

    open fun tick(context: TickContext) {}

    open fun dispose() {
        unregister()
    }

    open fun end() {
        state = MessengerState.FINISHED
        player.chatHistory.resendMessages(player)
//
//        // Resend the chat history again after a delay to make sure that the dialogue chat is fully cleared
//        SYNC.launch {
//            delay(1.ticks)
//            player.chatHistory.resendMessages(player)
//        }
    }

    open val eventTriggers: List<EventTrigger>
        get() = entry.eventTriggers

    open val modifiers: List<Modifier>
        get() = entry.modifiers

    fun completeOrFinish() {
        if (isCompleted) {
            state = MessengerState.FINISHED
        } else {
            isCompleted = true
        }
    }
}

class TickContext(
    val playTime: Duration,
    val deltaTime: Duration,
)

class EmptyDialogueMessenger(player: Player, context: InteractionContext, entry: DialogueEntry) :
    DialogueMessenger<DialogueEntry>(player, context, entry) {
    override fun init() {
        state = MessengerState.FINISHED
    }
}

