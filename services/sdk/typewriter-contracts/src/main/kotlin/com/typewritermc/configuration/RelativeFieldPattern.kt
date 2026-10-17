package com.typewritermc.configuration

import com.typewritermc.types.catalog.ResolvedRepresentation
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class RelativeFieldPattern(
    val segments: List<FieldPatternSegment> = emptyList(),
)

@Serializable
sealed interface FieldPatternSegment {
    @Serializable
    @SerialName("field")
    data class Field(
        val name: String,
    ) : FieldPatternSegment

    @Serializable
    @SerialName("items")
    data object Items : FieldPatternSegment

    @Serializable
    @SerialName("keys")
    data object Keys : FieldPatternSegment

    @Serializable
    @SerialName("values")
    data object Values : FieldPatternSegment
}

@Serializable
enum class RepresentationKind {
    Unit,
    Boolean,
    Text,
    Bytes,
    Integer,
    Float,
    Decimal,
    Timestamp,
    Duration,
    Record,
    List,
    Set,
    Map,
    Enum,
    Link,
}

fun ResolvedRepresentation.kind(): RepresentationKind =
    when (this) {
        is ResolvedRepresentation.Scalar -> {
            when (kind) {
                com.typewritermc.types.ScalarKind.Unit -> RepresentationKind.Unit
                com.typewritermc.types.ScalarKind.Boolean -> RepresentationKind.Boolean
                com.typewritermc.types.ScalarKind.Text -> RepresentationKind.Text
                com.typewritermc.types.ScalarKind.Bytes -> RepresentationKind.Bytes
                is com.typewritermc.types.ScalarKind.Integer -> RepresentationKind.Integer
                is com.typewritermc.types.ScalarKind.Float -> RepresentationKind.Float
                com.typewritermc.types.ScalarKind.Decimal -> RepresentationKind.Decimal
                com.typewritermc.types.ScalarKind.Timestamp -> RepresentationKind.Timestamp
                com.typewritermc.types.ScalarKind.Duration -> RepresentationKind.Duration
            }
        }

        is ResolvedRepresentation.Record -> {
            RepresentationKind.Record
        }

        is ResolvedRepresentation.Sequence -> {
            when (kind) {
                com.typewritermc.types.CollectionKind.List -> RepresentationKind.List
                com.typewritermc.types.CollectionKind.Set -> RepresentationKind.Set
            }
        }

        is ResolvedRepresentation.Mapping -> {
            RepresentationKind.Map
        }

        is ResolvedRepresentation.Enumeration -> {
            RepresentationKind.Enum
        }

        is ResolvedRepresentation.Link -> {
            RepresentationKind.Link
        }
    }
