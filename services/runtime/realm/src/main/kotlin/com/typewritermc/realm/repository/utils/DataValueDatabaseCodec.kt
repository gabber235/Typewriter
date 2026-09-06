package com.typewritermc.realm.repository.utils

import com.surrealdb.Value
import com.typewritermc.types.DataValue
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull

/**
 * Stores portable values in a versioned database envelope using explicit variant discriminators.
 *
 * Decode requires the supported storage format and known database value shapes. Reference slot projection remains
 * encoded in the value tree; this codec does not resolve edges.
 */
internal object DataValueDatabaseCodec {
    private val json = Json { classDiscriminator = "kind" }

    fun encode(value: DataValue): Map<String, Any?> =
        mapOf(
            "format" to STORAGE_FORMAT,
            "data" to json.encodeToJsonElement(DataValue.serializer(), value).databaseValue(),
        )

    fun decode(value: Value): DataValue {
        val stored = value.requireObject()
        require(stored.get("format").getLong() == STORAGE_FORMAT.toLong()) { "Unsupported element value storage format." }
        return json.decodeFromJsonElement(DataValue.serializer(), stored.get("data").jsonElement())
    }
}

private fun JsonElement.databaseValue(): Any? =
    when (this) {
        JsonNull -> {
            null
        }

        is JsonArray -> {
            map(JsonElement::databaseValue)
        }

        is JsonObject -> {
            mapValues { it.value.databaseValue() }
        }

        is JsonPrimitive -> {
            when {
                isString -> content
                booleanOrNull != null -> booleanOrNull
                longOrNull != null -> longOrNull
                else -> doubleOrNull ?: error("Unsupported JSON primitive $this")
            }
        }
    }

private fun Value.jsonElement(): JsonElement =
    when {
        isNull || isNone -> JsonNull
        isBoolean -> JsonPrimitive(getBoolean())
        isLong -> JsonPrimitive(getLong())
        isDouble -> JsonPrimitive(getDouble())
        isBigDecimal -> JsonPrimitive(getBigDecimal())
        isString -> JsonPrimitive(getString())
        isArray -> JsonArray(getArray().map(Value::jsonElement))
        isObject -> JsonObject(getObject().associate { it.key to it.value.jsonElement() })
        else -> error("Unsupported stored element value $this")
    }

private fun Value.requireObject(): com.surrealdb.Object {
    require(isObject) { "Stored element values must be objects." }
    return getObject()
}

private const val STORAGE_FORMAT = 1
