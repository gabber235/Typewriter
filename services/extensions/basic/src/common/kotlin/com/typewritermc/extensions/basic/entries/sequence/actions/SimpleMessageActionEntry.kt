package com.typewritermc.extensions.basic.entries.sequence.actions

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.extensions.basic.entries.sequence.SequenceTriggers
import com.typewritermc.types.Color
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "01a0b1fc-d60f-743f-aef8-5dce1c4ad200", revision = 1)
@TypewriterDisplay(
    name = "Simple Message Action Entry",
    description = "This allows you to send a simple message to the player.",
    icon = "flowbite:message-dots-solid",
    color = Color.Hex.RED,
)
class SimpleMessageActionEntry(
    override val name: String,
    override val placement: GraphPlacement,
    val triggers: Set<Ref<SequenceTriggers.Entry, SequenceEntry>>,
    val message: String,
) : SequenceEntry
