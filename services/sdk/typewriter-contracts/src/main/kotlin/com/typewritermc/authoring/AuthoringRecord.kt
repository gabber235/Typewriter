package com.typewritermc.authoring

import com.typewritermc.types.DataValue
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.ResolvedField
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
sealed interface ArgumentSelection {
    @Serializable
    @SerialName("chosen")
    data class Chosen(
        val type: TypeUse,
    ) : ArgumentSelection

    @Serializable
    @SerialName("unfilled")
    data object Unfilled : ArgumentSelection
}

@Serializable
sealed interface TypeSelection {
    @Serializable
    @SerialName("complete")
    data class Complete(
        val use: TypeUse.Named,
    ) : TypeSelection

    @Serializable
    @SerialName("pending")
    data class Pending(
        val definition: TypeDefinitionId,
        val arguments: List<ArgumentSelection>,
    ) : TypeSelection
}

@Serializable
data class AuthoringRecord(
    val configuration: TypeSelection,
    val fields: Map<String, DataValue>,
)

@Serializable
data class ArgumentLocation(
    val index: Int,
)

@Serializable
data class DependentField(
    val owner: FieldOwner,
    val type: TypeTemplate,
    val missing: Set<ParameterKey>,
)

@Serializable
data class PartialSchema(
    val knownFields: List<ResolvedField>,
    val dependentFields: List<DependentField>,
    val pendingArguments: List<ArgumentLocation>,
)
