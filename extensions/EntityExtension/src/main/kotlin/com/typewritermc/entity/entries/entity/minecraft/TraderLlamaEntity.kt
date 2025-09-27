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
import com.typewritermc.entity.entries.data.minecraft.living.horse.*
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("trader_llama_definition", "A trader llama entity", Colors.ORANGE, "mingcute:exchange-dollar-fill")
@Tags("trader_llama_definition")
/**
 * The `TraderLlamaDefinition` class is an entry that represents a trader llama entity.
 *
 * ## How could this be used?
 * This could be used to create a trader llama entity.
 */
class TraderLlamaDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "llama_data", "chested_horse_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = TraderLlamaEntity(player)
}

@Entry("trader_llama_instance", "An instance of a trader llama entity", Colors.YELLOW, "mingcute:exchange-dollar-fill")
/**
 * The `TraderLlamaInstance` class is an entry that represents an instance of a trader llama entity.
 *
 * ## How could this be used?
 *
 * This could be used to create a trader llama entity.
 */
class TraderLlamaInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<TraderLlamaDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "llama_data", "chested_horse_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class TraderLlamaEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.TRADER_LLAMA,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is AgeableProperty -> applyAgeableData(entity, property)
            is LlamaVariantProperty -> applyLlamaVariantData(entity, property)
            is LlamaCarpetColorProperty -> applyLlamaCarpetColorData(entity, property)
            is ChestedHorseChestProperty -> applyChestedHorseChestData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}