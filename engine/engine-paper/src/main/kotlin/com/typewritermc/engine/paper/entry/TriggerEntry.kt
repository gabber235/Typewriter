package com.typewritermc.engine.paper.entry

import com.google.gson.annotations.SerializedName
import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.interaction.EntryContextBuilder
import com.typewritermc.core.interaction.InteractionBound
import com.typewritermc.engine.paper.entry.dialogue.DialogueTrigger
import com.typewritermc.engine.paper.entry.entries.EntryTrigger
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.interaction.withContext
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent.get

@Tags("trigger")
interface TriggerEntry : Entry {
    @Help("The entries that will be fired after this entry.")
    val triggers: List<Ref<TriggerableEntry>>

    val eventTriggers: List<EventTrigger>
        get() = triggers.map(::EntryTrigger)
}

@Tags("triggerable")
interface TriggerableEntry : TriggerEntry {
    @Help("The criteria that must be met before this entry is triggered")
    val criteria: List<Criteria>

    @Help("The modifiers that will be applied when this entry is triggered")
    val modifiers: List<Modifier>
}

@Tags("interaction_bound")
interface InteractionBoundEntry : TriggerableEntry {
    @Help("Triggers that are fired if the interaction is interrupted")
    val interruptTriggers: List<Ref<TriggerableEntry>>

    fun build(player: Player): InteractionBound
}

/**
 * Trigger all triggers for all entries in a list.
 *
 * Example:
 * ```kotlin
 * val entries: List<SomeEntry> = ...
 * entries.triggerAllFor(player, context())
 * ```
 *
 * @param player The player to trigger the triggers for.
 * @param context The context trigger the interaction with.
 */
fun <E : TriggerEntry> List<E>.triggerAllFor(player: Player, context: InteractionContext) {
    val triggers = this.flatMap { it.eventTriggers }
    if (triggers.isEmpty()) return
    get<PlayerSessionManager>(PlayerSessionManager::class.java).triggerActions(player, context, triggers)
}

/**
 * Trigger all triggers for all entries in a list.
 *
 * Example:
 * ```kotlin
 * val entries: List<SomeEntry> = ...
 * entries.triggerAllFor(player) {
 *     // Add context here
 * }
 * ```
 *
 * @param player The player to trigger the triggers for.
 * @param builder The entry context builder to build the context with.
 */
inline fun <reified E : TriggerEntry> List<E>.triggerAllFor(player: Player, builder: EntryContextBuilder<E>) {
    val triggers = this.flatMap { it.eventTriggers }
    if (triggers.isEmpty()) return
    get<PlayerSessionManager>(PlayerSessionManager::class.java).triggerActions(player, this.withContext(builder), triggers)
}

/**
 * Trigger all triggers for all entries in a sequence.
 *
 * Example:
 * ```kotlin
 * val entries: Sequence<SomeEntry> = ...
 * entries.triggerAllFor(player, context())
 * ```
 *
 * @param player The player to trigger the triggers for.
 */
fun <E : TriggerEntry> Sequence<E>.triggerAllFor(player: Player, context: InteractionContext) {
    val triggers = this.flatMap { it.eventTriggers }.toList()
    if (triggers.isEmpty()) return
    get<PlayerSessionManager>(PlayerSessionManager::class.java).triggerActions(player, context, triggers)
}

/**
 * Trigger all triggers for all entries in a sequence.
 *
 * Example:
 * ```kotlin
 * val entries: Sequence<SomeEntry> = ...
 * entries.triggerAllFor(player) {
 *     // Add context here
 * }
 * ```
 *
 * @param player The player to trigger the triggers for.
 * @param builder The entry context builder to build the context with.
 */
inline fun <reified E : TriggerEntry> Sequence<E>.triggerAllFor(player: Player, builder: EntryContextBuilder<E>) {
    val entries = toList()
    val triggers = entries.flatMap { it.eventTriggers }
    if (triggers.isEmpty()) return
    get<PlayerSessionManager>(PlayerSessionManager::class.java).triggerActions(player, entries.withContext(builder), triggers)
}

