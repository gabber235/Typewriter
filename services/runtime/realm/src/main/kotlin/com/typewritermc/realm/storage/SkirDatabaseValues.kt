package com.typewritermc.realm.repository.utils

import build.skir.JsonFlavor
import com.surrealdb.Value
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull
import build.skir.Serializer as SkirSerializer

/*
 * SurrealDB stores generated Skir values as their readable Skir JSON: records and unions stay objects, matching the
 * object columns of the schema, and field names are the stored keys. A field rename therefore changes stored data.
 * Readable timestamps are objects as well, so these functions never write a value into a datetime column.
 */

/** The readable Skir JSON of [value] as a structured Surreal value. */
internal fun <T> encodeSkir(
    serializer: SkirSerializer<T>,
    value: T,
): Any? = serializer.toJson(value, JsonFlavor.READABLE).databaseValue()

/** Reads a value stored by [encodeSkir]. Callers check the invariants of the result where it enters the runtime. */
internal fun <T> decodeSkir(
    serializer: SkirSerializer<T>,
    value: Value,
): T = serializer.fromJson(value.jsonElement())

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
