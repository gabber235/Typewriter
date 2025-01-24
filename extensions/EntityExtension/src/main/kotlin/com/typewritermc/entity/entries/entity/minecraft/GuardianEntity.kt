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
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.data.minecraft.living.guardian.RetractingSpikesProperty
import com.typewritermc.entity.entries.data.minecraft.living.guardian.applyRetractingSpikesData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("guardian_definition", "A guardian entity", Colors.ORANGE, "tabler:radar-filled")
@Tags("guardian_definition")
/**
 * The `GuardianDefinition` class is an entry that shows up as a guardian in-game.
 *
 * ## How could this be used?
 * This could be used to create a guardian entity.
 */
class GuardianDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Sound = Sound.EMPTY,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "guardian_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = GuardianEntity(player)
}

@Entry("guardian_instance", "An instance of a guardian entity", Colors.YELLOW, "tabler:radar-filled")
class GuardianInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<GuardianDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "guardian_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class GuardianEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.GUARDIAN,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is RetractingSpikesProperty -> applyRetractingSpikesData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}