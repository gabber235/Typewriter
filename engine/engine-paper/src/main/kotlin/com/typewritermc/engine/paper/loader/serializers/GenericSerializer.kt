package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.utils.Generic
import java.lang.reflect.Type

class GenericSerializer : DataSerializer<Generic> {
    override val type: Type = Generic::class.java

    override fun serialize(src: Generic, typeOfSrc: Type, context: JsonSerializationContext): JsonElement {
        return src.data
    }
    override fun deserialize(json: JsonElement, typeOfT: Type, context: JsonDeserializationContext): Generic {
        return Generic(json)
    }
}