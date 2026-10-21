package com.typewritermc.types

import com.typewritermc.authoring.CanonicalValueHash
import com.typewritermc.authoring.CompleteValue
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath
import java.security.MessageDigest

interface CanonicalValueEquality {
    fun equivalent(
        left: CompleteValue,
        right: CompleteValue,
    ): Boolean

    fun hash(value: CompleteValue): CanonicalValueHash
}

/**
 * Compares admitted values by concrete schema and representation, independently of editor collection identities.
 * Lists preserve order; sets and maps compare sorted representation keys. Repeated entries remain significant.
 */
object DefaultCanonicalValueEquality : CanonicalValueEquality {
    override fun equivalent(
        left: CompleteValue,
        right: CompleteValue,
    ): Boolean = left.schema.use == right.schema.use && left.value.canonicalValueKey() == right.value.canonicalValueKey()

    override fun hash(value: CompleteValue): CanonicalValueHash {
        val input = listOf(value.schema.use.semanticForm(), value.value.canonicalValueKey()).framed("value").encodeToByteArray()
        val digest = MessageDigest.getInstance("SHA256").digest(input)
        return CanonicalValueHash(digest.toHexString())
    }
}

/**
 * Returns the stable representation equality key for an authored value.
 *
 * This key ignores collection item and row identities. It does not certify that the value is complete or valid for
 * any schema.
 */
fun DataValue.canonicalValueKey(): String =
    when (this) {
        DataValue.UNFILLED -> {
            "unfilled"
        }

        DataValue.NULL -> {
            "null"
        }

        DataValue.UNIT -> {
            "unit"
        }

        is DataValue.BooleanWrapper -> {
            "boolean:$value"
        }

        is DataValue.IntegerWrapper -> {
            "integer:$bigInteger"
        }

        is DataValue.FloatWrapper -> {
            "float:${value.toBits()}"
        }

        is DataValue.DecimalWrapper -> {
            "decimal:${value.toBigDecimal().stripTrailingZeros().toPlainString()}"
        }

        is DataValue.StringValueWrapper -> {
            "text:${value.length}:$value"
        }

        is DataValue.BytesWrapper -> {
            "bytes:${value.toByteArray().joinToString(",")}"
        }

        is DataValue.TimestampWrapper -> {
            "timestamp:$instant"
        }

        is DataValue.DurationWrapper -> {
            "duration:$duration"
        }

        is DataValue.EnumCaseWrapper -> {
            "enum:${value.length}:$value"
        }

        is DataValue.RecordWrapper -> {
            fields
                .sortedBy { it.name }
                .map { field -> listOf(field.name, field.value.canonicalValueKey()).framed("field") }
                .framed("record")
        }

        is DataValue.NamedWrapper -> {
            listOf(actualType.use.semanticForm(), payload.canonicalValueKey()).framed("named")
        }

        is DataValue.ListValueWrapper -> {
            items.map { it.value.canonicalValueKey() }.framed("list")
        }

        is DataValue.SetValueWrapper -> {
            items.map { it.value.canonicalValueKey() }.sorted().framed("set")
        }

        is DataValue.MapValueWrapper -> {
            rows
                .map { listOf(it.key.canonicalValueKey(), it.value.canonicalValueKey()).framed("row") }
                .sorted()
                .framed("map")
        }

        is DataValue.LinkWrapper -> {
            val opposite = value.target.opposite?.let(ValuePath.serializer::toJsonCode) ?: "null"
            listOf(value.endpoint.value, value.target.resource.value, opposite).framed("link")
        }

        else -> {
            unknownVariant(this)
        }
    }

private fun TypeUse.semanticForm(): String = canonicalText

private fun List<String>.framed(kind: String): String = "$kind:$size:" + joinToString("") { "${it.length}:$it" }
