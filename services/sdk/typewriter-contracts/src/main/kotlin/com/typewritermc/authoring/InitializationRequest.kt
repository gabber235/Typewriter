package com.typewritermc.authoring

import com.typewritermc.types.unknownVariant
import skirout.editor.v1.catalog.PrepareValueResult
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.type_catalog.AuthoringRecord

val PreparedContent.RecordWrapper.record: AuthoringRecord get() = value

/**
 * Materializes unfinished editor values without starting an interactive creation flow. Only ready, needs input and
 * unavailable steps carry content; preparation reports catalog changes and failures separately.
 */
fun PrepareValueResult.materialize(): PreparedValue =
    when (this) {
        is PrepareValueResult.ReadyWrapper -> value
        is PrepareValueResult.NeedsInputWrapper -> PreparedValue(content = value.content, findings = value.findings)
        is PrepareValueResult.UnavailableErrorWrapper -> PreparedValue(content = value.content, findings = value.findings)
        else -> unknownVariant(this)
    }
