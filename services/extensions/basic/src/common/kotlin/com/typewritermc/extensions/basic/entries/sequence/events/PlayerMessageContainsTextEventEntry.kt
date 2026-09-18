package com.typewritermc.extensions.basic.entries.sequence.events

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.TypewriterElement
import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.presentation.PresentationBuildContext
import com.typewritermc.presentation.TypewriterPresentation
import com.typewritermc.presentation.presentation
import com.typewritermc.types.Color
import com.typewritermc.types.Ref

@TypewriterElement(
    id = "01a0b180-cac6-770c-bbe8-101a740011ac",
    revision = 1,
    name = "Player Message Contains Text Event Entry",
    description = "This event entry is triggered when a player sends a message that contains a specific text.",
    icon = "fluent:note-48-filled",
    color = Color.Hex.YELLOW,
)
class PlayerMessageContainsTextEventEntry(
    override val id: ElementInstanceId,
    override val name: String,
    val triggers: Set<Ref<SequenceEntry>>,
    val text: String,
    val exactSame: Boolean,
) : SequenceEntry

// @TypewriterPresentation(
//    default = true,
//    priority = 100,
// )
// context(_: PresentationBuildContext)
// fun playerMessageContainsTextEventEntryEditor() =
//    presentation<PlayerMessageContainsTextEventEntry>(name = "default") {
//
//    }
