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

@Entry("allay_definition", "A allay entity", Colors.ORANGE, "ph:flying-saucer-fill")
@Tags("allay_definition")
/**
 * The `AllayDefinition` class is an entry that represents an allay entity.
 *
 * ## How could this be used?
 * This could be used to create an allay entity.
 */
class AllayDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "allay_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = AllayEntity(player)
}

@Entry("allay_instance", "An instance of a allay entity", Colors.YELLOW, "ph:flying-saucer-fill")
/**
 * The `Allay Instance` class is an entry that represents an instance of an allay entity.
 *
 * ## How could this be used?
 *
 * This could be used to create an allay entity.
 */
class AllayInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<AllayDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "allay_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class AllayEntity(player: Player) : WrapperFakeEntity(EntityTypes.ALLAY, player) {
    override fun applyProperty(property: EntityProperty) {
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}