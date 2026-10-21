package com.typewritermc.authoring

import com.typewritermc.types.DataValue
import skirout.editor.v1.type_catalog.FieldOwner

interface NativeConstructionPlan {
    val defaultedFields: Set<FieldOwner>

    fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult
}

sealed interface CaptureResult {
    data class Captured(
        val values: Map<FieldOwner, DataValue>,
    ) : CaptureResult

    data class Unavailable(
        val reasons: List<InitializationDiagnostic>,
    ) : CaptureResult
}
