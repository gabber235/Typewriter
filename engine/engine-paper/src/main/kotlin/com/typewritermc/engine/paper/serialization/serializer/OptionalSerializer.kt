package com.typewritermc.engine.paper.serialization.serializer

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.serializer
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.lang.reflect.ParameterizedType
import java.lang.reflect.Type
import java.util.*
import kotlin.jvm.optionals.getOrNull

class OptionalSerializer<T: Any>(tSerializer: KSerializer<T>) : KSerializer<Optional<*>> by serializer(
    "enabled", { isPresent }, Boolean.serializer(),
    "value", { getOrNull() as T? }, tSerializer.nullable,
    { enabled, value ->
        if (enabled) Optional.of(value)
        else Optional.empty()
    }
)