package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.*
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.utils.point.Coordinate
import java.lang.reflect.Type

class CoordinateSerializer : DataSerializer<Coordinate> {
    override val type: Type = Coordinate::class.java
    override fun deserialize(json: JsonElement, typeOfT: Type, context: JsonDeserializationContext): Coordinate {
        if (json is JsonPrimitive && json.asJsonPrimitive.isString) {
            val split = json.asString.split(",")
            if (split.size != 6) throw IllegalArgumentException("Could not parse coordinate from $json")

            val x = split[1].toDouble()
            val y = split[2].toDouble()
            val z = split[3].toDouble()
            val yaw = split[4].toFloat()
            val pitch = split[5].toFloat()
            return Coordinate(x, y, z, yaw, pitch)
        }

        if (json is JsonObject) {
            val x = json.get("x")?.asDouble ?: 0.0
            val y = json.get("y")?.asDouble ?: 0.0
            val z = json.get("z")?.asDouble ?: 0.0
            val yaw = json.get("yaw")?.asFloat ?: 0f
            val pitch = json.get("pitch")?.asFloat ?: 0f
            return Coordinate(x, y, z, yaw, pitch)
        }

        throw IllegalArgumentException("Could not parse coordinate from $json")
    }

    override fun serialize(src: Coordinate, typeOfSrc: Type, context: JsonSerializationContext): JsonElement {
        val obj = JsonObject()
        obj.addProperty("x", src.x)
        obj.addProperty("y", src.y)
        obj.addProperty("z", src.z)
        obj.addProperty("yaw", src.yaw)
        obj.addProperty("pitch", src.pitch)
        return obj

    }
}