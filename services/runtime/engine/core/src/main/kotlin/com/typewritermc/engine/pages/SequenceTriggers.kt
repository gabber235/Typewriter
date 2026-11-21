package com.typewritermc.extensions.basic.entries.sequence

import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.types.Many
import com.typewritermc.types.ReferenceContract

/**
 * Declares the directed links between authored sequence entries and their next triggered entries.
 *
 * The generated relation supplies typed references for entry fields; it does not execute the sequence.
 */
@ReferenceContract(SEQUENCE_TRIGGERS_RELATION_ID)
interface SequenceTriggersContract {
    interface Entry : Many<SequenceEntry>

    interface Trigger : Many<SequenceEntry>
}

const val SEQUENCE_TRIGGERS_RELATION_ID = "01a0b1fcd60f743faef85dce1c4ad201"
