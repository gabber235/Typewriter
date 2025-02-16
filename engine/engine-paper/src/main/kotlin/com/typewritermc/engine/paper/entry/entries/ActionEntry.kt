package com.typewritermc.engine.paper.entry.entries

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.interaction.ContextModifier
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.EntryInteractionContextKey
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.facts.FactDatabase
import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent.get

@Tags("action")
interface ActionEntry : TriggerableEntry {
    fun ActionTrigger.execute()
}

class ActionTrigger(
    val player: Player,
    context: InteractionContext,
    val entry: ActionEntry,
) : ContextModifier(context) {
    internal var eventTriggers: List<EventTrigger> = entry.eventTriggers
    internal var automaticModifiers: Boolean = true
    internal var executed = false

    fun disableAutomaticTriggering() {
        eventTriggers = emptyList()
        automaticModifiers = false
    }

    fun disableAutomaticModifiers() {
        automaticModifiers = false
    }

    fun triggerManually() {
        applyModifiers()
        entry.eventTriggers.triggerFor(player)
    }

    fun applyModifiers() {
        val factDatabase: FactDatabase = get(FactDatabase::class.java)
        factDatabase.modify(player, entry.modifiers, context)
    }

    @JvmName("triggerForRefs")
    fun List<Ref<out TriggerableEntry>>.triggerFor(player: Player) {
        this.map { EntryTrigger(it) }.triggerFor(player)
    }

    /**
     * If the entry is not done executing, this will make sure the triggers stay within the interaction.
     * To make sure dialogue is not interrupted.
     *
     * If the entry is already done executing, this will externally trigger the triggers.
     */
    fun List<EventTrigger>.triggerFor(player: Player) {
        if (isEmpty()) return
        if (executed) {
            this.triggerFor(player, context)
            return
        }
        eventTriggers += this
    }

    operator fun <T : Any> InteractionContext.set(key: EntryContextKey, value: T) {
        this[EntryInteractionContextKey<T>(entry.ref(), key)] = value
    }
}