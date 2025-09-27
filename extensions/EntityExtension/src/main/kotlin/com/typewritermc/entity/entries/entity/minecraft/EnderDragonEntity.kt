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
import com.typewritermc.entity.entries.data.minecraft.living.enderdragon.EnderDragonPhaseProperty
import com.typewritermc.entity.entries.data.minecraft.living.enderdragon.applyEnderDragonPhaseData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("ender_dragon_definition", "A ender_dragon entity", Colors.ORANGE, "game-icons:dragon-head")
@Tags("ender_dragon_definition")
/**
 * The `EnderDragonDefinition` class is an entry that shows up as an ender_dragon in-game.
 *
 * ## How could this be used?
 * This could be used to create an ender_dragon entity.
 */
class EnderDragonDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ender_dragon_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = EnderDragonEntity(player)
}

@Entry("ender_dragon_instance", "An instance of a ender_dragon entity", Colors.YELLOW, "game-icons:dragon-head")
class EnderDragonInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<EnderDragonDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ender_dragon_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class EnderDragonEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.ENDER_DRAGON,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is EnderDragonPhaseProperty -> applyEnderDragonPhaseData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}