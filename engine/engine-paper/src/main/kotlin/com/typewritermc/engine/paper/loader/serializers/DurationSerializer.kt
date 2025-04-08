package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.serialization.DataSerializer
import java.lang.reflect.Type
import java.time.Duration

class DurationSerializer : DataSerializer<Duration> {
    override val type: Type = Duration::class.java

    override fun serialize(src: Duration?, typeOfSrc: Type?, context: JsonSerializationContext?): JsonElement {
        return JsonPrimitive(src?.toMillis() ?: 0)
    }

    override fun deserialize(
        json: JsonElement?,
        typeOfT: Type?,
        context: JsonDeserializationContext?
    ): Duration {
        if (json == null || !json.isJsonPrimitive || json.asJsonPrimitive.isNumber) {
            return Duration.ZERO
        }
        return Duration.ofMillis(json.asLong)
    }
}