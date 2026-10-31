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
import com.typewritermc.entity.entries.data.minecraft.living.SaddledProperty
import com.typewritermc.entity.entries.data.minecraft.living.applyAgeableData
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.data.minecraft.living.applySaddledData
import com.typewritermc.entity.entries.data.minecraft.living.horse.EatingProperty
import com.typewritermc.entity.entries.data.minecraft.living.horse.RearingProperty
import com.typewritermc.entity.entries.data.minecraft.living.horse.applyHorseEatingData
import com.typewritermc.entity.entries.data.minecraft.living.horse.applyRearingData
import com.typewritermc.entity.entries.data.minecraft.living.tameable.TamedProperty
import com.typewritermc.entity.entries.data.minecraft.living.tameable.applyTamedData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("skeleton_horse_definition", "A skeleton horse entity", Colors.ORANGE, "game-icons:horse-head")
@Tags("skeleton_horse_definition")
/**
 * The `SkeletonHorseDefinition` class is an entry that represents a skeleton horse entity.
 *
 * ## How could this be used?
 * This could be used to create the saddled skeleton horse of a ghostly rider who appears during a thunderstorm.
 * It can rear up, graze, be saddled, be tamed and be a foal.
 */
class SkeletonHorseDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags(
        "generic_entity_data",
        "living_entity_data",
        "mob_data",
        "ageable_data",
        "saddled_data",
        "eating_data",
        "tamed_data",
        "rearing_data",
    )
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = SkeletonHorseEntity(player)
}

@Entry("skeleton_horse_instance", "An instance of a skeleton horse entity", Colors.YELLOW, "game-icons:horse-head")
/**
 * The `SkeletonHorseInstance` class is an entry that represents an instance of a skeleton horse entity.
 *
 * ## How could this be used?
 * This could be used to place a skeleton horse in the world, for example one waiting at a graveyard gate
 * for the player to ride into the next chapter.
 */
class SkeletonHorseInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<SkeletonHorseDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags(
        "generic_entity_data",
        "living_entity_data",
        "mob_data",
        "ageable_data",
        "saddled_data",
        "eating_data",
        "tamed_data",
        "rearing_data",
    )
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class SkeletonHorseEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.SKELETON_HORSE,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is AgeableProperty -> applyAgeableData(entity, property)
            is SaddledProperty -> applySaddledData(entity, property)
            is EatingProperty -> applyHorseEatingData(entity, property)
            is TamedProperty -> applyTamedData(entity, property)
            is RearingProperty -> applyRearingData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}
