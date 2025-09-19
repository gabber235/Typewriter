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
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("turtle_definition", "A turtle entity", Colors.ORANGE, "mdi:turtle")
@Tags("turtle_definition")
/**
 * The `TurtleDefinition` class is an entry that represents a turtle entity.
 *
 * ## How could this be used?
 * This could be used to create a turtle entity.
 */
class TurtleDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "turtle_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = TurtleEntity(player)
}

@Entry("turtle_instance", "An instance of a turtle entity", Colors.YELLOW, "mdi:turtle")
/**
 * The `TurtleInstance` class is an entry that represents an instance of a turtle entity.
 *
 * ## How could this be used?
 *
 * This could be used to create a turtle entity.
 */
class TurtleInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<TurtleDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "turtle_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class TurtleEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.TURTLE,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is AgeableProperty -> applyAgeableData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}

// Skipped data (no existing data entry available):
// - Turtle: homePosition (TurtleMeta.getHomePosition/setBlockPosition)
// - Turtle: hasEgg (TurtleMeta.hasEgg/setHasEgg)
// - Turtle: layingEgg (TurtleMeta.isLayingEgg/setLayingEgg)
// - Turtle: travelPosition (TurtleMeta.getTravelPosition/setTravelPosition)
// - Turtle: goingHome (TurtleMeta.isGoingHome/setGoingHome)
// - Turtle: travelling (TurtleMeta.isTravelling/setTravelling)
