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
import com.typewritermc.entity.entries.data.minecraft.living.AgeableProperty
import com.typewritermc.entity.entries.data.minecraft.living.applyAgeableData
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.data.minecraft.living.scheep.ShearedProperty
import com.typewritermc.entity.entries.data.minecraft.living.scheep.applySheepShearedData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("sheep_definition", "A sheep entity", Colors.ORANGE, "mdi:sheep")
@Tags("sheep_definition")
/**
 * The `SheepDefinition` class is an entry that represents a sheep entity.
 *
 * ## How could this be used?
 * This could be used to create a sheep entity.
 */
class SheepDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Sound = Sound.EMPTY,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "sheep_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = SheepEntity(player)
}

@Entry("sheep_instance", "An instance of a sheep entity", Colors.YELLOW, "mdi:sheep")
/**
 * The `SheepInstance` class is an entry that represents an instance of a sheep entity.
 *
 * ## How could this be used?
 * This could be used to create a sheep entity.
 */
class SheepInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<SheepDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "sheep_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class SheepEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.SHEEP,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is DyeColorProperty -> applyDyeColorData(entity, property)
            is ShearedProperty -> applySheepShearedData(entity, property)
            is AgeableProperty -> applyAgeableData(entity, property)
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}