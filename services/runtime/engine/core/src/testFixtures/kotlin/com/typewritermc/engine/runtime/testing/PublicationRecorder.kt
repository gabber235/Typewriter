package com.typewritermc.engine.runtime.testing

import com.typewritermc.engine.runtime.PublicationObserver
import skirout.editor.v1.type_catalog.PublicationId

/** An engine part that records every publication it hears applied, in order. */
class PublicationRecorder : PublicationObserver {
    val applied = mutableListOf<PublicationId>()

    override fun applied(publication: PublicationId) {
        applied += publication
    }
}
