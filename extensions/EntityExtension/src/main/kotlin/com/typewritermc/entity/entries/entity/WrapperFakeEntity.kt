package com.typewritermc.entity.entries.entity

import com.github.retrooper.packetevents.protocol.entity.type.EntityType
import com.typewritermc.engine.paper.entry.entity.EntityState
import com.typewritermc.engine.paper.entry.entity.FakeEntity
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.utils.toPacketLocation
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
                    entity.teleport(it.toPacketLocation())
                    entity.rotateHead(it.yaw, it.pitch)
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