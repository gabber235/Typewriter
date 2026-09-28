package com.typewritermc.realm.repository.utils

import com.surrealdb.Value
import kotlinx.serialization.KSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull

/** Encodes typed metadata as structured Surreal objects without string serialization. */
internal object StructuredDatabaseCodec {
    private val json = Json { classDiscriminator = "kind" }

    fun <T> encode(
        serializer: KSerializer<T>,
        value: T,
    ): Any? = json.encodeToJsonElement(serializer, value).databaseValue()

    fun <T> decode(
        serializer: KSerializer<T>,
        value: Value,
    ): T = json.decodeFromJsonElement(serializer, value.jsonElement())
}

internal fun JsonElement.databaseValue(): Any? =
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

internal fun Value.jsonElement(): JsonElement =
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
