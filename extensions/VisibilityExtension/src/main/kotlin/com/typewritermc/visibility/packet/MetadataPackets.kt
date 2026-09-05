package com.typewritermc.visibility.packet

import com.github.retrooper.packetevents.protocol.entity.data.EntityData
import com.github.retrooper.packetevents.protocol.entity.data.EntityDataTypes
import com.github.retrooper.packetevents.protocol.entity.pose.EntityPose
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityMetadata
import net.kyori.adventure.text.Component
import org.bukkit.entity.Player
import org.bukkit.entity.Pose
import java.util.Optional

/**
 * The bit masks of the shared entity flags metadata byte.
 */
object EntityFlag {
    const val ON_FIRE = 0x01
    const val SNEAKING = 0x02
    const val SPRINTING = 0x08
    const val SWIMMING = 0x10
    const val INVISIBLE = 0x20
    const val GLOWING = 0x40
    const val GLIDING = 0x80
}

const val FLAGS_METADATA_INDEX = 0
const val CUSTOM_NAME_METADATA_INDEX = 2
const val CUSTOM_NAME_VISIBLE_METADATA_INDEX = 3
const val POSE_METADATA_INDEX = 6

/**
 * Applies the given flag masks to the shared entity flags byte of a metadata packet.
 *
 * Leaves the packet untouched when it does not carry the flags byte. That is not the same as the
 * client keeping the flags it already had: a client adding the entity fresh starts from the vanilla
 * defaults, and the server omits every default value from the metadata packet accompanying a spawn.
 * Effects relying on a flag therefore have to send it on spawn as well.
 *
 * @return true when the packet carried the flags byte and it was rewritten
 */
fun rewriteEntityFlags(metadata: List<EntityData<*>>, setMask: Int, clearMask: Int = 0): Boolean {
    val entry = flagsEntry(metadata) ?: return false
    entry.value = ((entry.value.toInt() and clearMask.inv()) or setMask).toByte()
    return true
}

/**
 * The shared entity flags byte a metadata packet carries, or null when it carries none.
 * Effects track this so a packet they synthesize preserves the flags they do not own.
 */
fun readEntityFlags(metadata: List<EntityData<*>>): Int? = flagsEntry(metadata)?.value?.toInt()

@Suppress("UNCHECKED_CAST")
private fun flagsEntry(metadata: List<EntityData<*>>): EntityData<Byte>? =
    metadata.firstOrNull { it.index == FLAGS_METADATA_INDEX && it.value is Byte } as EntityData<Byte>?

/**
 * Replaces the pose of a metadata packet.
 *
 * @return true when the packet carried a pose and it was rewritten
 */
fun rewriteEntityPose(metadata: List<EntityData<*>>, pose: EntityPose): Boolean {
    val entry = metadata.firstOrNull { it.index == POSE_METADATA_INDEX && it.value is EntityPose }
        ?: return false

    @Suppress("UNCHECKED_CAST")
    (entry as EntityData<EntityPose>).value = pose
    return true
}

fun entityFlagsPacket(entityId: Int, flags: Int) = WrapperPlayServerEntityMetadata(
    entityId,
    listOf(EntityData(FLAGS_METADATA_INDEX, EntityDataTypes.BYTE, flags.toByte())),
)

fun entityPosePacket(entityId: Int, pose: EntityPose) = WrapperPlayServerEntityMetadata(
    entityId,
    listOf(EntityData(POSE_METADATA_INDEX, EntityDataTypes.ENTITY_POSE, pose)),
)

/**
 * Writes the custom name of a metadata packet, adding the entries when the packet omits them.
 *
 * A null name clears the entry and hides it. Entries the packet already carries are replaced in
 * place so the order the client reads them in is unchanged.
 */
fun rewriteCustomName(metadata: MutableList<EntityData<*>>, name: Component?) {
    val visible = name != null
    val nameEntry = customNameEntry(metadata)
    if (nameEntry != null) nameEntry.value = Optional.ofNullable(name)
    else metadata.add(EntityData(CUSTOM_NAME_METADATA_INDEX, EntityDataTypes.OPTIONAL_ADV_COMPONENT, Optional.ofNullable(name)))

    val visibleEntry = customNameVisibleEntry(metadata)
    if (visibleEntry != null) visibleEntry.value = visible
    else metadata.add(EntityData(CUSTOM_NAME_VISIBLE_METADATA_INDEX, EntityDataTypes.BOOLEAN, visible))
}

/** The custom name a metadata packet carries, or null when it carries none. */
fun readCustomName(metadata: List<EntityData<*>>): Optional<Component>? = customNameEntry(metadata)?.value

/** Whether a metadata packet shows its custom name, or null when it carries no such entry. */
fun readCustomNameVisible(metadata: List<EntityData<*>>): Boolean? = customNameVisibleEntry(metadata)?.value

fun customNamePacket(entityId: Int, name: Component?) = WrapperPlayServerEntityMetadata(
    entityId,
    listOf(
        EntityData(CUSTOM_NAME_METADATA_INDEX, EntityDataTypes.OPTIONAL_ADV_COMPONENT, Optional.ofNullable(name)),
        EntityData(CUSTOM_NAME_VISIBLE_METADATA_INDEX, EntityDataTypes.BOOLEAN, name != null),
    ),
)

@Suppress("UNCHECKED_CAST")
private fun customNameEntry(metadata: List<EntityData<*>>): EntityData<Optional<Component>>? =
    metadata.firstOrNull { it.index == CUSTOM_NAME_METADATA_INDEX && it.value is Optional<*> } as EntityData<Optional<Component>>?

@Suppress("UNCHECKED_CAST")
private fun customNameVisibleEntry(metadata: List<EntityData<*>>): EntityData<Boolean>? =
    metadata.firstOrNull { it.index == CUSTOM_NAME_VISIBLE_METADATA_INDEX && it.value is Boolean } as EntityData<Boolean>?

/**
 * The entity flags byte matching the player's current server side state.
 * Used as the base value for synthetic metadata packets. Must be called on the main thread.
 */
fun serverSideEntityFlags(player: Player): Int {
    var flags = 0
    if (player.fireTicks > 0) flags = flags or EntityFlag.ON_FIRE
    if (player.isSneaking) flags = flags or EntityFlag.SNEAKING
    if (player.isSprinting) flags = flags or EntityFlag.SPRINTING
    if (player.isSwimming) flags = flags or EntityFlag.SWIMMING
    if (player.isInvisible) flags = flags or EntityFlag.INVISIBLE
    if (player.isGlowing) flags = flags or EntityFlag.GLOWING
    if (player.isGliding) flags = flags or EntityFlag.GLIDING
    return flags
}

fun Pose.toEntityPose(): EntityPose = when (this) {
    Pose.SNEAKING -> EntityPose.CROUCHING
    else -> runCatching { EntityPose.valueOf(name) }.getOrDefault(EntityPose.STANDING)
}
