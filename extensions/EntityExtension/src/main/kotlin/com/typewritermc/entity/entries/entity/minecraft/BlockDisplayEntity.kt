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
import com.typewritermc.entity.entries.data.minecraft.display.applyDisplayEntityData
import com.typewritermc.entity.entries.data.minecraft.display.block.BlockProperty
import com.typewritermc.entity.entries.data.minecraft.display.block.applyBlockData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("block_display_definition", "A block display entity", Colors.ORANGE, "heroicons:cube-transparent-16-solid")
@Tags("block_display_definition")
/**
 * The `BlockDisplayDefinition` class is an entry that represents a block display entity.
 *
 * ## How could this be used?
 * This could be used to create an entity that displays a block.
 */
class BlockDisplayDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "display_data", "block_display_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = BlockDisplayEntity(player)
}

@Entry("block_display_instance", "An instance of a block display entity", Colors.YELLOW, "heroicons:cube-transparent-16-solid")
class BlockDisplayInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<BlockDisplayDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "display_data", "block_display_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

open class BlockDisplayEntity(player: Player) : WrapperFakeEntity(EntityTypes.BLOCK_DISPLAY, player) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is BlockProperty -> applyBlockData(entity, property)
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyDisplayEntityData(entity, property)) return
    }
}