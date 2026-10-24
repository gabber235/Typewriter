package com.typewritermc.configuration

import com.typewritermc.types.unknownVariant
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.NamedFieldPatternSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind

/** The pattern of the owning occurrence itself, with no segments. */
val RelativeFieldPattern.Companion.root: RelativeFieldPattern get() = ROOT_PATTERN

private val ROOT_PATTERN = RelativeFieldPattern(segments = emptyList())

/** A pattern of [segments] relative to the owning occurrence. */
fun RelativeFieldPattern.Companion.of(vararg segments: FieldPatternSegment): RelativeFieldPattern =
    RelativeFieldPattern(segments = segments.toList())

/** The segment that selects the record field [name]. */
fun FieldPatternSegment.Companion.field(name: String): FieldPatternSegment.FieldWrapper =
    FieldPatternSegment.FieldWrapper(NamedFieldPatternSegment(name = name))

/** The record field name this segment selects. */
val FieldPatternSegment.FieldWrapper.name: String get() = value.name

/** Checks the segments of a pattern read from outside the runtime: known segments and non blank field names. */
fun RelativeFieldPattern.requireValid(): RelativeFieldPattern =
    apply {
        segments.forEach { segment ->
            when (segment) {
                is FieldPatternSegment.FieldWrapper -> require(segment.name.isNotBlank()) { "Field pattern names must not be blank." }
                FieldPatternSegment.ITEMS, FieldPatternSegment.KEYS, FieldPatternSegment.VALUES -> Unit
                else -> throw IllegalArgumentException("Unknown field pattern segment.")
            }
        }
    }

fun ResolvedRepresentation.kind(): RepresentationKind =
    when (this) {
        is ResolvedRepresentation.ScalarWrapper -> {
            when (val kind = value.kind) {
                ScalarKind.UNIT -> RepresentationKind.UNIT
                ScalarKind.BOOLEAN -> RepresentationKind.BOOLEAN
                ScalarKind.TEXT -> RepresentationKind.TEXT
                ScalarKind.BYTES -> RepresentationKind.BYTES
                is ScalarKind.IntegerWrapper -> RepresentationKind.INTEGER
                is ScalarKind.FloatWrapper -> RepresentationKind.FLOAT
                ScalarKind.DECIMAL -> RepresentationKind.DECIMAL
                ScalarKind.TIMESTAMP -> RepresentationKind.TIMESTAMP
                ScalarKind.DURATION -> RepresentationKind.DURATION
                else -> unknownVariant(kind)
            }
        }

        is ResolvedRepresentation.RecordWrapper -> {
            RepresentationKind.RECORD
        }

        is ResolvedRepresentation.SequenceWrapper -> {
            when (val kind = value.kind) {
                CollectionKind.LIST -> RepresentationKind.LIST
                CollectionKind.SET -> RepresentationKind.SET
                else -> unknownVariant(kind)
            }
        }

        is ResolvedRepresentation.MappingWrapper -> {
            RepresentationKind.MAP
        }

        is ResolvedRepresentation.EnumerationWrapper -> {
            RepresentationKind.ENUMERATION
        }

        is ResolvedRepresentation.LinkWrapper -> {
            RepresentationKind.LINK
        }

        else -> {
            unknownVariant(this)
        }
    }
