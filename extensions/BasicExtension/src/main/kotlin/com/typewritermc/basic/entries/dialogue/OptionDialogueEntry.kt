package com.typewritermc.basic.entries.dialogue

import com.typewritermc.basic.entries.dialogue.messengers.option.BedrockOptionDialogueDialogueMessenger
import com.typewritermc.basic.entries.dialogue.messengers.option.JavaOptionDialogueDialogueMessenger
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.dialogue.DialogueMessenger
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.isFloodgate
import org.bukkit.entity.Player
import java.time.Duration
import kotlin.reflect.KClass

@Entry("option", "Display a list of options to the player", "#4CAF50", "fa6-solid:list")
@ContextKeys(OptionContextKeys::class)
/**
 * The `Option Dialogue` action displays a list of options to the player to choose from. This action provides you with the ability to give players choices that affect the outcome of the game.
 *
 * ## How could this be used?
 *
 * This action can be useful in a variety of situations, such as presenting the player with dialogue choices that determine the course of a story or offering the player a choice of rewards for completing a quest.
 */
class OptionDialogueEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    override val speaker: Ref<SpeakerEntry> = emptyRef(),
    @Placeholder
    @Colored
    val text: Var<String> = ConstVar(""),
    val options: List<Option> = emptyList(),
    @Help("The duration it takes to type out the message. If the duration is zero, the message will be displayed instantly.")
    val duration: Var<Duration> = ConstVar(Duration.ZERO),
) : DialogueEntry {
    override fun messenger(player: Player, context: InteractionContext): DialogueMessenger<OptionDialogueEntry> {
        return if (player.isFloodgate) BedrockOptionDialogueDialogueMessenger(player, context, this)
        else JavaOptionDialogueDialogueMessenger(player, context, this)
    }
}

enum class OptionContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Int::class)
    SELECTED_OPTION(Int::class),
}


data class Option(
    @Help("Text for this option.")
    val text: Var<String> = ConstVar(""),
    @Help("The criteria that must be met for this option to show.")
    val criteria: List<Criteria> = emptyList(),
    @Help("The modifiers to apply when this option is chosen.")
    val modifiers: List<Modifier> = emptyList(),
    @Help("The triggers to fire when this option is chosen.")
    val triggers: List<Ref<TriggerableEntry>> = emptyList()
) {
    val eventTriggers: List<EventTrigger> get() = triggers.map(::EntryTrigger)
}