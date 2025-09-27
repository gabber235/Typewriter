package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.serialization.DataSerializer
import org.bukkit.potion.PotionEffectType
import java.lang.reflect.Type

class PotionEffectTypeSerializer : DataSerializer<PotionEffectType> {
    override val type: Type = PotionEffectType::class.java

    override fun serialize(src: PotionEffectType, typeOfSrc: Type, context: JsonSerializationContext): JsonElement {
        @Suppress("DEPRECATION")
        return JsonPrimitive(src.name)
    }

    override fun deserialize(
        json: JsonElement,
        typeOfT: Type,
        context: JsonDeserializationContext
    ): PotionEffectType {
        if (!json.isJsonPrimitive || !json.asJsonPrimitive.isString) {
            return PotionEffectType.SPEED
        }
        @Suppress("DEPRECATION")
        return PotionEffectType.getByName(json.asString) ?: PotionEffectType.SPEED
    }
}