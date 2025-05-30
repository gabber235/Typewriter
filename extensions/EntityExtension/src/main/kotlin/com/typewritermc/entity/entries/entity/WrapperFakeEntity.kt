package com.typewritermc.entity.entries.entity

import com.github.retrooper.packetevents.protocol.entity.EntityPositionData
import com.github.retrooper.packetevents.protocol.entity.type.EntityType
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityPositionSync
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityRelativeMoveAndRotation
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityRotation
import com.typewritermc.core.utils.point.toVector
import com.typewritermc.engine.paper.entry.entity.EntityState
import com.typewritermc.engine.paper.entry.entity.FakeEntity
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.utils.toCoordinate
import com.typewritermc.engine.paper.utils.toPacketLocation
import com.typewritermc.engine.paper.utils.toPacketVector3d
import com.typewritermc.entity.entries.entity.custom.state
import me.tofaa.entitylib.EntityLib
import me.tofaa.entitylib.meta.EntityMeta
import me.tofaa.entitylib.meta.projectile.ThrownExpBottleMeta
import me.tofaa.entitylib.meta.types.LivingEntityMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import me.tofaa.entitylib.wrapper.WrapperExperienceOrbEntity
import me.tofaa.entitylib.wrapper.WrapperLivingEntity
import org.bukkit.entity.Player

abstract class WrapperFakeEntity(
    val type: EntityType,
    player: Player,
) : FakeEntity(player) {
    protected val entity: WrapperEntity by lazy(LazyThreadSafetyMode.NONE) {
        val uuid = EntityLib.getPlatform().entityUuidProvider.provide(type)
        val entityId = EntityLib.getPlatform().entityIdProvider.provide(uuid, type)
        val metaData = EntityMeta.createMeta(entityId, type)
        when (metaData) {
            is LivingEntityMeta -> WrapperLivingEntity(entityId, uuid, type, metaData)
            is ThrownExpBottleMeta -> WrapperExperienceOrbEntity(entityId, uuid, type, metaData)
            else -> WrapperEntity(entityId, uuid, type, metaData)
        }
    }

    override val entityId: Int
        get() = entity.entityId

    override val state: EntityState
        get() = type.state(properties)

    override fun applyProperties(properties: List<EntityProperty>) {
        entity.entityMeta.setNotifyAboutChanges(false)
        properties.forEach {
            when (it) {
                is PositionProperty -> {
                    entity.move(it)
                }

                else -> applyProperty(it)
            }
        }
        entity.entityMeta.setNotifyAboutChanges(true)
    }

    abstract fun applyProperty(property: EntityProperty)

    override fun spawn(location: PositionProperty) {
        entity.spawn(location.toPacketLocation())
        entity.addViewer(player.uniqueId)
        super.spawn(location)
    }

    override fun addPassenger(entity: FakeEntity) {
        if (entity.entityId == entityId) return
        if (this.entity.hasPassenger(entity.entityId)) return
        this.entity.addPassenger(entity.entityId)
    }

    override fun removePassenger(entity: FakeEntity) {
        if (entity.entityId == entityId) return
        if (!this.entity.hasPassenger(entity.entityId)) return
        this.entity.removePassenger(entity.entityId)
    }

    override fun contains(entityId: Int): Boolean = entityId == entity.entityId

    override fun dispose() {
        super.dispose()
        entity.despawn()
        entity.remove()
    }
}

fun WrapperEntity.move(property: PositionProperty) {
    if (!isSpawned) return

    val delta = property.toVector() - location.toCoordinate()

    // Minecraft is stupid and requires the head rotation to be sent BEFORE the movement
    if (property.yaw != location.yaw || property.pitch != location.pitch) {
        rotateHead(property.yaw, property.pitch)
    }

    location = property.toPacketLocation()
    val distanceSquared = delta.lengthSquared

    if (distanceSquared == 0.0) {
        sendPacketToViewers(
            WrapperPlayServerEntityRotation(entityId, property.yaw, property.pitch, isOnGround)
        )
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