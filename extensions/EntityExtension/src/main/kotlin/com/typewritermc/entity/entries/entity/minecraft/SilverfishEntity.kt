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
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("silverfish_definition", "A silverfish entity", Colors.ORANGE, "game-icons:caterpillar")
@Tags("silverfish_definition")
/**
 * The `SilverfishDefinition` class is an entry that represents a silverfish entity.
 *
 * ## How could this be used?
 * This could be used to create a silverfish that scurries out of the cracked stone bricks of a stronghold.
 */
class SilverfishDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = SilverfishEntity(player)
}

@Entry("silverfish_instance", "An instance of a silverfish entity", Colors.YELLOW, "game-icons:caterpillar")
/**
 * The `SilverfishInstance` class is an entry that represents an instance of a silverfish entity.
 *
 * ## How could this be used?
 * This could be used to place a silverfish in the world, for example a swarm crawling through a mine shaft
 * that the player has to clear out.
 */
class SilverfishInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<SilverfishDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class SilverfishEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.SILVERFISH,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}
