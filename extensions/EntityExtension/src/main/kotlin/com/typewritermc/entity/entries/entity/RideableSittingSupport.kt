package com.typewritermc.entity.entries.entity

import com.github.retrooper.packetevents.protocol.entity.pose.EntityPose
import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import com.typewritermc.engine.paper.extensions.packetevents.meta
import com.typewritermc.engine.paper.utils.isFloodgate
import com.typewritermc.engine.paper.utils.move
import com.typewritermc.engine.paper.utils.toPacketLocation
import me.tofaa.entitylib.meta.other.ArmorStandMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player

class RideableSittingSupport(
    private val player: Player,
    private val passenger: () -> WrapperEntity,
    private val isPassengerSpawned: () -> Boolean,
    private val location: () -> PositionProperty?,
) {
    private var sitEntity: WrapperEntity? = null
    private val seat: Seat = if (player.isFloodgate) Seat.ARMOR_STAND else Seat.BLOCK_DISPLAY

    fun applyPose(pose: EntityPose, poseLocation: PositionProperty?) {
        if (pose == EntityPose.SITTING) sit(poseLocation) else unsit()
    }

    fun move(property: PositionProperty) {
        if (sitEntity?.isSpawned == true) {
            sitEntity?.move(seat.at(property))
        }
    }

    fun onSpawn(spawnLocation: PositionProperty) {
        val seatEntity = sitEntity ?: return
        seatEntity.spawn(seat.at(spawnLocation).toPacketLocation())
        seatEntity.addViewer(player.uniqueId)
    }

    fun mountIfNeeded() {
        val seatEntity = sitEntity ?: return
        if (isPassengerSpawned()) {
            seatEntity.addPassengers(passenger())
        }
    }

    fun contains(entityId: Int): Boolean = sitEntity?.entityId == entityId

    fun dispose() {
        val seatEntity = sitEntity ?: return
        if (seatEntity.hasPassenger(passenger())) {
            seatEntity.removePassengers(passenger())
        }
        seatEntity.removeViewer(player.uniqueId)
        seatEntity.despawn()
        seatEntity.remove()
        sitEntity = null
    }

    private fun sit(poseLocation: PositionProperty?) {
        val loc = poseLocation ?: location() ?: return
        if (sitEntity != null) return
        val seatEntity = seat.createEntity()
        sitEntity = seatEntity
        seatEntity.spawn(seat.at(loc).toPacketLocation())
        seatEntity.addViewer(player.uniqueId)
        if (isPassengerSpawned()) {
            seatEntity.addPassengers(passenger())
        }
    }

    private fun unsit() {
        val seatEntity = sitEntity ?: return
        if (seatEntity.hasPassenger(passenger())) {
            seatEntity.removePassengers(passenger())
        }
        seatEntity.removeViewer(player.uniqueId)
        seatEntity.despawn()
        seatEntity.remove()
        sitEntity = null
    }

    private enum class Seat(private val yOffset: Double) {
        BLOCK_DISPLAY(0.0),
        ARMOR_STAND(-0.25);

        fun createEntity(): WrapperEntity = when (this) {
            BLOCK_DISPLAY -> WrapperEntity(EntityTypes.BLOCK_DISPLAY)
            ARMOR_STAND -> WrapperEntity(EntityTypes.ARMOR_STAND).meta<ArmorStandMeta> {
                isInvisible = true
                isMarker = true
            }
        }

        fun at(location: PositionProperty): PositionProperty = location.add(0.0, yOffset, 0.0)
    }
}
