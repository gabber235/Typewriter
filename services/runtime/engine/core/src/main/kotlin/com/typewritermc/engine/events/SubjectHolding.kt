package com.typewritermc.engine.events

import com.typewritermc.identity.Protagonist

/**
 * Whether this engine holds a session of a protagonist. An event about a protagonist it does not hold runs none of its
 * handlers here and is dropped, until cross engine delivery forwards it to the engine that does.
 */
fun interface SubjectHolding {
    fun holds(protagonist: Protagonist): Boolean
}
