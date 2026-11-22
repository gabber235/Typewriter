package com.typewritermc.engine.runtime

import com.typewritermc.events.EnginePart
import com.typewritermc.types.ResourceId
import skirout.editor.v1.type_catalog.PublicationId

/**
 * An engine part that hears each publication the engine newly applied, with the resources it compiles roots of. A test
 * host reads it to know when content it published runs on this engine.
 *
 * TODO(node 9): temporary test only signal; replace with the engine's reported active publication ("applied on N of M").
 */
interface PublicationObserver : EnginePart {
    fun applied(
        publication: PublicationId,
        resources: Set<ResourceId>,
    )
}
