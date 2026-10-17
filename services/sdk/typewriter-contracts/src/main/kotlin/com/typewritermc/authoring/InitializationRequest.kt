package com.typewritermc.authoring

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.DataValue
import com.typewritermc.types.FieldOwner
import kotlinx.serialization.Serializable

@Serializable
data class InitializationRequest(
    val catalog: CatalogGeneration,
    val target: PreparationTarget,
    /** A complete authored value for [PreparationTarget.Value], or partial record fields for [PreparationTarget.Record]. */
    val supplied: DataValue?,
)

@Serializable
sealed interface PreparationTarget {
    @Serializable
    data class Value(
        val type: com.typewritermc.types.TypeUse,
    ) : PreparationTarget

    @Serializable
    data class Record(
        val selection: TypeSelection,
    ) : PreparationTarget
}

@Serializable
sealed interface PreparedContent {
    @Serializable
    data class Value(
        val value: DataValue,
    ) : PreparedContent

    @Serializable
    data class Record(
        val record: AuthoringRecord,
    ) : PreparedContent
}

@Serializable
data class PreparedValue(
    val content: PreparedContent,
    val findings: List<InitializationDiagnostic>,
)

@Serializable
data class InitializationDiagnostic(
    val field: FieldOwner?,
    val code: String,
    val message: String,
    val relativePath: ValuePath? = null,
)

/** A caller owned continuation of initialization, retaining evaluated values and deferred defaults. */
@Serializable
data class PreparationDraft(
    val catalog: CatalogGeneration,
    val target: PreparationTarget,
    val content: PreparedContent,
    val pendingDefaults: Set<ValuePath>,
    val requiredInputs: List<RequiredInput>,
    val findings: List<InitializationDiagnostic>,
)

@Serializable
data class RequiredInput(
    val path: ValuePath,
    val expected: com.typewritermc.types.TypeUse,
)

@Serializable
data class InputAnswer(
    val path: ValuePath,
    val value: DataValue,
)

@Serializable
sealed interface PreparationOperation {
    @Serializable
    data class Start(
        val request: InitializationRequest,
    ) : PreparationOperation

    @Serializable
    data class Resume(
        val draft: PreparationDraft,
        val answers: List<InputAnswer>,
    ) : PreparationOperation
}

@Serializable
sealed interface PreparationStep {
    @Serializable
    data class Ready(
        val value: PreparedValue,
    ) : PreparationStep

    @Serializable
    data class NeedsInput(
        val draft: PreparationDraft,
    ) : PreparationStep

    @Serializable
    data class Unavailable(
        val draft: PreparationDraft,
    ) : PreparationStep
}

/** Materializes unfinished editor values without starting an interactive creation flow. */
fun PreparationStep.materialize(): PreparedValue =
    when (this) {
        is PreparationStep.Ready -> value
        is PreparationStep.NeedsInput -> PreparedValue(draft.content, draft.findings)
        is PreparationStep.Unavailable -> PreparedValue(draft.content, draft.findings)
    }

data class LocatedInitializationDiagnostic(
    val location: ValueLocation,
    val diagnostic: InitializationDiagnostic,
)
