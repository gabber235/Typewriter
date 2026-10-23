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
import com.typewritermc.entity.entries.data.minecraft.living.bat.HangingProperty
import com.typewritermc.entity.entries.data.minecraft.living.bat.applyBatHangingData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("bat_definition", "A bat entity", Colors.ORANGE, "mdi:bat")
@Tags("bat_definition")
/**
 * The `BatDefinition` class is an entry that represents a bat entity.
 *
 * ## How could this be used?
 * This could be used to create a bat that flutters around a cave or hangs from its ceiling.
 * The bat flaps its wings for as long as it is not hanging, even when it stands still.
 */
class BatDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "bat_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = BatEntity(player)
}

@Entry("bat_instance", "An instance of a bat entity", Colors.YELLOW, "mdi:bat")
/**
 * The `BatInstance` class is an entry that represents an instance of a bat entity.
 *
 * ## How could this be used?
 * This could be used to place a bat in the world, for example one hanging in a cave or circling a spooky tower.
 */
class BatInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<BatDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "bat_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class BatEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.BAT,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is HangingProperty -> applyBatHangingData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}
