package com.typewritermc.extensions.basic.entries.sequence.actions

import com.typewritermc.authoring.GraphPlacement
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
import kotlin.random.Random

/**
 * Goes on through links drawn at random by their weights, [amount] draws with replacement; a link of weight zero is
 * never drawn. Its links carry their weights, so it has no plain triggers.
 */
@TypewriterType(id = "01a20277-8bab-7485-b441-9f0889c95fa3")
@TypewriterDisplay(
    name = "Weighted Random Trigger Gate",
    description = "A weighted random trigger gate.",
    icon = "jam:dices-f",
    color = Color.Hex.PINK,
)
class WeightedRandomTriggerGateEntry(
    override val page: Ref<PageElements.Element, SequencePage>,
    override val name: String,
    override val placement: GraphPlacement,
    val links: List<WeightedLink>,
    val amount: Var<Int, InteractionContext> = Var.Value(1),
) : SequenceEntry

/** One link of a weighted gate: a link with a higher [weight] is drawn more often. */
@TypewriterType(id = "01a20277-8bab-7485-b441-9f09dd15dd3e")
data class WeightedLink(
    val link: Ref<SequenceTriggers.Entry, SequenceEntry>,
    val weight: Int = 1,
)

/**
 * Fires [amount] links drawn by weight, with replacement, for the subject the chain runs for; a gate whose weights are
 * all zero fires nothing. The draw uses an unseeded random until the chain carries its seed record.
 */
@Handler
suspend fun Triggered<WeightedRandomTriggerGateEntry>.pickWeighted(amount: Int) {
    val drawable = entry.links.filter { it.weight > 0 }
    if (drawable.isEmpty()) return
    val total = drawable.sumOf { it.weight.toLong() }
    List(amount.coerceAtLeast(0)) { drawable.drawn(Random.nextLong(total)) }.fire(context, subject)
}

/** The link whose share of the cumulative weights holds [roll], a number from zero up to the total weight. */
private fun List<WeightedLink>.drawn(roll: Long): Ref<SequenceTriggers.Entry, SequenceEntry> {
    var remaining = roll
    return first { link -> (remaining < link.weight).also { remaining -= link.weight } }.link
}
