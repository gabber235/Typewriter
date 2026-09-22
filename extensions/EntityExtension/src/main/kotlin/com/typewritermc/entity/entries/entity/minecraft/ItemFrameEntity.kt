package com.typewritermc.entity.entries.entity.minecraft

import com.github.retrooper.packetevents.protocol.entity.data.EntityDataTypes
import com.github.retrooper.packetevents.protocol.entity.type.EntityType
import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.OnlyTags
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entity.FakeEntity
import com.typewritermc.engine.paper.entry.entity.SimpleEntityDefinition
import com.typewritermc.engine.paper.entry.entity.SimpleEntityInstance
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.packetevents.metas
import com.typewritermc.engine.paper.utils.Sound
import com.typewritermc.entity.entries.data.minecraft.applyGenericEntityData
import com.typewritermc.entity.entries.data.minecraft.display.item.ItemProperty
import com.typewritermc.entity.entries.data.minecraft.itemframe.ItemFrameFacingProperty
import com.typewritermc.entity.entries.data.minecraft.itemframe.ItemFrameMetadata
import com.typewritermc.entity.entries.data.minecraft.itemframe.ItemFrameRotationProperty
import com.typewritermc.entity.entries.data.minecraft.itemframe.applyItemFrameFacingData
import com.typewritermc.entity.entries.data.minecraft.itemframe.applyItemFrameRotationData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import io.github.retrooper.packetevents.util.SpigotConversionUtil
import me.tofaa.entitylib.meta.other.ItemFrameMeta
import org.bukkit.entity.Player

@Entry("item_frame_definition", "An item frame entity", Colors.ORANGE, "mdi:image-frame")
@Tags("item_frame_definition")
/**
 * The `ItemFrameDefinition` class is an entry that shows up as an item frame in-game.
 *
 * The frame hangs inside the block its position is in, against the side opposite to the direction it faces.
 *
 * ## How could this be used?
 * This could be used for puzzles where the player has to turn the item in a frame to the right rotation.
 */
class ItemFrameDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "item_data", "item_frame_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = ItemFrameEntity(EntityTypes.ITEM_FRAME, player)
}

@Entry("item_frame_instance", "An instance of an item frame entity", Colors.YELLOW, "mdi:image-frame")
class ItemFrameInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<ItemFrameDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "item_data", "item_frame_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

@Entry("glow_item_frame_definition", "A glow item frame entity", Colors.ORANGE, "mdi:image-frame")
@Tags("glow_item_frame_definition")
/**
 * The `GlowItemFrameDefinition` class is an entry that shows up as a glow item frame in-game.
 *
 * The frame hangs inside the block its position is in, against the side opposite to the direction it faces.
 *
 * ## How could this be used?
 * This could be used for the same puzzles as an item frame, in places too dark to see a normal one.
 */
class GlowItemFrameDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "item_data", "item_frame_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = ItemFrameEntity(EntityTypes.GLOW_ITEM_FRAME, player)
}

@Entry("glow_item_frame_instance", "An instance of a glow item frame entity", Colors.YELLOW, "mdi:image-frame")
class GlowItemFrameInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<GlowItemFrameDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "item_data", "item_frame_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class ItemFrameEntity(type: EntityType, player: Player) : WrapperFakeEntity(type, player) {
    init {
        val meta = entity.entityMeta
        check(meta is ItemFrameMeta) { "$type is not an item frame" }
        meta.orientation = ItemFrameMeta.Orientation.SOUTH
    }

    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is ItemProperty -> applyFramedItem(property)
            is ItemFrameRotationProperty -> applyItemFrameRotationData(entity, property)
            is ItemFrameFacingProperty -> applyItemFrameFacingData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
    }

    private fun applyFramedItem(property: ItemProperty) {
        val item = SpigotConversionUtil.fromBukkitItemStack(property.item.build(player))
        entity.metas {
            meta<ItemFrameMeta> { setIndex(ItemFrameMetadata.itemIndex, EntityDataTypes.ITEMSTACK, item) }
            error("Could not apply ItemData to ${entity.entityType} entity.")
        }
    }
}
