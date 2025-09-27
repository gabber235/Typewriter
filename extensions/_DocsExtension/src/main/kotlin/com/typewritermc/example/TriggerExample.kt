package com.typewritermc.example

import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.dialogue.DialogueTrigger
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.entries.InteractionEndTrigger
import com.typewritermc.engine.paper.entry.temporal.TemporalSettings
import com.typewritermc.engine.paper.entry.temporal.TemporalStartTrigger
import com.typewritermc.engine.paper.entry.temporal.TemporalStopTrigger
import com.typewritermc.engine.paper.interaction.interactionContext
import org.bukkit.entity.Player

fun triggerSingleEntry(player: Player) {
    //<code-block:trigger_without_context>
    // If you only have one entry
    val triggerEntry: TriggerEntry = Query.findById<MyTriggerableEntry>("some_id") ?: return
    // Triggers all the next entries in the sequence.
    triggerEntry.triggerAllFor(player, context())

    // If you have multiple entries
    val triggerEntries: Sequence<TriggerEntry> = Query.find<MyTriggerableEntry>()
    // Triggers all the next entries for all entries.
    triggerEntries.triggerAllFor(player, context())
    //</code-block:trigger_without_context>
}

fun startDialogueWithOrNextDialogue(player: Player) {
    //<code-block:start_dialogue_with_or_trigger>
    val triggerEntries: Sequence<MyTriggerableEntry> = Query.find<MyTriggerableEntry>()
    triggerEntries.startDialogueWithOrNextDialogue(player, context())

    // Or trigger something completely different when the player is in dialogue:
    val customTrigger: EventTrigger = InteractionEndTrigger
    triggerEntries.startDialogueWithOrTrigger(player, customTrigger, context())
    //</code-block:start_dialogue_with_or_trigger>
}

fun triggerWithContext(player: Player) {
    val triggerEntries: Sequence<TriggerEntry> = Query.find<MyTriggerableEntry>()
    //<code-block:trigger_with_context>
    // The context that you have, most likely provided by Typewriter in some way.
    val context = player.interactionContext ?: context()
    // Triggers all the next entries in the sequence.
    triggerEntries.triggerAllFor(player, context)
    //</code-block:trigger_with_context>
}

fun interactionTriggers(player: Player) {
    //<code-block:interaction_triggers>
    // Indicates that the current interaction should be ended
    InteractionEndTrigger.triggerFor(player, context())
    //</code-block:interaction_triggers>
}

fun dialogueTriggers(player: Player) {
    //<code-block:dialogue_triggers>
    // Next dialogue should be triggered or the current dialogue should complete its typing animation.
    DialogueTrigger.NEXT_OR_SKIP_ANIMATION.triggerFor(player, context())

    // Forces the next dialogue to be triggered, even if the animation hasn't finished.
    DialogueTrigger.FORCE_NEXT.triggerFor(player, context())
    //</code-block:dialogue_triggers>
}

fun temporalTriggers(player: Player) {
    //<code-block:temporal_triggers>
    // To start a temporal sequence
    TemporalStartTrigger(
        pageId = "some_id",
        eventTriggers = listOf<EventTrigger>(),
        settings = TemporalSettings(
            blockChatMessages = true,
            blockActionBarMessages = true
        )
    ).triggerFor(player, context())

    // To stop the temporal sequence and trigger the following entries.
    TemporalStopTrigger.triggerFor(player, player.interactionContext ?: context())
    //</code-block:temporal_triggers>
}

class MyTriggerableEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : TriggerableEntry