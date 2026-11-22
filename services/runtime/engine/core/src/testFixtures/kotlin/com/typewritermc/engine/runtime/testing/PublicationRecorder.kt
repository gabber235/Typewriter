package com.typewritermc.engine.runtime.testing

import com.typewritermc.engine.runtime.PublicationObserver
import com.typewritermc.types.ResourceId
import skirout.editor.v1.type_catalog.PublicationId

/** An engine part that records every publication it hears applied, with its roots, in order. */
class PublicationRecorder : PublicationObserver {
    val applied = mutableListOf<Pair<PublicationId, Set<ResourceId>>>()

    override fun applied(
        publication: PublicationId,
        resources: Set<ResourceId>,
    ) {
        applied += publication to resources
    }
}
