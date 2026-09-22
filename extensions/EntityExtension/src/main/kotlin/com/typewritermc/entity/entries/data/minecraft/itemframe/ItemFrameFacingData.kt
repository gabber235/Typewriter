package com.typewritermc.entity.entries.data.minecraft.itemframe

import com.github.retrooper.packetevents.protocol.entity.data.EntityDataTypes
import com.github.retrooper.packetevents.protocol.world.BlockFace
import com.github.retrooper.packetevents.protocol.world.Direction
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.other.ItemFrameMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("item_frame_facing_data", "The direction an item frame faces", Colors.RED, "fa6-solid:compass")
@Tags("item_frame_facing_data", "item_frame_data")
class ItemFrameFacingData(
    override val id: String = "",
    override val name: String = "",
    @Help("The frame hangs on the side of its block opposite to this direction.")
    val facing: Direction = Direction.SOUTH,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<ItemFrameFacingProperty> {
    override fun type(): KClass<ItemFrameFacingProperty> = ItemFrameFacingProperty::class

    override fun build(player: Player): ItemFrameFacingProperty = ItemFrameFacingProperty(facing)
}

data class ItemFrameFacingProperty(val facing: Direction) : EntityProperty {
    companion object :
        SinglePropertyCollectorSupplier<ItemFrameFacingProperty>(ItemFrameFacingProperty::class)
}

/**
 * Before 1.21.6 the client only reads the direction from the spawn packet, so the frame is spawned again
 * to turn it. From then on the direction is synced data and changes in place.
 */
fun applyItemFrameFacingData(entity: WrapperEntity, property: ItemFrameFacingProperty) {
    val orientation = ItemFrameMeta.Orientation.valueOf(property.facing.name)
    var needsRespawn = false
    entity.metas {
        meta<ItemFrameMeta> {
            if (this.orientation == orientation) return@meta
            this.orientation = orientation
            if (ItemFrameMetadata.hasSyncedDirection) {
                setIndex(ItemFrameMetadata.DIRECTION_INDEX, EntityDataTypes.BLOCK_FACE, BlockFace.valueOf(property.facing.name))
            } else {
                needsRespawn = true
            }
        }
        error("Could not apply ItemFrameFacingData to ${entity.entityType} entity.")
    }

    if (!needsRespawn || !entity.isSpawned) return
    val location = entity.location
    entity.despawn()
    entity.spawn(location)
}
