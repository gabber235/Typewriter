package com.typewritermc.engine.paper.loader.serializers

import com.google.common.reflect.TypeToken
import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.serialization.DataSerializer
import java.lang.reflect.ParameterizedType
import java.lang.reflect.Type
import kotlin.reflect.KClass

class EntryReferenceSerializer : DataSerializer<Ref<*>> {
    override val type: Type = Ref::class.java

    override fun serialize(src: Ref<*>?, typeOfSrc: Type?, context: JsonSerializationContext?): JsonElement {
        return JsonPrimitive(src?.id ?: "")
    }

    override fun deserialize(
        json: JsonElement?,
        typeOfT: Type?,
        context: JsonDeserializationContext?
    ): Ref<*> {
        val subType = (typeOfT as ParameterizedType).actualTypeArguments[0]
        val clazz = TypeToken.of(subType).rawType
        if (!Entry::class.java.isAssignableFrom(clazz)) {
            throw IllegalArgumentException("Type $clazz is not a valid Entry type")
        }
        @Suppress("UNCHECKED_CAST")
        val klass = clazz.kotlin as KClass<Entry>

        if (json?.isJsonNull == true) {
            return Ref("", klass)
        }

        val id = json?.asString ?: ""
        return Ref(id, klass)
    }
}