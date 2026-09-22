package com.typewritermc.entity.entries.data.minecraft.itemframe

import com.github.retrooper.packetevents.protocol.entity.data.EntityDataTypes
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.other.ItemFrameMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

const val ITEM_FRAME_ROTATIONS = 8

@Entry("item_frame_rotation_data", "The rotation of the item in an item frame", Colors.RED, "mdi:rotate-right")
@Tags("item_frame_rotation_data", "item_frame_data")
class ItemFrameRotationData(
    override val id: String = "",
    override val name: String = "",
    @Help("Clockwise steps of 45 degrees. Any whole number works, it wraps around every 8 steps.")
    val rotation: Var<Int> = ConstVar(0),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<ItemFrameRotationProperty> {
    override fun type(): KClass<ItemFrameRotationProperty> = ItemFrameRotationProperty::class

    override fun build(player: Player): ItemFrameRotationProperty =
        ItemFrameRotationProperty(Math.floorMod(rotation.get(player), ITEM_FRAME_ROTATIONS))
}

data class ItemFrameRotationProperty(val rotation: Int) : EntityProperty {
    init {
        require(rotation in 0 until ITEM_FRAME_ROTATIONS) { "An item frame rotation is 0 to 7, got $rotation" }
    }

    companion object :
        SinglePropertyCollectorSupplier<ItemFrameRotationProperty>(
            ItemFrameRotationProperty::class,
            ItemFrameRotationProperty(0)
        )
}

fun applyItemFrameRotationData(entity: WrapperEntity, property: ItemFrameRotationProperty) {
    entity.metas {
        meta<ItemFrameMeta> { setIndex(ItemFrameMetadata.rotationIndex, EntityDataTypes.INT, property.rotation) }
        error("Could not apply ItemFrameRotationData to ${entity.entityType} entity.")
    }
}
