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

@Entry("creeper_definition", "A creeper entity", Colors.ORANGE, "mdi:lightning-bolt")
@Tags("creeper_definition")
/**
 * The `CreeperDefinition` class is an entry that represents a creeper entity.
 *
 * ## How could this be used?
 * This could be used to create a creeper entity.
 */
class CreeperDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "creeper_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = CreeperEntity(player)
}

@Entry("creeper_instance", "An instance of a creeper entity", Colors.YELLOW, "mdi:lightning-bolt")
/**
 * The `CreeperInstance` class is an entry that represents an instance of a creeper entity.
 *
 * ## How could this be used?
 *
 * This could be used to create a creeper entity.
 */
class CreeperInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<CreeperDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "creeper_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class CreeperEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.CREEPER,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}

// Skipped data (no existing data entry available):
// - Creeper: state (CreeperMeta.getState/setState - IDLE/FUSE)
// - Creeper: charged (CreeperMeta.isCharged/setCharged)
// - Creeper: ignited (CreeperMeta.isIgnited/setIgnited)
