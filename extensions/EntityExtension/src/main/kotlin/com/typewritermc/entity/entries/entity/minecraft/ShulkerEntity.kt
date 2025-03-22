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
import com.typewritermc.entity.entries.data.minecraft.DyeColorProperty
import com.typewritermc.entity.entries.data.minecraft.applyDyeColorData
import com.typewritermc.entity.entries.data.minecraft.applyGenericEntityData
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.data.minecraft.living.shulker.AttachFaceProperty
import com.typewritermc.entity.entries.data.minecraft.living.shulker.ShieldHeightProperty
import com.typewritermc.entity.entries.data.minecraft.living.shulker.applyAttachFaceData
import com.typewritermc.entity.entries.data.minecraft.living.shulker.applyShieldHeightData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("shulker_definition", "A shulker entity", Colors.ORANGE, "fa6-solid:box")
@Tags("shulker_definition")
/**
 * The `ShulkerDefinition` class is an entry that shows up as a shulker in-game.
 *
 * ## How could this be used?
 * This could be used to create a shulker entity with customizable face attachment, shield height, and color.
 */
class ShulkerDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Sound = Sound.EMPTY,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "shulker_data", "dye_color_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = ShulkerEntity(player)
}

@Entry("shulker_instance", "An instance of a shulker entity", Colors.YELLOW, "fa6-solid:box")
class ShulkerInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<ShulkerDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "shulker_data", "dye_color_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class ShulkerEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.SHULKER,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is AttachFaceProperty -> applyAttachFaceData(entity, property)
            is ShieldHeightProperty -> applyShieldHeightData(entity, property)
            is DyeColorProperty -> applyDyeColorData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}