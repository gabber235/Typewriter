package com.typewritermc.engine.paper.entry.entries

import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.dialogue.DialogueMessenger
import org.bukkit.entity.Player

@Tags("dialogue")
interface DialogueEntry : TriggerableEntry {
    @Help(key = "engine.dialogue.fields.speaker.help")
    val speaker: Ref<SpeakerEntry>

    val speakerDisplayName: Var<String>
        get() = speaker.get()?.displayName ?: ConstVar("")

    fun messenger(player: Player, context: InteractionContext): DialogueMessenger<*>?
}

