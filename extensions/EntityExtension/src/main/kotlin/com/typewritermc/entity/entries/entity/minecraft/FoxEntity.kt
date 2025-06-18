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
import com.typewritermc.entity.entries.data.minecraft.living.AgeableProperty
import com.typewritermc.entity.entries.data.minecraft.living.applyAgeableData
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.data.minecraft.living.DefendingProperty
import com.typewritermc.entity.entries.data.minecraft.living.FaceplantedProperty
import com.typewritermc.entity.entries.data.minecraft.living.InterestedProperty
import com.typewritermc.entity.entries.data.minecraft.living.PouncingProperty
import com.typewritermc.entity.entries.data.minecraft.living.applyDefendingData
import com.typewritermc.entity.entries.data.minecraft.living.applyFaceplantedData
import com.typewritermc.entity.entries.data.minecraft.living.applyInterestedData
import com.typewritermc.entity.entries.data.minecraft.living.applyPouncingData
import com.typewritermc.entity.entries.data.minecraft.living.SleepingProperty
import com.typewritermc.entity.entries.data.minecraft.living.applySleepingData
import com.typewritermc.entity.entries.data.minecraft.living.fox.FoxTypeProperty
import com.typewritermc.entity.entries.data.minecraft.living.fox.applyFoxTypeData
import com.typewritermc.entity.entries.data.minecraft.living.tameable.SittingProperty
import com.typewritermc.entity.entries.data.minecraft.living.tameable.applyTameableData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("fox_definition", "A fox entity", Colors.ORANGE, "mdi:fox")
@Tags("fox_definition")
class FoxDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Sound = Sound.EMPTY,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "fox_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = FoxEntity(player)
}

@Entry("fox_instance", "An instance of a fox entity", Colors.YELLOW, "mdi:fox")
class FoxInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<FoxDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "fox_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class FoxEntity(player: Player) : WrapperFakeEntity(EntityTypes.FOX, player) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is FoxTypeProperty -> applyFoxTypeData(entity, property)
            is AgeableProperty -> applyAgeableData(entity, property)
            is SittingProperty -> applyTameableData(entity, property)
            is InterestedProperty -> applyInterestedData(entity, property)
            is PouncingProperty -> applyPouncingData(entity, property)
            is SleepingProperty -> applySleepingData(entity, property)
            is FaceplantedProperty -> applyFaceplantedData(entity, property)
            is DefendingProperty -> applyDefendingData(entity, property)
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}

