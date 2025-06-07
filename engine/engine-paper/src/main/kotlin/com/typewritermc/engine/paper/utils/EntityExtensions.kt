package com.typewritermc.engine.paper.utils

import com.github.retrooper.packetevents.protocol.entity.EntityPositionData
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityPositionSync
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityRelativeMoveAndRotation
import com.typewritermc.core.utils.point.toVector
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import me.tofaa.entitylib.wrapper.WrapperEntity

fun WrapperEntity.move(property: PositionProperty) {
    if (!isSpawned) return

    val delta = property.toVector() - location.toCoordinate()
    val distanceSquared = delta.lengthSquared

    // Minecraft is stupid and requires the head rotation to be sent BEFORE the movement
    if (property.yaw != location.yaw || property.pitch != location.pitch) {
        rotateHead(property.yaw, property.pitch)
    }
    location = property.toPacketLocation()

    if (distanceSquared == 0.0) {
        return
    } else if (distanceSquared < 7 * 7) {
        sendPacketsToViewers(
            WrapperPlayServerEntityRelativeMoveAndRotation(
                entityId,
                delta.x,
                delta.y,
                delta.z,
                property.yaw,
                property.pitch,
                isOnGround
            ),
        )
    } else {
//        println("Teleporting $distanceSquared by $delta to $property")
        sendPacketsToViewers(
            WrapperPlayServerEntityPositionSync(
                entityId, EntityPositionData(
                    property.toPacketVector3d(),
                    delta.toPacketVector3d(),
                    property.yaw,
                    property.pitch
                ), isOnGround
            ),
        )
    }
}
