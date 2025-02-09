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
import com.typewritermc.entity.entries.data.minecraft.display.item.ItemProperty
import com.typewritermc.entity.entries.data.minecraft.display.item.applyItemData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("dropped_item_entity_definition", "A dropped item entity", Colors.ORANGE, "material-symbols:pin-drop")
@Tags("dropped_item_entity_definition")
class DroppedItemEntityDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Sound = Sound.EMPTY,
    @OnlyTags("generic_entity_data", "item_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity {
        return DroppedItemEntity(player)
    }
}

@Entry("dropped_item_entity_instance", "An instance of a dropped item entity", Colors.YELLOW, "ic:round-drop")
class DroppedItemEntityInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<DroppedItemEntityDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "item_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out EntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

class DroppedItemEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.ITEM,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is ItemProperty -> applyItemData(entity, property, player)
        }
        if (applyGenericEntityData(entity, property)) return
    }
}
