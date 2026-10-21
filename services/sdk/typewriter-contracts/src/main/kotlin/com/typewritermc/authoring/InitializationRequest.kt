package com.typewritermc.authoring

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.skir.DataValueSerializer
import com.typewritermc.types.skir.FieldOwnerSerializer
import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.TypeUse

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

@Serializable
sealed interface PreparedContent {
    @Serializable
    data class Value(
        @Serializable(with = DataValueSerializer::class)
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
    @Serializable(with = FieldOwnerSerializer::class)
    val field: FieldOwner?,
    val code: String,
    val message: String,
    val relativePath: ValuePath? = null,
)

/** A caller owned continuation of initialization, retaining evaluated values and deferred defaults. */
data class PreparationDraft(
    val catalog: CatalogGeneration,
    val target: PreparationTarget,
    val content: PreparedContent,
    val pendingDefaults: Set<ValuePath>,
    val requiredInputs: List<RequiredInput>,
    val findings: List<InitializationDiagnostic>,
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
        is PreparationStep.NeedsInput -> PreparedValue(draft.content, draft.findings)
        is PreparationStep.Unavailable -> PreparedValue(draft.content, draft.findings)
    }

data class LocatedInitializationDiagnostic(
    val location: ValueLocation,
    val diagnostic: InitializationDiagnostic,
)
