package com.typewritermc.authoring

import skirout.editor.v1.diagnostic.InitializationDiagnostic
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldOwner

interface NativeConstructionPlan {
    val defaultedFields: Set<FieldOwner>

    fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult

    /**
     * Runs the Kotlin constructor with the [supplied] Kotlin values, every omitted field taking its Kotlin default.
     * What the constructor throws, an init check among it, reaches the caller unwrapped.
     */
    fun construct(supplied: Map<FieldOwner, Any?>): Any
}

sealed interface CaptureResult {
    data class Captured(
        val values: Map<FieldOwner, DataValue>,
    ) : CaptureResult

    data class Unavailable(
        val reasons: List<InitializationDiagnostic>,
    ) : CaptureResult
}
