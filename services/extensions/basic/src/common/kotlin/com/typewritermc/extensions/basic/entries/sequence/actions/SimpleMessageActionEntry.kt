package com.typewritermc.extensions.basic.entries.sequence.actions

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.TypewriterElement
import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.types.Color
import com.typewritermc.types.Ref

@TypewriterElement(
    id = "01a0b1fc-d60f-743f-aef8-5dce1c4ad200",
    revision = 1,
    name = "Simple Message Action Entry",
    description = "This allows you to send a simple message to the player.",
    icon = "flowbite:message-dots-solid",
    color = Color.Hex.RED,
)
class SimpleMessageActionEntry(
    override val id: ElementInstanceId,
    override val name: String,
    val triggers: Set<Ref<SequenceEntry>>,
    val message: String,
) : SequenceEntry
