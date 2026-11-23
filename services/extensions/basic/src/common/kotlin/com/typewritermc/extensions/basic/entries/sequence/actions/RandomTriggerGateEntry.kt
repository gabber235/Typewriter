package com.typewritermc.extensions.basic.entries.sequence.actions

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.engine.events.Triggerable
import com.typewritermc.engine.events.fire
import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.engine.pages.SequencePage
import com.typewritermc.engine.pages.SequenceTriggers
import com.typewritermc.events.Handler
import com.typewritermc.events.InteractionContext
import com.typewritermc.events.Triggered
import com.typewritermc.formula.Var
import com.typewritermc.library.PageElements
import com.typewritermc.types.Color
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType

/** Goes on through [amount] of its links, picked at random; each link fires at most once. */
@TypewriterType(id = "01a20264-98c1-7191-8cd7-fca3184778ff")
@TypewriterDisplay(
    name = "Random Trigger Gate",
    description = "Randomly selects its connected triggers.",
    icon = "mdi:clover",
    color = Color.Hex.PINK,
)
class RandomTriggerGateEntry(
    override val page: Ref<PageElements.Element, SequencePage>,
    override val name: String,
    override val placement: GraphPlacement,
    override val triggers: Set<Ref<SequenceTriggers.Entry, SequenceEntry>>,
    val amount: Var<Int, InteractionContext> = Var.Value(1),
) : Triggerable

/**
 * Fires [amount] distinct links of the gate, chosen at random, for the subject the chain runs for; with fewer links, all
 * of them. The draw uses an unseeded random until the chain carries its seed record.
 */
@Handler
suspend fun Triggered<RandomTriggerGateEntry>.pickLinks() {
    triggers
        .shuffled()
        .take(amount.coerceAtLeast(0))
        .fire(context, subject)
}
