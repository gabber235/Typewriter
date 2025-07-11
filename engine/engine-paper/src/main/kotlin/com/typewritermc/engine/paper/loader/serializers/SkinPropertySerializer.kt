package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.typewritermc.engine.paper.entry.entity.SkinProperty
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.DataSerializer.Companion.toDataSerializer
import com.typewritermc.core.serialization.serializer
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.builtins.serializer
import java.lang.reflect.Type

class SkinPropertySerializer : DataSerializer<SkinProperty> by SkinProperty.serializer().toDataSerializer()