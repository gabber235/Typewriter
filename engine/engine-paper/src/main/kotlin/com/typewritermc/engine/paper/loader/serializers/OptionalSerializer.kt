package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.serialization.DataSerializer
import java.lang.reflect.ParameterizedType
import java.lang.reflect.Type
import java.util.*

class OptionalSerializer : DataSerializer<Optional<*>> {
    override val clazz: Type = Optional::class.java

    override fun serialize(src: Optional<*>?, typeOfSrc: Type?, context: JsonSerializationContext?): JsonElement {
        val obj = JsonObject()
        obj.addProperty("enabled", src?.isPresent ?: false)

        if (src?.isPresent == true) {
            val value = src.get()
            val valueElement = context?.serialize(value)
            obj.add("value", valueElement)
        }

        return obj
    }

    override fun deserialize(json: JsonElement?, typeOfT: Type?, context: JsonDeserializationContext?): Optional<*> {
        val obj = json?.asJsonObject ?: JsonObject()
        val enabled = obj.get("enabled")?.asBoolean ?: false
        if (!enabled) return Optional.empty<Any>()

        val valueElement = obj.get("value")
        val actualType = (typeOfT as? ParameterizedType)?.actualTypeArguments?.get(0)
        val value: Any? = context?.deserialize(valueElement, actualType)
        return Optional.ofNullable(value)
    }
}