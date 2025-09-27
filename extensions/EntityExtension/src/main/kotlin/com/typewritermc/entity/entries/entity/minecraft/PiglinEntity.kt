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
import com.typewritermc.entity.entries.data.minecraft.living.piglin.DancingProperty
import com.typewritermc.entity.entries.data.minecraft.living.piglin.applyDancingData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("piglin_definition", "A piglin entity", Colors.ORANGE, "fluent-emoji-high-contrast:pig-nose")
@Tags("piglin_definition")
/**
 * The `PiglinDefinition` class is an entry that shows up as a piglin in-game.
 *
 * ## How could this be used?
 * This could be used to create a piglin entity.
 */
class PiglinDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags(
        "generic_entity_data",
        "living_entity_data",
        "mob_data",
        "ageable_data",
        "piglin_data",
        "piglin_dancing_data"
    )
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = PiglinEntity(player)
}

@Entry("piglin_instance", "An instance of a piglin entity", Colors.YELLOW, "fluent-emoji-high-contrast:pig-nose")
class PiglinInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<PiglinDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags(
        "generic_entity_data",
        "living_entity_data",
        "mob_data",
        "ageable_data",
        "piglin_data",
        "piglin_dancing_data"
    )
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class PiglinEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.PIGLIN,
    player,
) {
    init {
        consumeProperties(TremblingProperty(false))
    }

    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is DancingProperty -> applyDancingData(entity, property)
            is AgeableProperty -> applyAgeableData(entity, property)
            is TremblingProperty -> applyTremblingData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}

