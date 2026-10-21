package com.typewritermc.authoring

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.immutableListCopy
import com.typewritermc.types.immutableSetCopy
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.diagnostic.InitializationDiagnostic
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

data class InitializationRequest(
    val catalog: CatalogGeneration,
    val target: PreparationTarget,
    /** A complete authored value for [PreparationTarget.Value], or partial record fields for [PreparationTarget.Record]. */
    val supplied: DataValue?,
)

sealed interface PreparationTarget {
    data class Value(
        val type: TypeUse,
    ) : PreparationTarget

    data class Record(
        val selection: TypeSelection,
    ) : PreparationTarget
}

val PreparedContent.RecordWrapper.record: AuthoringRecord get() = value

/** A caller owned continuation of initialization, retaining evaluated values and deferred defaults. */
data class PreparationDraft(
    val catalog: CatalogGeneration,
    val target: PreparationTarget,
    val content: PreparedContent,
    val pendingDefaults: Set<ValuePath>,
    val requiredInputs: List<RequiredInput>,
    val findings: List<InitializationDiagnostic>,
)

/** Copies the Kotlin collections of this draft, so a continuation retains no caller supplied collection. */
fun PreparationDraft.immutableCopy(): PreparationDraft =
    copy(
        pendingDefaults = pendingDefaults.immutableSetCopy(),
        requiredInputs = requiredInputs.immutableListCopy(),
        findings = findings.immutableListCopy(),
    )

data class RequiredInput(
    val path: ValuePath,
    val expected: TypeUse,
)

data class InputAnswer(
    val path: ValuePath,
    val value: DataValue,
)

sealed interface PreparationOperation {
    data class Start(
        val request: InitializationRequest,
    ) : PreparationOperation

    data class Resume(
        val draft: PreparationDraft,
        val answers: List<InputAnswer>,
    ) : PreparationOperation
}

sealed interface PreparationStep {
    data class Ready(
        val value: PreparedValue,
    ) : PreparationStep

    data class NeedsInput(
        val draft: PreparationDraft,
    ) : PreparationStep

    data class Unavailable(
        val draft: PreparationDraft,
    ) : PreparationStep
}

/** Materializes unfinished editor values without starting an interactive creation flow. */
fun PreparationStep.materialize(): PreparedValue =
    when (this) {
        is PreparationStep.Ready -> value
        is PreparationStep.NeedsInput -> PreparedValue(content = draft.content, findings = draft.findings)
        is PreparationStep.Unavailable -> PreparedValue(content = draft.content, findings = draft.findings)
    }

data class LocatedInitializationDiagnostic(
    val location: ValueLocation,
    val diagnostic: InitializationDiagnostic,
)
