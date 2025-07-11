package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.DataSerializer.Companion.toDataSerializer
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.utils.logErrorIfNull
import com.typewritermc.engine.paper.utils.server
import java.lang.reflect.Type
import java.util.*

class WorldSerializer : DataSerializer<World> by World.serializer().toDataSerializer()