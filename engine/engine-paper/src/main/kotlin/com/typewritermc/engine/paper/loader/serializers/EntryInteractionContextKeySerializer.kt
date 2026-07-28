package com.typewritermc.engine.paper.loader.serializers

import com.google.common.reflect.TypeToken
import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.EntryInteractionContextKey
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.loader.ExtensionLoader
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.lang.reflect.Type
import kotlin.reflect.safeCast

class EntryInteractionContextKeySerializer : DataSerializer<EntryInteractionContextKey<*>>, KoinComponent {
    override val type: Type = EntryInteractionContextKey::class.java
    private val extensionLoader: ExtensionLoader by inject()

    override fun deserialize(
        json: JsonElement,
        typeOfT: Type,
        context: JsonDeserializationContext,
    ): EntryInteractionContextKey<*> {
        if (json !is JsonObject) throw IllegalArgumentException("Invalid json for EntryInteractionContextKey, expected JsonObject")
        val obj = json.asJsonObject
        val required = listOf("ref", "key", "keyClass")
        required.forEach {
            if (!obj.has(it)) throw IllegalArgumentException("Missing required field $it")
        }
        val ref = context.deserialize<Ref<Entry>>(obj["ref"], object : TypeToken<Ref<Entry>>() {}.type)
        if (!ref.isSet) return EntryInteractionContextKey<Any>()

        val keyClassString = obj["keyClass"]?.asString
            ?: return EntryInteractionContextKey<Any>()
        val keyClass = extensionLoader.loadClass(keyClassString)

        val key = context.deserialize<Any>(obj["key"], keyClass) ?: return EntryInteractionContextKey<Any>()
        val entryKey = EntryContextKey::class.safeCast(key)
            ?: throw IllegalArgumentException("Invalid keyClass, expected ${EntryContextKey::class.qualifiedName} but got $keyClass")

        return EntryInteractionContextKey<Any>(ref, entryKey)
    }

    override fun serialize(
        src: EntryInteractionContextKey<*>,
        typeOfSrc: Type,
        context: JsonSerializationContext,
    ): JsonElement {
        val obj = JsonObject()
        obj.add("ref", context.serialize(src.ref))
        obj.add("key", context.serialize(src.key))
        obj.addProperty("keyClass", src.key::class.java.name)
        return obj
    }
}