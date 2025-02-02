package com.typewritermc.engine.paper.entry.entries

import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.command.dsl.DslCommand
import com.typewritermc.engine.paper.entry.TriggerEntry
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.matches
import io.papermc.paper.command.brigadier.CommandSourceStack
import org.bukkit.entity.Player

@Tags("event")
interface EventEntry : TriggerEntry

interface CustomCommandEntry : Entry {
    @Suppress("UnstableApiUsage")
    fun command(): DslCommand<CommandSourceStack>
}

class Event(val player: Player, val context: InteractionContext, val triggers: List<EventTrigger>) {
    constructor(player: Player, context: InteractionContext, vararg triggers: EventTrigger) : this(
        player,
        context,
        triggers.toList()
    )

    operator fun contains(trigger: EventTrigger) = triggers.contains(trigger)

    operator fun contains(entry: Entry) = triggers.any { it.id == entry.id }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Event) return false

        if (triggers != other.triggers) return false
        return player.uniqueId == other.player.uniqueId
    }

    override fun hashCode(): Int {
        var result = triggers.hashCode()
        result = 31 * result + player.hashCode()
        return result
    }

    override fun toString(): String {
        return "Event(player=${player.name}, triggers=$triggers)"
    }

    fun distinct(): Event = Event(player, context, triggers.distinct())
    fun filterAllowedTriggers() = Event(player, context, triggers.filter { it.canTriggerFor(player, context) })
}

interface EventTrigger {
    val id: String
    fun canTriggerFor(player: Player, interactionContext: InteractionContext): Boolean = true
}

data class EntryTrigger(val ref: Ref<out TriggerableEntry>) : EventTrigger {
    override val id: String = ref.id

    constructor(entry: TriggerableEntry) : this(entry.ref())

    override fun canTriggerFor(player: Player, interactionContext: InteractionContext): Boolean =
        ref.get()?.criteria?.matches(player, interactionContext) ?: false
}

data object InteractionEndTrigger : EventTrigger {
    override val id: String
        get() = "system.interaction.end"

}
