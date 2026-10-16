package com.typewritermc.extensions.basic.entries.sequence.events

import com.typewritermc.types.text
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.engine.pages.SequencePage
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.expression.trim
import com.typewritermc.extensions.basic.entries.sequence.SequenceTriggers
import com.typewritermc.library.PageElements
import com.typewritermc.presentation.resourceHeading
import com.typewritermc.types.Color
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "01a0b180-cac6-770c-bbe8-101a740011ac", revision = 1)
@TypewriterDisplay(
    name = "Player Message Contains Text Event Entry",
    description = "This event entry is triggered when a player sends a message that contains a specific text.",
    icon = "fluent:note-48-filled",
    color = Color.Hex.YELLOW,
)
class PlayerMessageContainsTextEventEntry(
    override val page: Ref<PageElements.Element, SequencePage>,
    override val name: String,
    override val placement: GraphPlacement,
    val triggers: Set<Ref<SequenceTriggers.Entry, SequenceEntry>>,
    val text: String,
    val exactSame: Boolean,
) : SequenceEntry

object PlayerMessageContainsTextEventEntryInspector : PlayerMessageContainsTextEventEntryPresentation {
    override fun PlayerMessageContainsTextEventEntryPresentationScope.present() {
        resourceHeading(
            title = expressions.name.orElse(literal("Unnamed event")),
            color = literal(Color.parseRgb(requireNotNull(PlayerMessageContainsTextEventEntryDefinition.display?.color))),
            identifier = subject.identifier.text,
        )
        name {
            label("name")
            textInput { onComplete { value.trim() } }
        }
        remainingFields {}
    }
}
