package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Colored
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.MultiLine
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.dialogue.playSpeakerSound
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.sendMiniWithResolvers
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder.parsed

private val messageFormat: String by snippet(
    "action.message.format",
    "\n<gray> [ <bold><speaker></bold><reset><gray> ]\n<reset><white> <message>\n"
)

@Entry("send_message", "Send a message to a player", Colors.RED, "flowbite:message-dots-solid")
/**
 * The `Send Message Action` is an action that sends a message to a player.
 * You can specify the speaker, and the message to send.
 *
 * This should not be confused with the (Message Dialogue)[../dialogue/message].
 * (Message Dialogue)[../dialogue/message] will replace the current dialogue with the message, while this action will not.
 *
 * ## How could this be used?
 *
 * This action can be useful in a variety of situations.
 * You can use it to create text effects in response to specific events, such as completing actions or anything else.
 * The possibilities are endless!
 */
class MessageActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val speaker: Ref<SpeakerEntry> = emptyRef(),
    @Placeholder
    @Colored
    @MultiLine
    val message: Var<String> = ConstVar(""),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        val speakerEntry = speaker.get()
        player.playSpeakerSound(speakerEntry)
        player.sendMiniWithResolvers(
            messageFormat,
            parsed(
                "speaker",
                speakerEntry?.displayName?.get(player, context)?.parsePlaceholders(player) ?: ""
            ),
            parsed(
                "message",
                message.get(player, context).parsePlaceholders(player).replace("\n", "\n ")
            )
        )
    }
}