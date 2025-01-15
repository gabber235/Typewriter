package com.typewritermc.core.utils

import com.google.gson.Gson
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import kotlin.reflect.KClass

class Generic(
    val data: JsonElement,
) : Comparable<Generic>, KoinComponent {
    companion object {
        val Empty = Generic(JsonObject())
    }

    private val gson: Gson by inject(named("dataSerializer"))

    fun <T> get(klass: Class<T>): T? {
        return gson.fromJson(data, klass)
    }

    fun <T : Any> get(klass: KClass<T>): T? {
        return gson.fromJson(data, klass.java)
    }

    override fun compareTo(other: Generic): Int {
        if (this === other) return 0
        if (other.data.isJsonNull) return 1
        if (data.isJsonNull) return -1
        if (data.isJsonPrimitive && other.data.isJsonPrimitive) {
            if (data.asJsonPrimitive.isBoolean && other.data.asJsonPrimitive.isBoolean) {
                return data.asBoolean.compareTo(other.data.asBoolean)
            }
            if (data.asJsonPrimitive.isNumber && other.data.asJsonPrimitive.isNumber) {
                return data.asJsonPrimitive.asNumber.toDouble()
                    .compareTo(other.data.asJsonPrimitive.asNumber.toDouble())
            }
            return data.asString.compareTo(other.data.asString)
        }
        if (data.isJsonObject && other.data.isJsonObject) {
            data.asJsonObject.size().compareTo(other.data.asJsonObject.size())
        }
        if (data.isJsonArray && other.data.isJsonArray) {
            data.asJsonArray.size().compareTo(other.data.asJsonArray.size())
        }
        return 0
    }
}

inline fun <reified T> Generic.get(): T? {
    return get(T::class.java)
}
