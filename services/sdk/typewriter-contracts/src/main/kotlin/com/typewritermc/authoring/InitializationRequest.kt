package com.typewritermc.authoring

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.CapturedDefault
import com.typewritermc.types.DataValue
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.TypeDefinitionId
import kotlinx.serialization.Serializable

@Serializable
data class InitializationDescriptor(
    val definition: TypeDefinitionId,
    val mode: InitializationMode,
    val captured: List<CapturedDefault>,
    val diagnostics: List<InitializationDiagnostic>,
)

@Serializable
enum class InitializationMode {
    Startup,
    Creation,
}

@Serializable
data class InitializationRequest(
    val id: InitializationRequestId,
    val catalog: CatalogGeneration,
    val type: TypeSelection,
    val supplied: Map<String, DataValue>,
    val intentHash: String,
)

@Serializable
data class PreparedCreation(
    val record: AuthoringRecord,
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
