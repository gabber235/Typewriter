package com.typewritermc.events

import com.typewritermc.identity.Protagonist

/** What a formula along a chain reads: the protagonist the chain runs for. */
interface InteractionContext {
    val protagonist: Protagonist
}

/** What a formula of an entry about one event reads: that event, beside the chain's protagonist. */
interface EventContext<E : Event> : InteractionContext {
    val event: E
}
