package com.typewritermc.types.catalog

import com.typewritermc.types.CollectionKind
import com.typewritermc.types.EndpointId
import com.typewritermc.types.EnumVariant
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeUse
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

data class AppliedSchema(
    val use: TypeUse,
    val representation: ResolvedRepresentation,
    val fields: List<ResolvedField>,
    val ancestors: Set<TypeUse.Named>,
)

@Serializable
sealed interface ResolvedRepresentation {
    @Serializable
    @SerialName("scalar")
    data class Scalar(
        val kind: ScalarKind,
    ) : ResolvedRepresentation

    @Serializable
    @SerialName("record")
    data class Record(
        val fields: List<ResolvedField>,
        val abstract: Boolean,
    ) : ResolvedRepresentation

    @Serializable
    @SerialName("sequence")
    data class Sequence(
        val item: TypeUse,
        val kind: CollectionKind,
    ) : ResolvedRepresentation

    @Serializable
    @SerialName("mapping")
    data class Mapping(
        val key: TypeUse,
        val value: TypeUse,
    ) : ResolvedRepresentation

    @Serializable
    @SerialName("enumeration")
    data class Enumeration(
        val cases: List<EnumVariant>,
    ) : ResolvedRepresentation

    @Serializable
    @SerialName("link")
    data class Link(
        val endpoint: EndpointId,
        val target: TypeUse,
    ) : ResolvedRepresentation
}
