package com.typewritermc.extensions.basic.entries.sequence.actions

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.engine.events.Triggerable
import com.typewritermc.engine.events.complete
import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.engine.pages.SequencePage
import com.typewritermc.engine.pages.SequenceTriggers
import com.typewritermc.events.Handler
import com.typewritermc.events.Triggered
import com.typewritermc.library.PageElements
import com.typewritermc.types.Color
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType

/** An action with no work of its own: it goes on through its links, and from node 6 applies its changes first. */
@TypewriterType(id = "01a20277-8bab-7485-b441-9f0753de9080")
@TypewriterDisplay(
    name = "Simple Action",
    description = "Simple action to modify facts.",
    icon = "heroicons:bolt-16-solid",
    color = Color.Hex.RED,
)
class SimpleActionEntry(
    override val page: Ref<PageElements.Element, SequencePage>,
    override val name: String,
    override val placement: GraphPlacement,
    override val triggers: Set<Ref<SequenceTriggers.Entry, SequenceEntry>>,
) : Triggerable

/** Continues the chain through every link of the action. */
@Handler
suspend fun Triggered<SimpleActionEntry>.proceed() = complete()
