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
import com.typewritermc.entity.entries.data.minecraft.living.TremblingProperty
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.data.minecraft.living.applyTremblingData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("piglin_brute_definition", "A piglin brute entity", Colors.ORANGE, "mdi:axe")
@Tags("piglin_brute_definition")
/**
 * The `PiglinBruteDefinition` class is an entry that shows up as a piglin brute in-game.
 *
 * ## How could this be used?
 * This could be used to create a piglin brute entity.
 */
class PiglinBruteDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "trembling_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = PiglinBruteEntity(player)
}

@Entry("piglin_brute_instance", "An instance of a piglin brute entity", Colors.YELLOW, "mdi:axe")
class PiglinBruteInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<PiglinBruteDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "trembling_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class PiglinBruteEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.PIGLIN_BRUTE,
    player,
) {
    private val rideableSitting = RideableSittingSupport(
        player,
        passenger = { entity },
        isPassengerSpawned = { entity.isSpawned },
        location = { property<PositionProperty>() },
    )

    init {
        consumeProperties(TremblingProperty(false))
    }

    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is PoseProperty -> {
                rideableSitting.applyPose(property.pose, property<PositionProperty>())
                if (property.pose == EntityPose.SITTING) return
            }
            is TremblingProperty -> applyTremblingData(entity, property)
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