package com.typewritermc.entity.entries.entity.minecraft

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
import com.typewritermc.engine.paper.utils.Sound
import com.typewritermc.entity.entries.data.minecraft.applyGenericEntityData
import com.typewritermc.entity.entries.data.minecraft.display.applyDisplayEntityData
import com.typewritermc.entity.entries.data.minecraft.display.item.DisplayTypeProperty
import com.typewritermc.entity.entries.data.minecraft.display.item.ItemProperty
import com.typewritermc.entity.entries.data.minecraft.display.item.applyDisplayTypeData
import com.typewritermc.entity.entries.data.minecraft.display.item.applyItemData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("item_display_definition", "An item display entity", Colors.ORANGE, "streamline:podium-solid")
@Tags("item_display_definition")
/**
 * The `ItemDisplayDefinition` class is an entry that represents an item display entity.
 *
 * ## How could this be used?
 * This could be used to create an entity that displays an item.
 */
class ItemDisplayDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "display_data", "item_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = ItemDisplayEntity(player)
}

@Entry(
    "item_display_instance",
    "An instance of an item display entity",
    Colors.YELLOW,
    "streamline:podium-solid"
)

class ItemDisplayInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<ItemDisplayDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "display_data", "item_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

open class ItemDisplayEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.ITEM_DISPLAY,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is ItemProperty -> applyItemData(entity, property, player)
            is DisplayTypeProperty -> applyDisplayTypeData(entity, property)
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyDisplayEntityData(entity, property)) return
    }
}