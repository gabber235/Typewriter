package com.typewritermc.engine.paper.utils

import com.google.gson.*
import com.typewritermc.core.serialization.serializer
import com.typewritermc.core.serialization.xmap
import com.typewritermc.core.utils.point.Coordinate
import com.typewritermc.engine.paper.loader.serializers.CoordinateSerializer
import com.typewritermc.engine.paper.logger
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.modules.SerializersModule
import org.bukkit.Bukkit
import org.bukkit.Location
import org.bukkit.Material
import org.bukkit.inventory.ItemStack
import java.lang.reflect.Type
import java.util.*


// TODO better serialization module management.
fun createBukkitJsonFormat(): Json = Json {
    serializersModule = SerializersModule {
        contextual(Location::class, LocationSerializer)
        contextual(ItemStack::class, ItemStackSerializer)
        contextual(Coordinate::class, CoordinateSerializer)
    }
}

fun createBukkitDataParser(): Gson = GsonBuilder()
    .create()


object ItemStackSerializer : KSerializer<ItemStack> by String.serializer().xmap(
    { Base64.getEncoder().encodeToString(serializeAsBytes()) },
    { ItemStack.deserializeBytes(Base64.getDecoder().decode(this)) }
)

object UUIDSerializer : KSerializer<UUID> by serializer(
    "most", { mostSignificantBits }, Long.serializer(),
    "least", { leastSignificantBits }, Long.serializer(),
    ::UUID
)

object LocationSerializer : KSerializer<Location> by serializer(
    "x", { x }, Double.serializer(),
    "y", { y }, Double.serializer(),
    "z", { z }, Double.serializer(),
    "yaw", { yaw }, Float.serializer().nullable,
    "pitch", { pitch }, Float.serializer().nullable,
    "world", { world.uuid }, UUIDSerializer,
    { x, y, z, yaw, pitch, world ->
        val worldObj = Bukkit.getWorld(world)
        if (worldObj == null) {
            logger.warning("Failed to find world '$world' while deserializing location '$this'")
            Location(Bukkit.getWorlds()[0], x, y, z, yaw ?: 0f, pitch ?: 0f)
        } else {
            Location(worldObj, x, y, z, yaw ?: 0f, pitch ?: 0f)
        }
    }
)