package com.typewritermc.extensions.basic.entries.sequence.events

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.engine.events.Triggerable
import com.typewritermc.engine.events.fire
import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.engine.pages.SequencePage
import com.typewritermc.engine.pages.SequenceTriggers
import com.typewritermc.events.Candidate
import com.typewritermc.events.Handler
import com.typewritermc.extensions.basic.events.Tick
import com.typewritermc.extensions.basic.events.TickConfig
import com.typewritermc.identity.Protagonist
import com.typewritermc.library.PageElements
import com.typewritermc.types.Color
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType

/**
 * Starts its links for every online player its book applies to, once every [interval] server ticks. Each published
 * entry is one [Tick] configuration, so the Paper source only counts the intervals that content uses.
 */
@TypewriterType(id = INTERVAL_EVENT_ENTRY_TYPE_ID)
@TypewriterDisplay(
    name = "Interval Event Entry",
    description = "Starts its links for every player once every few ticks.",
    icon = "mdi:timer-sync-outline",
    color = Color.Hex.YELLOW,
)
data class IntervalEventEntry(
    override val page: Ref<PageElements.Element, SequencePage>,
    override val name: String,
    override val placement: GraphPlacement,
    override val triggers: Set<Ref<SequenceTriggers.Entry, SequenceEntry>> = emptySet(),
    override val interval: Int = 20,
) : Triggerable,
    TickConfig

/**
 * Starts the entry's chain for each online player once its interval comes round. A tick has no subject, so the
 * protagonist parameter makes this run once per online player, and the candidate is the entry the tick is for.
 */
@Handler
suspend fun Tick<IntervalEventEntry>.start(
    @Suppress("UNUSED_PARAMETER") protagonist: Protagonist,
    entry: Candidate<IntervalEventEntry>,
) {
    entry.fire()
}

const val INTERVAL_EVENT_ENTRY_TYPE_ID = "6bbaf8ac6ffc422abe9f7ec18dc8258a"
