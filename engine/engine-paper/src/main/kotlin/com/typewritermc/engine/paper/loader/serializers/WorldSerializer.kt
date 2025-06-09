package com.typewritermc.engine.paper.loader.serializers

import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonElement
import com.google.gson.JsonPrimitive
import com.google.gson.JsonSerializationContext
import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.utils.logErrorIfNull
import com.typewritermc.engine.paper.utils.server
import java.lang.reflect.Type
import java.util.*

class WorldSerializer : DataSerializer<World> {
    override val type: Type = World::class.java

    override fun serialize(src: World, typeOfSrc: Type, context: JsonSerializationContext): JsonElement {
        return JsonPrimitive(src.identifier)
    }

    override fun deserialize(json: JsonElement, typeOfT: Type, context: JsonDeserializationContext): World {
        val world = json.asString

        val uuid = try {
            UUID.fromString(world)
        } catch (e: IllegalArgumentException) {
            null
        }

        val bukkitWorld =
            uuid?.let { server.getWorld(it) }
                ?: server.getWorld(world)
                ?: server.worlds.firstOrNull { it.name.equals(world, true) }
                    .logErrorIfNull("No world found for identifier '$world', possible worlds: ${server.worlds.map { it.name }}. Picking ${server.worlds.firstOrNull()?.name} as default.")
                ?: server.worlds.firstOrNull()
                ?: throw IllegalArgumentException("Could not find world '$world' for location, and no default world available.")

        return World(bukkitWorld.uid.toString())
    }
}