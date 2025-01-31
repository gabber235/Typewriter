package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.TypewriterCommand
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.command.dsl.CommandTree
import com.typewritermc.engine.paper.command.dsl.entry
import com.typewritermc.engine.paper.command.dsl.executePlayerOrTarget
import com.typewritermc.engine.paper.command.dsl.withPermission
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.startDialogueWithOrNextDialogue
import com.typewritermc.engine.paper.entry.triggerFor

@Entry(
    "fire_trigger_event",
    "Trigger the event when a player runs `/tw fire <entry id/name> [player]`",
    Colors.YELLOW,
    "mingcute:firework-fill"
)
/**
 * The `FireTriggerEventEntry` is an event that fires its triggers when the player runs `/tw fire <entry id/name> [force] [player]`
 *
 * By default, the event will only trigger if the player is not in a dialogue.
 * If they are in a dialogue, the event will trigger the next dialogue.
 * This is to allow things like npcs to trigger this event and still continue the conversation.
 *
 * If you want to force the event to trigger, you can use `/tw fire <entry id/name> force [player]`
 *
 * ## How could this be used?
 * This could be used to trigger an event when a player runs `/tw fire <entry id/name> [force] [player]`
 */
class FireTriggerEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : EventEntry

@TypewriterCommand
fun CommandTree.fireCommand() = literal("fire") {
    withPermission("typewriter.fire")
    entry<FireTriggerEventEntry>("entry") { entry ->
        executePlayerOrTarget { target ->
            listOf(entry()).startDialogueWithOrNextDialogue(target, context())
        }

        literal("force") {
            executePlayerOrTarget { target ->
                entry().eventTriggers.triggerFor(target, context())
            }
        }
    }
}