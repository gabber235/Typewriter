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
import com.typewritermc.entity.entries.data.minecraft.living.armadillo.ArmadilloStateProperty
import com.typewritermc.entity.entries.data.minecraft.living.armadillo.applyArmadilloStateData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("armadillo_definition", "An armadillo entity", Colors.ORANGE, "game-icons:armadillo")
@Tags("armadillo_definition")
/**
 * The `ArmadilloDefinition` class is an entry that represents an armadillo entity.
 *
 * ## How could this be used?
 * This could be used to create an armadillo that wanders a savanna or badlands quest area
 * and curls up into its shell when the player frightens it.
 */
class ArmadilloDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "armadillo_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = ArmadilloEntity(player)
}

@Entry("armadillo_instance", "An instance of an armadillo entity", Colors.YELLOW, "game-icons:armadillo")
/**
 * The `ArmadilloInstance` class is an entry that represents an instance of an armadillo entity.
 *
 * ## How could this be used?
 * This could be used to place an armadillo in the world, for example one curled up next to a savanna village
 * that a ranger asks the player to find.
 */
class ArmadilloInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<ArmadilloDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "armadillo_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class ArmadilloEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.ARMADILLO,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is AgeableProperty -> applyAgeableData(entity, property)
            is ArmadilloStateProperty -> applyArmadilloStateData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}
