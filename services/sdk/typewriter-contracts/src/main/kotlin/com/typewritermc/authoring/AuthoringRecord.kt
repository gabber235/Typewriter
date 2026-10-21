package com.typewritermc.authoring

import com.typewritermc.types.DataValue
import com.typewritermc.types.skir.NamedTypeUseSerializer
import com.typewritermc.types.skir.TypeDefinitionIdSerializer
import com.typewritermc.types.skir.TypeUseSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.ResolvedField
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

@Serializable
sealed interface ArgumentSelection {
    @Serializable
    @SerialName("chosen")
    data class Chosen(
        @Serializable(with = TypeUseSerializer::class)
        val type: TypeUse,
    ) : ArgumentSelection

    @Serializable
    @SerialName("unfilled")
    data object Unfilled : ArgumentSelection
}

/**
 * Tracks authored type arguments while a record is being edited.
 *
 * [Pending] can retain an unfilled argument without inventing a concrete type. [Complete] describes filled type
 * arguments, not completed field values or a successful catalog check.
 */
@Serializable
sealed interface TypeSelection {
    @Serializable
    @SerialName("complete")
    data class Complete(
        @Serializable(with = NamedTypeUseSerializer::class)
        val use: NamedTypeUse,
    ) : TypeSelection

    @Serializable
    @SerialName("pending")
    data class Pending(
        @Serializable(with = TypeDefinitionIdSerializer::class)
        val definition: TypeDefinitionId,
        val arguments: List<ArgumentSelection>,
    ) : TypeSelection
}

/** The selected type, complete or pending. */
val TypeSelection.definition: TypeDefinitionId
    get() =
        when (this) {
            is TypeSelection.Complete -> use.definition
            is TypeSelection.Pending -> definition
        }

/**
 * Stores a resource's type selection separately from its field payload so partially configured records remain editable.
 * Nested nominal values still carry their own actual types in [DataValue.Named].
 */
@Serializable
data class AuthoringRecord(
    val configuration: TypeSelection,
    val fields: Map<String, DataValue>,
)

data class ArgumentLocation(
    val index: Int,
)

data class DependentField(
    val owner: FieldOwner,
    val type: TypeTemplate,
    val missing: Set<ParameterKey>,
)

data class PartialSchema(
    val knownFields: List<ResolvedField>,
    val dependentFields: List<DependentField>,
    val pendingArguments: List<ArgumentLocation>,
)
