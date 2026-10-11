package com.typewritermc.authoring

import com.typewritermc.types.DataValue
import com.typewritermc.types.FieldOwner

interface NativeConstructionPlan {
    val defaultedFields: Set<FieldOwner>

    fun sample(
        arguments: AppliedNativeArguments,
        requiredInputs: SamplingInputs,
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
