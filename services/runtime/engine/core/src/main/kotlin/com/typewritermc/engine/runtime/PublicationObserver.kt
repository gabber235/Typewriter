package com.typewritermc.engine.runtime

import com.typewritermc.events.EnginePart
import skirout.editor.v1.type_catalog.PublicationId

/**
 * An engine part that hears each publication the engine newly applied. A test host reads it to know when the
 * publication it waits for runs on this engine.
 *
 * TODO(node 9): temporary test only signal; replace with the engine's reported active publication ("applied on N of M").
 */
interface PublicationObserver : EnginePart {
    fun applied(publication: PublicationId)
}
