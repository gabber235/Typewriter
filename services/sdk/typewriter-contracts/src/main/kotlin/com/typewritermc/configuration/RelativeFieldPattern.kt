package com.typewritermc.configuration

import com.typewritermc.types.unknownVariant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind

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
        is ResolvedRepresentation.ScalarWrapper -> {
            when (val kind = value.kind) {
                ScalarKind.UNIT -> RepresentationKind.Unit
                ScalarKind.BOOLEAN -> RepresentationKind.Boolean
                ScalarKind.TEXT -> RepresentationKind.Text
                ScalarKind.BYTES -> RepresentationKind.Bytes
                is ScalarKind.IntegerWrapper -> RepresentationKind.Integer
                is ScalarKind.FloatWrapper -> RepresentationKind.Float
                ScalarKind.DECIMAL -> RepresentationKind.Decimal
                ScalarKind.TIMESTAMP -> RepresentationKind.Timestamp
                ScalarKind.DURATION -> RepresentationKind.Duration
                else -> unknownVariant(kind)
            }
        }

        is ResolvedRepresentation.RecordWrapper -> {
            RepresentationKind.Record
        }

        is ResolvedRepresentation.SequenceWrapper -> {
            when (val kind = value.kind) {
                CollectionKind.LIST -> RepresentationKind.List
                CollectionKind.SET -> RepresentationKind.Set
                else -> unknownVariant(kind)
            }
        }

        is ResolvedRepresentation.MappingWrapper -> {
            RepresentationKind.Map
        }

        is ResolvedRepresentation.EnumerationWrapper -> {
            RepresentationKind.Enum
        }

        is ResolvedRepresentation.LinkWrapper -> {
            RepresentationKind.Link
        }

        else -> {
            unknownVariant(this)
        }
    }
