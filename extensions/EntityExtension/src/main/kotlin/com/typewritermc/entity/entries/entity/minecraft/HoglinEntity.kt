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
import com.typewritermc.entity.entries.data.minecraft.living.*
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("hoglin_definition", "A hoglin entity", Colors.ORANGE, "icon-park-outline:pig")
@Tags("hoglin_definition")
/**
 * The `HoglinDefinition` class is an entry that shows up as a hoglin in-game.
 *
 * ## How could this be used?
 * This could be used to create a hoglin entity.
 */
class HoglinDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "trembling_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = HoglinEntity(player)
}

@Entry("hoglin_instance", "An instance of a hoglin entity", Colors.YELLOW, "icon-park-outline:pig")
class HoglinInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<HoglinDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "trembling_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class HoglinEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.HOGLIN,
    player,
) {
    init {
        consumeProperties(TremblingProperty(false))
    }

    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is AgeableProperty -> applyAgeableData(entity, property)
            is TremblingProperty -> applyTremblingData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}