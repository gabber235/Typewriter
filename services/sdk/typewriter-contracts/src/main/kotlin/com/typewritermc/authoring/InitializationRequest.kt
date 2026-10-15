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

data class LocatedInitializationDiagnostic(
    val location: ValueLocation,
    val diagnostic: InitializationDiagnostic,
)