/**
 * Trigger all triggers for an entry.
 *
 * Example:
 * ```kotlin
 * val entry: SomeEntry = ...
 * entry.triggerAllFor(player, context())
 * ```
 *
 * @param player The player to trigger the triggers for.
 */
fun <E : TriggerEntry> E.triggerAllFor(player: Player, context: InteractionContext) {
    val triggers = this.eventTriggers
    if (triggers.isEmpty()) return
    get<PlayerSessionManager>(PlayerSessionManager::class.java).triggerActions(player, context, triggers)
}

/**
 * Trigger all triggers for a player.
 *
 * Example:
 * ```kotlin
 * val entry: SomeEntry = ...
 * entry.triggerAllFor(player) {
 *     // Add context here
 * }
 * ```
 *
 * @param player The player to trigger the triggers for.
 * @param builder The entry context builder to build the context with.
 */
inline fun <reified E : TriggerEntry> E.triggerAllFor(player: Player, builder: EntryContextBuilder<E>) {
    val triggers = this.eventTriggers
    if (triggers.isEmpty()) return
    get<PlayerSessionManager>(PlayerSessionManager::class.java).triggerActions(player, this.withContext(builder), triggers)
}

/**
 * Trigger all triggers for all entries in a list.
 * This is a convenience method for [triggerAllFor] that takes a list of [Ref].
 *
 * Example:
 * ```kotlin
 * val triggers: List<Ref<TriggerableEntry>> = ...
 * triggers.triggerEntriesFor(player, context())
 * ```
 *
 * @param player The player to trigger the triggers for.
 */
fun List<Ref<out TriggerableEntry>>.triggerEntriesFor(player: Player, context: InteractionContext) {
    val triggers = eventTriggers
    if (triggers.isEmpty()) return
    get<PlayerSessionManager>(PlayerSessionManager::class.java).triggerActions(player, context, triggers)
}

/**
 * Trigger all triggers for all entries in a list.
 * This is a convenience method for [triggerAllFor] that takes a [Ref].
 *
 * Example:
 * ```kotlin
 * val triggers: List<Ref<TriggerableEntry>> = ...
 * triggers.triggerEntriesFor(player) {
 *     // Add context here
 * }
 * ```
 *
 * @param player The player to trigger the triggers for.
 * @param builder The entry context builder to build the context with.
 */
inline fun <reified E : TriggerableEntry> List<Ref<E>>.triggerEntriesFor(player: Player, builder: EntryContextBuilder<E>) {
    val triggers = eventTriggers
    if (triggers.isEmpty()) return
    get<PlayerSessionManager>(PlayerSessionManager::class.java).triggerActions(player, this.withContext(builder), triggers)
}

/**
 * Trigger all triggers for all entries in a sequence.
 * This is a convenience method for [triggerAllFor] that takes a sequence of [Ref].
 *
 * Example:
 * ```kotlin
 * val triggers: Sequence<Ref<TriggerableEntry>> = ...
 * triggers.triggerEntriesFor(player, context())
 * ```
 *
 * @param player The player to trigger the triggers for.
 */
fun Sequence<Ref<out TriggerableEntry>>.triggerEntriesFor(player: Player, context: InteractionContext) {
    val triggers = eventTriggers.toList()
    if (triggers.isEmpty()) return
    get<PlayerSessionManager>(PlayerSessionManager::class.java).triggerActions(player, context, triggers)
}

/**
 * Trigger all triggers for all entries in a sequence.
 * This is a convenience method for [triggerAllFor] that takes a sequence of [Ref].
 *
 * Example:
 * ```kotlin
 * val triggers: Sequence<Ref<TriggerableEntry>> = ...
 * triggers.triggerEntriesFor(player) {
 *     // Add context here
 * }
 * ```
 *
 * @param player The player to trigger the triggers for.
 * @param builder The entry context builder to build the context with.
 */
inline fun <reified E : TriggerableEntry> Sequence<Ref<E>>.triggerEntriesFor(player: Player, builder: EntryContextBuilder<E>) {
    val entries = toList()
    val triggers = entries.eventTriggers
    if (triggers.isEmpty()) return
    get<PlayerSessionManager>(PlayerSessionManager::class.java).triggerActions(player, entries.withContext(builder), triggers)
}

