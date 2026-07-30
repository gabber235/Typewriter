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

/**
 * Sits an entity down on a seat that only its own viewer can see.
 *
 * Everything the entity does has a counterpart here: [applyPose] when it takes a pose, [move] when it
 * is moved, [onSpawn] and [mountIfNeeded] around its spawn, [contains] when it is asked what it is
 * made of, and [dispose] when it goes away.
 */
class RideableSittingSupport(
    private val player: Player,
    private val passenger: () -> WrapperEntity,
    private val isPassengerSpawned: () -> Boolean,
    private val location: () -> PositionProperty?,
) {
    private var sitEntity: WrapperEntity? = null
    private val seat: Seat = if (player.isFloodgate) Seat.ARMOR_STAND else Seat.BLOCK_DISPLAY

    /**
     * Puts a seat under the entity for as long as it holds a sitting pose, and takes it away again
     * for every other pose.
     *
     * [poseLocation] is where the seat goes. Without one it falls back on where the entity is.
     */
    fun applyPose(pose: EntityPose, poseLocation: PositionProperty?) {
        if (pose == EntityPose.SITTING) sit(poseLocation) else unsit()
    }

    /**
     * Moves the seat along with the entity.
     *
     * A client positions a passenger from the entity it rides as well as from the packets the
     * passenger itself gets, and lets the two fight whenever they disagree, so the seat has to end up
     * wherever the entity is asked to go.
     */
    fun move(property: PositionProperty) {
        sitEntity?.move(seat.at(property))
    }

    /**
     * Spawns the seat of an entity that was already sitting when it is spawned again, which is what
     * a respawn is for as long as the pose holds.
     *
     * Call it before spawning the entity, so the seat is there to receive it.
     */
    fun onSpawn(spawnLocation: PositionProperty) {
        val seatEntity = sitEntity ?: return
        seatEntity.spawn(seat.at(spawnLocation).toPacketLocation())
        seatEntity.addViewer(player.uniqueId)
    }

    /**
     * Call after spawning the entity.
     *
     * A client only accepts the two of them being tied together once it knows both, so a mount is
     * tried from either end and settles on whichever of them arrives last.
     */
    fun mountIfNeeded() {
        val seatEntity = sitEntity ?: return
        if (!isPassengerSpawned()) return
        if (seatEntity.hasPassenger(passenger())) return
        seatEntity.addPassengers(passenger())
    }

    /**
     * Whether the id is the seat's, so that an entity asked what it consists of owns up to the seat
     * it is sat on as well.
     */
    fun contains(entityId: Int): Boolean = sitEntity?.entityId == entityId

    /** Call from the entity's own dispose, so that the seat does not outlive it. */
    fun dispose() = unsit()

    private fun sit(poseLocation: PositionProperty?) {
        val loc = poseLocation ?: location() ?: return
        if (sitEntity != null) return
        val seatEntity = seat.createEntity()
        sitEntity = seatEntity
        seatEntity.spawn(seat.at(loc).toPacketLocation())
        seatEntity.addViewer(player.uniqueId)
        mountIfNeeded()
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

    /**
     * @param yOffset how far above the entity its seat is placed for the entity to end up where it
     * was asked to be. A client draws a passenger on the point its seat hands it, which for a block
     * display is the display itself, so nothing has to be added on java. Vanilla positioning would
     * drop a player shaped passenger 0.6 below that point, and a real player mounting a real block
     * display does land there, but an entity that only ever existed in packets does not, so leave
     * this at zero. Bedrock goes through geyser and was measured on its own.
     */
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
