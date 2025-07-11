package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.serializer
import kotlinx.serialization.builtins.serializer
import org.bukkit.util.Vector
import java.lang.reflect.Type

class VectorSerializer : DataSerializer<Vector>
    by serializer(
        "x", { x }, Double.serializer(),
        "y", { y }, Double.serializer(),
        "z", { z }, Double.serializer(),
        ::Vector
    )