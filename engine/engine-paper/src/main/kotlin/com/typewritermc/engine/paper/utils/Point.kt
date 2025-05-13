package com.typewritermc.engine.paper.utils

import com.github.retrooper.packetevents.protocol.world.Location
import com.github.retrooper.packetevents.util.Vector3d
import com.github.retrooper.packetevents.util.Vector3f
import com.github.retrooper.packetevents.util.Vector3i
import com.typewritermc.core.utils.point.*
import com.typewritermc.core.utils.point.Vector
import io.github.retrooper.packetevents.util.SpigotConversionUtil
import com.typewritermc.core.utils.server
import org.bukkit.entity.Player
import java.util.*

fun org.bukkit.util.Vector.toVector(): Vector {
    return Vector(x, y, z)
}

fun Point<*>.toPacketVector3f() = Vector3f(x.toFloat(), y.toFloat(), z.toFloat())
fun Point<*>.toPacketVector3d() = Vector3d(x, y, z)
fun Point<*>.toPacketVector3i() = Vector3i(blockX, blockY, blockZ)
fun Point<*>.toBukkitVector(): org.bukkit.util.Vector = org.bukkit.util.Vector(x, y, z)

fun World.toBukkitWorld(): org.bukkit.World = server.getWorld(UUID.fromString(identifier))
    ?: throw IllegalArgumentException("Could not find world '$identifier' for location, and no default world available.")

fun org.bukkit.World.toWorld(): World = World(uid.toString())

fun <RWP> RWP.toBukkitLocation(): org.bukkit.Location where RWP : Point<RWP>, RWP : Rotatable<RWP>, RWP : WorldHolder<RWP> {
    return org.bukkit.Location(world.toBukkitWorld(), x, y, z, yaw, pitch)
}

fun <RP> RP.toPacketLocation(): Location where RP : Point<RP>, RP : Rotatable<RP> {
    return Location(x, y, z, yaw, pitch)
}

fun org.bukkit.Location.toPosition(): Position = Position(World(world.uid.toString()), x, y, z, yaw, pitch)
fun org.bukkit.Location.toPacketLocation(): Location = SpigotConversionUtil.fromBukkitLocation(this)
fun org.bukkit.Location.toCoordinate(): Coordinate = Coordinate(x, y, z, yaw, pitch)

fun <RP> RP.toBukkitLocation(bukkitWorld: org.bukkit.World): org.bukkit.Location where RP : Point<RP>, RP : Rotatable<RP> {
    return org.bukkit.Location(bukkitWorld, x, y, z, yaw, pitch)
}

fun Location.toCoordinate(): Coordinate =
    Coordinate(x, y, z, yaw, pitch)

val Player.position: Position
    get() = location.toPosition()