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
import com.typewritermc.entity.entries.data.minecraft.living.bee.AngryProperty
import com.typewritermc.entity.entries.data.minecraft.living.bee.NectarProperty
import com.typewritermc.entity.entries.data.minecraft.living.bee.StungProperty
import com.typewritermc.entity.entries.data.minecraft.living.bee.applyBeeAngryData
import com.typewritermc.entity.entries.data.minecraft.living.bee.applyBeeStungData
import com.typewritermc.entity.entries.data.minecraft.living.bee.applyBeeNectarData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("bee_definition", "A bee entity", Colors.ORANGE, "carbon:bee")
@Tags("bee_definition")
/**
 * The `BeeDefinition` class is an entry that represents a bee entity.
 *
 * ## How could this be used?
 * This could be used to create a bee entity.
 */
class BeeDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Sound = Sound.EMPTY,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "bee_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = BeeEntity(player)
}

@Entry("bee_instance", "An instance of a bee entity", Colors.YELLOW, "carbon:bee")
class BeeInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<BeeDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "ageable_data", "bee_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class BeeEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.BEE,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is AgeableProperty -> applyAgeableData(entity, property)
            is AngryProperty -> applyBeeAngryData(entity, property)
            is StungProperty -> applyBeeStungData(entity, property)
            is NectarProperty -> applyBeeNectarData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}