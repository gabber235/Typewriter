package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.DataSerializer.Companion.toDataSerializer
import com.typewritermc.engine.paper.plugin
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.serializer
import org.koin.core.component.get
import org.koin.core.qualifier.named
import java.lang.reflect.ParameterizedType
import java.lang.reflect.Type
import kotlin.reflect.KClass

// delegate to the module, which has the polymorphic serializers.
class ClosedRangeSerializer() : DataSerializer<ClosedRange<*>> by plugin.get<Json>(named("dataSerializer")).serializersModule.serializer<ClosedRange<*>>().toDataSerializer()