package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.DataSerializer.Companion.toDataSerializer
import com.typewritermc.core.serialization.xmap
import kotlinx.serialization.builtins.serializer
import java.lang.reflect.Type

class ColorSerializer : DataSerializer<Color>
by Int.serializer().xmap(Color::color, ::Color).toDataSerializer()