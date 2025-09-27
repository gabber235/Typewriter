package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.serialization.DataSerializer
import java.lang.reflect.ParameterizedType
import java.lang.reflect.Type

class ClosedRangeSerializer : DataSerializer<ClosedRange<*>> {
    override val type: Type = ClosedRange::class.java

    override fun serialize(src: ClosedRange<*>?, typeOfSrc: Type?, context: JsonSerializationContext?): JsonElement {
        val obj = JsonObject()
        obj.add("start", context?.serialize(src?.start))
        obj.add("end", context?.serialize(src?.endInclusive))
        return obj
    }

    override fun deserialize(json: JsonElement?, typeOfT: Type?, context: JsonDeserializationContext?): ClosedRange<*> {
        val obj = json?.asJsonObject ?: JsonObject()

        val actualType = (typeOfT as? ParameterizedType)?.actualTypeArguments?.get(0)

        val start: Any? = context?.deserialize(obj["start"], actualType)
        val end: Any? = context?.deserialize(obj["end"], actualType)

        if (start == null || end == null) {
            throw IllegalArgumentException("Invalid range")
        }

        val range = when (actualType?.typeName) {
            "java.lang.Integer" -> start as Int..end as Int
            "java.lang.Short" -> start as Short..end as Short
            "java.lang.Byte" -> start as Byte..end as Byte
            "java.lang.Long" -> start as Long..end as Long
            "java.lang.Double" -> start as Double..end as Double
            "java.lang.Float" -> start as Float..end as Float
            else -> null
        }
        if (range != null) return range

        if (actualType is Class<*> && Comparable::class.java.isAssignableFrom(actualType)) {
            @Suppress("UNCHECKED_CAST")
            return start as Comparable<Any>..end as Comparable<Any>
        }

        throw IllegalArgumentException("Invalid range type for $actualType")
    }
}