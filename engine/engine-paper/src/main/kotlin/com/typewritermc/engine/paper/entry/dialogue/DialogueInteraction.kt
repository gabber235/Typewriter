package com.typewritermc.engine.paper.entry.dialogue

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.core.interaction.Interaction
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.ok
import com.typewritermc.engine.paper.entry.entries.DialogueEntry
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.entries.SpeakerEntry
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.events.AsyncDialogueEndEvent
import com.typewritermc.engine.paper.events.AsyncDialogueStartEvent
import com.typewritermc.engine.paper.events.AsyncDialogueSwitchEvent
import com.typewritermc.engine.paper.facts.FactDatabase
import com.typewritermc.engine.paper.interaction.*
import com.typewritermc.engine.paper.utils.ThreadType.DISPATCHERS_ASYNC
import com.typewritermc.engine.paper.utils.playSound
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.java.KoinJavaComponent
import java.time.Duration

class DialogueInteraction(
    private val player: Player,
    initialInteractionContext: InteractionContext,
    initialEntry: DialogueEntry,
) : Interaction, KoinComponent {
    private val _speakers: MutableSet<Ref<SpeakerEntry>> = mutableSetOf()
    val speakers: Set<Ref<SpeakerEntry>> by ::_speakers

    private val factDatabase: FactDatabase by inject()

    internal var currentEntry: DialogueEntry = initialEntry
    private var currentMessenger = initialEntry.messenger(player, initialInteractionContext) ?: EmptyDialogueMessenger(
        player,
        initialInteractionContext,
        initialEntry
    )
    private var playTime = Duration.ZERO
    var isActive = false

    override val context: InteractionContext
        get() = currentMessenger.context

    val eventTriggers: List<EventTrigger>
        get() = currentMessenger.eventTriggers

    override val priority: Int
        get() = currentEntry.priority

    var isCompleted: Boolean
        get() = currentMessenger.isCompleted
        set(value) {
            currentMessenger.isCompleted = value
        }

    override suspend fun initialize(): Result<Unit> {
        setup()
        tick(playTime)
        DISPATCHERS_ASYNC.launch {
            AsyncDialogueStartEvent(player).callEvent()
        }
        return ok(Unit)
    }

    private fun setup() {
        isActive = true
        playTime = Duration.ZERO
        currentMessenger.init()
        _speakers.add(currentEntry.speaker)
        player.playSpeakerSound(currentEntry.speaker.get())
        player.startBlockingMessages()
        player.startBlockingActionBar()
    }

    override suspend fun tick(deltaTime: Duration) {
        if (!isActive) return
        playTime += deltaTime

        if (currentMessenger.state == MessengerState.FINISHED) {
            isActive = false
            DialogueTrigger.NEXT_OR_COMPLETE.triggerFor(player, currentMessenger.context)
        } else if (currentMessenger.state == MessengerState.CANCELLED) {
            isActive = false

            player.interruptInteraction(currentMessenger.context)
        }

        currentMessenger.tick(TickContext(playTime, deltaTime))
    }

    fun next(nextEntry: DialogueEntry, context: InteractionContext) {
        cleanupEntry(false)
        currentEntry = nextEntry
        val nextContext = currentMessenger.context.combine(context)
        currentMessenger =
            nextEntry.messenger(player, nextContext) ?: EmptyDialogueMessenger(player, nextContext, nextEntry)
        setup()
        DISPATCHERS_ASYNC.launch {
            AsyncDialogueSwitchEvent(player).callEvent()
        }
    }

    private fun cleanupEntry(final: Boolean) {
        val messenger = currentMessenger

        if (final) {
            player.stopBlockingMessages()
            player.stopBlockingActionBar()
            messenger.end()
        }
        messenger.dispose()

        factDatabase.modify(player, messenger.modifiers)
    }

    override suspend fun teardown(force: Boolean) {
        isActive = false
        cleanupEntry(true)
        DISPATCHERS_ASYNC.launch {
            AsyncDialogueEndEvent(player).callEvent()
        }
    }
}


private val Player.dialogueInteraction: DialogueInteraction?
    get() = with(KoinJavaComponent.get<PlayerSessionManager>(PlayerSessionManager::class.java)) {
        session?.interaction as? DialogueInteraction
    }

val Player.isInDialogue: Boolean
    get() = dialogueInteraction?.isActive ?: false

val Player.currentDialogue: DialogueEntry?
    get() {
        val sequence = dialogueInteraction ?: return null
        if (!sequence.isActive) return null
        return sequence.currentEntry
    }

val Player.speakersInDialogue: Set<Ref<SpeakerEntry>>
    get() {
        val sequence = dialogueInteraction ?: return emptySet()
        return sequence.speakers
    }

fun Player.playSpeakerSound(speaker: SpeakerEntry?) {
    val sound = speaker?.sound ?: return
    playSound(sound)
}

enum class DialogueTrigger : EventTrigger {
    NEXT_OR_COMPLETE,
    FORCE_NEXT,
    ;

    override val id: String
        get() = "system.${name.lowercase().replace('_', '.')}"

    override fun toString(): String {
        return "DialogueTrigger(id='$id')"
    }
}