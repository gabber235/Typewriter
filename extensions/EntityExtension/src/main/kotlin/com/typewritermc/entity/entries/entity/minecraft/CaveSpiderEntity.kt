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

@Entry("cave_spider_definition", "A cave spider entity", Colors.ORANGE, "mdi:spider")
@Tags("cave_spider_definition")
/**
 * The `CaveSpiderDefinition` class is an entry that shows up as a cave spider in-game.
 *
 * ## How could this be used?
 * This could be used to create a cave spider entity.
 */
class CaveSpiderDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Sound = Sound.EMPTY,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "spider_data", "cave_spider_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = CaveSpiderEntity(player)
}

@Entry("cave_spider_instance", "An instance of a cave spider entity", Colors.YELLOW, "mdi:spider")
class CaveSpiderInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<CaveSpiderDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "spider_data", "cave_spider_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class CaveSpiderEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.CAVE_SPIDER,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}