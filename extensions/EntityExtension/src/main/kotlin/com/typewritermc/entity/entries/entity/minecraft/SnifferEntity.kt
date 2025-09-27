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

@Entry("sniffer_definition", "A sniffer entity", Colors.ORANGE, "mdi:leaf")
@Tags("sniffer_definition")
/**
 * The `SnifferDefinition` class is an entry that represents a sniffer entity.
 *
 * This can be used to create a sniffer that supports generic, living, and ageable data.
 */
class SnifferDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "sniffer_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = SnifferEntity(player)
}

@Entry("sniffer_instance", "An instance of a sniffer entity", Colors.YELLOW, "mdi:leaf")
/**
 * The `SnifferInstance` class is an entry that represents an instance of a sniffer entity.
 */
class SnifferInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<SnifferDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "sniffer_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class SnifferEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.SNIFFER,
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
// - Sniffer: state (SnifferMeta.getState/setState)
// - Sniffer: dropSeedAtTick (SnifferMeta.getDropSeedAtTick/setDropSeedAtTick)