/**
 * Trigger all triggers for an entry.
 * This is a convenience method for [triggerAllFor] that takes a [Ref].
 *
 * Example:
 * ```kotlin
 * val trigger: Ref<TriggerableEntry> = ...
 * trigger.triggerFor(player, context())
 * ```
 *
 * @param player The player to trigger the trigger for.
 */
fun Ref<out TriggerableEntry>.triggerFor(player: Player, context: InteractionContext) {
    EntryTrigger(this).triggerFor(player, context)
}

/**
 * Trigger all triggers for an entry.
 * This is a convenience method for [triggerAllFor] that takes a [Ref].
 *
 * Example:
 * ```kotlin
 * val trigger: Ref<TriggerableEntry> = ...
 * trigger.triggerFor(player) {
 *     // Add context here
 * }
 * ```
 *
 * @param player The player to trigger the trigger for.
 */
inline fun <reified E : TriggerableEntry> Ref<E>.triggerFor(player: Player, builder: EntryContextBuilder<E>) {
    EntryTrigger(this).triggerFor(player, this.withContext(builder))
}

/**
 * Trigger a specific trigger for a player.
 *
 * Example:
 * ```kotlin
 * val trigger: EventTrigger = ...
 * trigger.triggerFor(player, context())
 * ```
 *
 * @param player The player to trigger the trigger for.
 */
fun EventTrigger.triggerFor(player: Player, context: InteractionContext) = listOf(this).triggerFor(player, context)

/**
 * Forcefully Trigger a specific trigger for a player.
 *
 * This will bypass the event queue and execute the event immediately.
 * This is useful for events that need to be executed immediately.
 * **This should only be used sparingly.**
 *
 * Example:
 * ```kotlin
 * val trigger: EventTrigger = ...
 * trigger.forceTriggerFor(player, context())
 * ```
 */
suspend fun EventTrigger.forceTriggerFor(player: Player, context: InteractionContext) = listOf(this).forceTriggerFor(player, context)

/**
 * Trigger all triggers for a player.
 *
 * Example:
 * ```kotlin
 * val triggers: List<EventTrigger> = ...
 * triggers.triggerAllFor(player, context())
 * ```
 *
 * @param player The player to trigger the triggers for.
 */
fun List<EventTrigger>.triggerFor(player: Player, context: InteractionContext) {
    get<PlayerSessionManager>(PlayerSessionManager::class.java).triggerActions(player, context, this)
}

/**
 * Forcefully Trigger all triggers for a player.
 *
 * This will bypass the event queue and execute the event immediately.
 * This is useful for events that need to be executed immediately.
 * **This should only be used sparingly.**
 *
 * Example:
 * ```kotlin
 * val triggers: List<EventTrigger> = ...
 * triggers.forceTriggerFor(player, context())
 * ```
 */
suspend fun List<EventTrigger>.forceTriggerFor(player: Player, context: InteractionContext) {
    get<PlayerSessionManager>(PlayerSessionManager::class.java).forceTriggerActions(player, context, this)
}


/**
 * If the player is not in a dialogue, trigger all triggers for all entries in a list.
 * If the player is in a dialogue, only trigger the [continueTrigger].
 *
 * This can be useful for actions that should not be triggered again if the player is already in a dialogue.
 * Like clicking on a npc to start a conversation. As we don't want to start the conversation again
 * if the player is already in a dialogue.
 *
 * Example:
 * ```kotlin
 * val entries: List<SomeEntry> = ...
 * entries.startDialogueWithOrTrigger(player, continueTrigger, context())
 * ```
 */
fun <E : TriggerEntry> List<E>.startDialogueWithOrTrigger(
    player: Player,
    continueTrigger: EventTrigger,
    context: InteractionContext
) {
    val triggers = this.flatMap { it.eventTriggers }
    if (triggers.isEmpty()) return
    get<PlayerSessionManager>(PlayerSessionManager::class.java).startDialogueWithOrTriggerEvent(
        player,
        context,
        triggers,
        continueTrigger
    )
}


