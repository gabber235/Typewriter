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
import com.typewritermc.entity.entries.data.minecraft.living.mooshroom.MooshroomVariantProperty
import com.typewritermc.entity.entries.data.minecraft.living.mooshroom.applyMooshroomVariantData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("mooshroom_definition", "A mooshroom entity", Colors.ORANGE, "mingcute:mushroom-fill")
@Tags("mooshroom_definition")
/**
 * The `MooshroomDefinition` class is an entry that shows up as a mooshroom in-game.
 *
 * ## How could this be used?
 * This could be used to create a mooshroom entity with red or brown variant.
 */
class MooshroomDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Sound = Sound.EMPTY,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "mooshroom_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = MooshroomEntity(player)
}

@Entry("mooshroom_instance", "An instance of a mooshroom entity", Colors.YELLOW, "mingcute:mushroom-fill")
class MooshroomInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<MooshroomDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "mooshroom_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class MooshroomEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.MOOSHROOM,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is AgeableProperty -> applyAgeableData(entity, property)
            is MooshroomVariantProperty -> applyMooshroomVariantData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}