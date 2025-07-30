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
import com.typewritermc.entity.entries.data.minecraft.living.horse.*
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("llaama_definition", "A llama entity", Colors.ORANGE, "simple-icons:ollama")
@Tags("llama_definition")
/**
 * The `LlamaDefinition` class is an entry that represents a llama entity.
 *
 * ## How could this be used?
 * This could be used to create a llama entity.
 */
class LlamaDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "horse_data", "chested_horse_data", "llama_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = LlamaEntity(player)
}

@Entry("llama_instance", "An instance of a llama entity", Colors.YELLOW, "simple-icons:ollama")
/**
 * The `LlamaInstance` class is an entry that represents an instance of a llama entity.
 *
 * ## How could this be used?
 *
 * This could be used to create a llama entity.
 */
class LlamaInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<LlamaDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "horse_data", "chested_horse_data", "llama_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class LlamaEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.LLAMA,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is LlamaVariantProperty -> applyLlamaVariantData(entity, property)
            is LlamaCarpetColorProperty -> applyLlamaCarpetColorData(entity, property)
            is ChestedHorseChestProperty -> applyChestedHorseChestData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}