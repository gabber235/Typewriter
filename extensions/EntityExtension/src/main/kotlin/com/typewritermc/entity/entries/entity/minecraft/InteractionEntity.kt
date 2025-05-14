package com.typewritermc.entity.entries.entity.minecraft

import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.OnlyTags
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entity.FakeEntity
import com.typewritermc.engine.paper.entry.entity.SimpleEntityDefinition
import com.typewritermc.engine.paper.entry.entity.SimpleEntityInstance
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.packetevents.meta
import com.typewritermc.engine.paper.utils.Sound
import com.typewritermc.entity.entries.data.minecraft.BoxSizeProperty
import com.typewritermc.entity.entries.data.minecraft.applyGenericEntityData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import me.tofaa.entitylib.meta.other.InteractionMeta
import org.bukkit.entity.Player

@Entry(
    "interaction_entity_definition",
    "An entity that allows quest, responding to player input",
    Colors.ORANGE,
    "ic:round-touch-app"
)
@Tags("interaction_entity_definition")
/**
 * Interaction entities are invisible hitboxes that can be used to detect player interactions.
 *
 * This entry is meant when you only want to have the quest entity.
 * If you want it to be tied to a specific entity, use the HitboxEntityDefinition instead.
 *
 * ## How could this be used?
 * This could be used to create a custom entity that can detect player interactions.
 */
class InteractionEntityDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Sound = Sound.EMPTY,
    @OnlyTags("generic_entity_data", "interaction_data", "box_size_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    @Default("1.0")
    val width: Double = 1.0,
    @Default("1.0")
    val height: Double = 1.0,
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity {
        return InteractionEntity(player, width, height)
    }
}

@Entry("interaction_entity_instance", "An instance of an quest entity", Colors.YELLOW, "ic:round-touch-app")
class InteractionEntityInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<InteractionEntityDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "interaction_data", "box_size_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out EntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

class InteractionEntity(
    player: Player,
    width: Double,
    height: Double,
) : WrapperFakeEntity(EntityTypes.INTERACTION, player) {
    init {
        consumeProperties(BoxSizeProperty(width, height))
    }

    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is BoxSizeProperty -> {
                entity.meta<InteractionMeta> {
                    this.width = property.width.toFloat()
                    this.height = property.height.toFloat()
                }
            }
        }
        if (applyGenericEntityData(entity, property)) return
    }
}
