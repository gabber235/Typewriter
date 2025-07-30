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
import com.typewritermc.entity.entries.data.minecraft.living.SizeProperty
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.data.minecraft.living.applySizeData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("magma_cube_definition", "A magma cube entity", Colors.ORANGE, "ion:cube")
@Tags("magma_cube_definition")
/**
 * The `MagmaCubeDefinition` class is an entry that represents a magma cube entity.
 *
 * ## How could this be used?
 * This could be used to create a magma cube entity.
 */
class MagmaCubeDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "slime_data", "magma_cube_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = MagmaCubeEntity(player)
}

@Entry("magma_cube_instance", "An instance of a magma cube entity", Colors.YELLOW, "ion:cube")
/**
 * The `MagmaCubeInstance` class is an entry that represents an instance of a magma cube entity.
 *
 * ## How could this be used?
 *
 * This could be used to create a magma cube entity.
 */
class MagmaCubeInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<MagmaCubeDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data", "slime_data", "magma_cube_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class MagmaCubeEntity(player: Player) : WrapperFakeEntity(
    EntityTypes.MAGMA_CUBE,
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is SizeProperty -> applySizeData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}