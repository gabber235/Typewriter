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
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.data.minecraft.living.raider.CelebratingProperty
import com.typewritermc.entity.entries.data.minecraft.living.raider.applyCelebratingData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("illusioner_definition", "An illusioner entity", Colors.ORANGE, "lucide:eye")
@Tags("illusioner_definition")
/**
 * The `IllusionerDefinition` class is an entry that shows up as an illusioner in-game.
 *
 * ## How could this be used?
 * This could be used to create an illusioner entity, a spellcasting illager that can cast blindness and create duplicates.
 */
class IllusionerDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "raider_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = IllusionerEntity(player)
}

@Entry("illusioner_instance", "An instance of an illusioner entity", Colors.YELLOW, "lucide:eye")
class IllusionerInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<IllusionerDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "raider_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class IllusionerEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.ILLUSIONER,
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
            is CelebratingProperty -> applyCelebratingData(entity, property)
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

// Skipped data (no existing data entry available):
// - SpellTicks: Number of ticks until a spell can be cast (not supported — no existing spellcaster data file)
// - Spellcasting state: Current spell being cast (not supported — no existing spellcaster data file)
