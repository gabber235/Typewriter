package com.typewritermc.types

import com.typewritermc.authoring.CanonicalValueHash
import com.typewritermc.authoring.CompleteValue
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.security.MessageDigest

interface CanonicalValueEquality {
    fun equivalent(
        left: CompleteValue,
        right: CompleteValue,
    ): Boolean

    fun hash(value: CompleteValue): CanonicalValueHash
}

object DefaultCanonicalValueEquality : CanonicalValueEquality {
    override fun equivalent(
        left: CompleteValue,
        right: CompleteValue,
    ): Boolean = left.schema.use == right.schema.use && left.value.canonicalValueKey() == right.value.canonicalValueKey()

    override fun hash(value: CompleteValue): CanonicalValueHash {
        val input = listOf(value.schema.use.semanticForm(), value.value.canonicalValueKey()).framed("value").encodeToByteArray()
        val digest = MessageDigest.getInstance("SHA256").digest(input)
        return CanonicalValueHash(digest.joinToString("") { byte -> "%02x".format(byte) })
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
        DataValue.Unfilled -> {
            "unfilled"
        }

        DataValue.Null -> {
            "null"
        }

        DataValue.Unit -> {
            "unit"
        }

        is DataValue.Boolean -> {
            "boolean:$value"
        }

        is DataValue.Integer -> {
            "integer:$value"
        }

        is DataValue.Float -> {
            "float:${value.toBits()}"
        }

        is DataValue.Decimal -> {
            "decimal:${value.toBigDecimal().stripTrailingZeros().toPlainString()}"
        }

        is DataValue.StringValue -> {
            "text:${value.length}:$value"
        }

        is DataValue.Bytes -> {
            "bytes:${value.joinToString(",")}"
        }

        is DataValue.Timestamp -> {
            "timestamp:$value"
        }

        is DataValue.Duration -> {
            "duration:$value"
        }

        is DataValue.EnumCase -> {
            "enum:${key.length}:$key"
        }

        is DataValue.Record -> {
            fields.entries
                .sortedBy(Map.Entry<String, DataValue>::key)
                .map { (key, value) ->
                    listOf(key, value.canonicalValueKey()).framed("field")
                }.framed("record")
        }

        is DataValue.Named -> {
            listOf(actualType.semanticForm(), payload.canonicalValueKey()).framed("named")
        }

        is DataValue.ListValue -> {
            items.map { it.value.canonicalValueKey() }.framed("list")
        }

        is DataValue.SetValue -> {
            items.map { it.value.canonicalValueKey() }.sorted().framed("set")
        }

        is DataValue.MapValue -> {
            rows
                .map { listOf(it.key.canonicalValueKey(), it.value.canonicalValueKey()).framed("row") }
                .sorted()
                .framed("map")
        }

        is DataValue.Link -> {
            listOf(endpoint.value, target.resource.value, Json.encodeToString(target.opposite)).framed("link")
        }
    }

private fun TypeUse.semanticForm(): String = Json.encodeToString(this)

private fun List<String>.framed(kind: String): String = "$kind:$size:" + joinToString("") { "${it.length}:$it" }
