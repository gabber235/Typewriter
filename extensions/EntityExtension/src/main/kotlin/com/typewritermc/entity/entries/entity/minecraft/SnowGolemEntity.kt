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
import com.typewritermc.entity.entries.data.minecraft.living.snowgolem.PumpkinHatProperty
import com.typewritermc.entity.entries.data.minecraft.living.snowgolem.applyPumpkinHatData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("snow_golem_definition", "A snow golem entity", Colors.ORANGE, "game-icons:snowman")
@Tags("snow_golem_definition")
/**
 * The `SnowGolemDefinition` class is an entry that shows up as a snow golem in-game.
 *
 * ## How could this be used?
 * This could be used to create a snow golem entity.
 */
class SnowGolemDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "snow_golem_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = SnowGolemEntity(player)
}

@Entry("snow_golem_instance", "An instance of a snow golem entity", Colors.YELLOW, "game-icons:snowman")
class SnowGolemInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<SnowGolemDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "snow_golem_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class SnowGolemEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.SNOW_GOLEM,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is PumpkinHatProperty -> applyPumpkinHatData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}