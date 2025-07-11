package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.typewritermc.engine.paper.utils.DefaultSoundId
import com.typewritermc.engine.paper.utils.EntrySoundId
import com.typewritermc.engine.paper.utils.SoundId
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.DataSerializer.Companion.toDataSerializer
import java.lang.reflect.Type

class SoundIdSerializer : DataSerializer<SoundId> by SoundId.serializer().toDataSerializer()