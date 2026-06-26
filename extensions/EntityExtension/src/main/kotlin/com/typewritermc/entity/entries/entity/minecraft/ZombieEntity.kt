package com.typewritermc.entity.entries.entity.minecraft

import com.github.retrooper.packetevents.protocol.entity.pose.EntityPose
import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.OnlyTags
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entity.FakeEntity
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import com.typewritermc.engine.paper.entry.entity.SimpleEntityDefinition
import com.typewritermc.engine.paper.entry.entity.SimpleEntityInstance
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.Sound
import com.typewritermc.entity.entries.data.minecraft.PoseProperty
import com.typewritermc.entity.entries.data.minecraft.applyGenericEntityData
import com.typewritermc.entity.entries.entity.RideableSittingSupport
import com.typewritermc.entity.entries.data.minecraft.living.AgeableProperty
import com.typewritermc.entity.entries.data.minecraft.living.applyAgeableData
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("zombie_definition", "A zombie entity", Colors.ORANGE, "game-icons:shambling-zombie")
@Tags("zombie_definition")
/**
 * The `ZombieDefinition` class is an entry that shows up as a zombie in-game.
 *
 * ## How could this be used?
 * This could be used to create a zombie entity.
 */
class ZombieDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = ZombieEntity(player)
}

@Entry("zombie_instance", "An instance of a zombie entity", Colors.YELLOW, "game-icons:shambling-zombie")
class ZombieInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<ZombieDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class ZombieEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.ZOMBIE,
    player,
) {
    private val rideableSitting = RideableSittingSupport(
        player,
        passenger = { entity },
        isPassengerSpawned = { entity.isSpawned },
        location = { property<PositionProperty>() },
    )

    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is PoseProperty -> {
                rideableSitting.applyPose(property.pose, property<PositionProperty>())
                if (property.pose == EntityPose.SITTING) return
            }
            is AgeableProperty -> applyAgeableData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }

    override fun applyPosition(property: PositionProperty) {
        rideableSitting.move(property)
        super.applyPosition(property)
    }

    override fun spawn(location: PositionProperty) {
        rideableSitting.onSpawn(location)
        super.spawn(location)
        rideableSitting.mountIfNeeded()
    }

    override fun contains(entityId: Int): Boolean =
        super.contains(entityId) || rideableSitting.contains(entityId)

    override fun dispose() {
        rideableSitting.dispose()
        super.dispose()
    }
}