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
import com.typewritermc.entity.entries.data.minecraft.living.frog.FrogVariantProperty
import com.typewritermc.entity.entries.data.minecraft.living.frog.applyFrogVariantData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("frog_definition", "A frog entity", Colors.ORANGE, "icon-park-solid:frog")
@Tags("frog_definition")
/**
 * The `FrogDefinition` class is an entry that represents a frog entity.
 *
 * ## How could this be used?
 * This could be used to create a frog entity.
 */
class FrogDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "frog_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = FrogEntity(player)
}

@Entry("frog_instance", "An instance of a frog entity", Colors.YELLOW, "icon-park-solid:frog")
/**
 * The `FrogInstance` class is an entry that represents an instance of a frog entity.
 *
 * ## How could this be used?
 *
 * This could be used to create a frog entity.
 */
class FrogInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<FrogDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "frog_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class FrogEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.FROG,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is AgeableProperty -> applyAgeableData(entity, property)
            is FrogVariantProperty -> applyFrogVariantData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}