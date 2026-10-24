package com.typewritermc.types

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
sealed interface ScalarKind {
    @Serializable
    @SerialName("unit")
    data object Unit : ScalarKind

    @Serializable
    @SerialName("boolean")
    data object Boolean : ScalarKind

    @Serializable
    @SerialName("text")
    data object Text : ScalarKind

    @Serializable
    @SerialName("bytes")
    data object Bytes : ScalarKind

    @Serializable
    @SerialName("integer")
    data class Integer(
        val width: IntegerWidth,
    ) : ScalarKind

    @Serializable
    @SerialName("float")
    data class Float(
        val width: FloatWidth,
    ) : ScalarKind

    @Serializable
    @SerialName("decimal")
    data object Decimal : ScalarKind

    @Serializable
    @SerialName("timestamp")
    data object Timestamp : ScalarKind

    @Serializable
    @SerialName("duration")
    data object Duration : ScalarKind
}

@Serializable
enum class CollectionKind {
    List,
    Set,
}

@Serializable
data class EnumVariant(
    val key: String,
) {
    init {
        require(key.isNotBlank()) { "Enum variant key must not be blank." }
    }
}

@Serializable
sealed interface RepresentationTemplate {
    @Serializable
    @SerialName("scalar")
    data class Scalar(
        val kind: ScalarKind,
    ) : RepresentationTemplate

    @Serializable
    @SerialName("record")
    data class Record(
        val fields: List<FieldDeclaration>,
        val abstract: kotlin.Boolean = false,
    ) : RepresentationTemplate

    @Serializable
    @SerialName("sequence")
    data class Sequence(
        val item: TypeTemplate,
        val kind: CollectionKind,
    ) : RepresentationTemplate

    @Serializable
    @SerialName("mapping")
    data class Mapping(
        val key: TypeTemplate,
        val value: TypeTemplate,
    ) : RepresentationTemplate

    @Serializable
    @SerialName("enumeration")
    data class Enumeration(
        val cases: List<EnumVariant>,
    ) : RepresentationTemplate

    @Serializable
    @SerialName("link")
    data class Link(
        val endpoint: EndpointId,
        val target: TypeTemplate,
    ) : RepresentationTemplate
}
