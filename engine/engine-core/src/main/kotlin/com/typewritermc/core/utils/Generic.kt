package com.typewritermc.core.utils

import kotlinx.serialization.Serializable
import kotlinx.serialization.Transient
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.double
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonNull
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.serializer
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import kotlin.reflect.KClass
import kotlin.reflect.full.starProjectedType

@Serializable
class Generic(
    val data: JsonElement,
) : Comparable<Generic>, KoinComponent {
    companion object {
        val Empty = Generic(JsonObject(emptyMap()))
    }

    private val jsonFormat: Json by inject(named("dataSerializer"))

    fun <T> get(klass: Class<T>): T? {
        return jsonFormat.decodeFromJsonElement(jsonFormat.serializersModule.serializer(klass),data) as T?
    }

    fun <T : Any> get(klass: KClass<T>): T? {
        return jsonFormat.decodeFromJsonElement(jsonFormat.serializersModule.serializer(klass.starProjectedType),data) as T?
    }

    override fun compareTo(other: Generic): Int {
        if (this === other) return 0
        if (other.data is JsonNull) return 1
        if (data is JsonNull) return -1
        if (data is JsonPrimitive && other.data is JsonPrimitive) {
            if (data.jsonPrimitive.booleanOrNull != null && other.data.jsonPrimitive.booleanOrNull != null) {
                return data.jsonPrimitive.boolean.compareTo(other.data.jsonPrimitive.boolean)
            }
            if (data.jsonPrimitive.doubleOrNull != null && other.data.jsonPrimitive.doubleOrNull != null) {
                return data.jsonPrimitive.double.compareTo(other.data.jsonPrimitive.double)
            }
            return data.jsonPrimitive.toString().compareTo(other.data.toString())
        }
        // TODO maybe check recursively?
        if (data is JsonObject && other.data is JsonObject) {
            return data.size.compareTo(other.data.size)
        }
        if (data is JsonArray && other.data is JsonArray) {
            return data.jsonArray.size.compareTo(other.data.jsonArray.size)
        }
        return 0
    }
}

inline fun <reified T> Generic.get(): T? {
    return get(T::class.java)
}