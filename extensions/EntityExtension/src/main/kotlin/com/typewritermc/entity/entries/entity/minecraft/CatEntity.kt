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
import com.typewritermc.entity.entries.data.minecraft.DyeColorProperty
import com.typewritermc.entity.entries.data.minecraft.applyDyeColorData
import com.typewritermc.entity.entries.data.minecraft.applyGenericEntityData
import com.typewritermc.entity.entries.data.minecraft.living.AgeableProperty
import com.typewritermc.entity.entries.data.minecraft.living.applyAgeableData
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.data.minecraft.living.cat.CatVariantProperty
import com.typewritermc.entity.entries.data.minecraft.living.cat.applyCatVariantData
import com.typewritermc.entity.entries.data.minecraft.living.tameable.applyTameableData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("cat_definition", "A cat entity", Colors.ORANGE, "ph:cat-fill")
@Tags("cat_definition")
/**
 * The `CatDefinition` class is an entry that represents a cat entity.
 *
 * ## How could this be used?
 * This could be used to create a cat entity.
 */
class CatDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "tameable_data", "cat_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = CatEntity(player)
}

@Entry("cat_instance", "An instance of a cat entity", Colors.YELLOW, "ph:cat-fill")
/**
 * The `Cat Instance` class is an entry that represents an instance of a cat entity.
 *
 * ## How could this be used?
 *
 * This could be used to create a cat entity.
 */
class CatInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<CatDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "tameable_data", "cat_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class CatEntity(player: Player) : WrapperFakeEntity(EntityTypes.CAT, player) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is CatVariantProperty -> applyCatVariantData(entity, property)
            is DyeColorProperty -> applyDyeColorData(entity, property)
            is AgeableProperty -> applyAgeableData(entity, property)
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
        if (applyTameableData(entity, property)) return
    }
}