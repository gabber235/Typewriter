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

    /** The Kotlin value of each stored field of [value], an instance of the plan's class, read as the constructor took it. */
    fun read(value: Any): Map<FieldOwner, Any?>
}

sealed interface CaptureResult {
    data class Captured(
        val values: Map<FieldOwner, DataValue>,
    ) : CaptureResult

    data class Unavailable(
        val reasons: List<InitializationDiagnostic>,
    ) : CaptureResult
}
