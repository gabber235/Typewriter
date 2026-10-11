package com.typewritermc.extensions.basic.entries.sequence

import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.types.Many
import com.typewritermc.types.ReferenceContract

@ReferenceContract(SEQUENCE_TRIGGERS_RELATION_ID)
interface SequenceTriggersContract {
    interface Entry : Many<SequenceEntry>

    interface Trigger : Many<SequenceEntry>
}

const val SEQUENCE_TRIGGERS_RELATION_ID = "01a0b1fcd60f743faef85dce1c4ad201"