/**
 * If the player is not in a dialogue, trigger all triggers for all entries in a list.
 * If the player is in a dialogue, only trigger the [continueTrigger].
 *
 * This can be useful for actions that should not be triggered again if the player is already in a dialogue.
 * Like clicking on a npc to start a conversation. As we don't want to start the conversation again
 * if the player is already in a dialogue.
 *
 * Example:
 * ```kotlin
 * val entries: Sequence<SomeEntry> = ...
 * entries.startDialogueWithOrTrigger(player, continueTrigger, context())
 * ```
 */
fun <E : TriggerEntry> Sequence<E>.startDialogueWithOrTrigger(
    player: Player,
    continueTrigger: EventTrigger,
    context: InteractionContext
) =
    toList().startDialogueWithOrTrigger(player, continueTrigger, context)

/**
 * If the player is not in a dialogue, trigger all triggers for all entries in a list.
 * If the player is in a dialogue, it will trigger the next dialogue.
 *
 * This can be useful for actions that should not be triggered again if the player is already in a dialogue.
 * Like clicking on a npc to start a conversation. As we don't want to start the conversation again
 * if the player is already in a dialogue.
 *
 * Example:
 * ```kotlin
 * val entries: List<SomeEntry> = ...
 * entries.startDialogueWithOrTrigger(player, context())
 * ```
 */
fun <E : TriggerEntry> List<E>.startDialogueWithOrNextDialogue(player: Player, context: InteractionContext) =
    startDialogueWithOrTrigger(player, DialogueTrigger.NEXT_OR_COMPLETE, context)

/**
 * If the player is not in a dialogue, trigger all triggers for all entries in a list.
 * If the player is in a dialogue, it will trigger the next dialogue.
 *
 * This can be useful for actions that should not be triggered again if the player is already in a dialogue.
 * Like clicking on a npc to start a conversation.
 * As we don't want to start the conversation again
 * and we don't want to trigger the same dialogue again.
 *
 * Example:
 * ```kotlin
 * val entries: List<SomeEntry> = ...
 * entries.startDialogueWithOrTrigger(player) {
 *     // Add context here
 * }
 * ```
 */
inline fun <reified E : TriggerEntry> List<E>.startDialogueWithOrNextDialogue(player: Player, builder: EntryContextBuilder<E>) =
    startDialogueWithOrTrigger(player, DialogueTrigger.NEXT_OR_COMPLETE, this.withContext(builder))



/**
 * If the player is not in a dialogue, trigger all triggers for all entries in a sequence.
 * If the player is in a dialogue, it will trigger the next dialogue.
 *
 * This can be useful for actions that should not be triggered again if the player is already in a dialogue.
 * Like clicking on a npc to start a conversation.
 * As we don't want to start the conversation again
 * if the player is already in a dialogue.
 *
 * Example:
 * ```kotlin
 * val entries: Sequence<SomeEntry> = ...
 * entries.startDialogueWithOrNextDialogue(player, context())
 * ```
 */
fun <E : TriggerEntry> Sequence<E>.startDialogueWithOrNextDialogue(player: Player, context: InteractionContext) =
    toList().startDialogueWithOrTrigger(player, DialogueTrigger.NEXT_OR_COMPLETE, context)

/**
 * If the player is not in a dialogue, trigger all triggers for all entries in a sequence.
 * If the player is in a dialogue, it will trigger the next dialogue.
 *
 * This can be useful for actions that should not be triggered again if the player is already in a dialogue.
 * Like clicking on a npc to start a conversation.
 * As we don't want to start the conversation again
 * and we don't want to trigger the same dialogue again.
 *
 * Example:
 * ```kotlin
 * val entries: Sequence<SomeEntry> = ...
 * entries.startDialogueWithOrTrigger(player) {
 *     // Add context here
 * }
 * ```
 */
inline fun <reified E : TriggerEntry> Sequence<E>.startDialogueWithOrNextDialogue(player: Player, builder: EntryContextBuilder<E>) {
    val entries = toList()
    entries.startDialogueWithOrTrigger(player, DialogueTrigger.NEXT_OR_COMPLETE, entries.withContext(builder))
}

val Sequence<Ref<out TriggerableEntry>>.eventTriggers: Sequence<EventTrigger>
    get() = map { EntryTrigger(it) }

val List<Ref<out TriggerableEntry>>.eventTriggers: List<EventTrigger>
    get() = map { EntryTrigger(it) }
