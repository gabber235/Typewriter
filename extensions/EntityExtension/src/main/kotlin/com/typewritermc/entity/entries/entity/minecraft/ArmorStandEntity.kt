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
import com.typewritermc.entity.entries.data.minecraft.*
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.data.minecraft.living.armorstand.*
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("armorstand_definition", "A armor_stand entity", Colors.ORANGE, "lucide:person-standing")
@Tags("armor_stand_definition")
/**
 * The `ArmorStandDefinition` class is an entry that shows up as a armor_stand in-game.
 *
 * ## How could this be used?
 * This could be used to create a armor_stand entity.
 */
class ArmorStandDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Sound = Sound.EMPTY,
    @OnlyTags("generic_entity_data", "living_entity_data", "armor_stand_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = ArmorStandEntity(player)
}

@Entry("armor_stand_instance", "An instance of a armor_stand entity", Colors.YELLOW, "lucide:person-standing")
class ArmorStandInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<ArmorStandDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "armor_stand_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class ArmorStandEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.ARMOR_STAND,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is ArmsProperty -> applyArmsData(entity, property)
            is BaseplateProperty -> applyBaseplateData(entity, property)
            is MarkerProperty -> applyMarkerData(entity, property)
            is RotationProperty -> applyRotationData(entity, property)
            is SmallProperty -> applySmallData(entity, property)
            is InvisibleProperty -> applyInvisibleData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}