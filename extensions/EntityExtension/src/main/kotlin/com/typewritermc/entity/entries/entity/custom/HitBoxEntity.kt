package com.typewritermc.entity.entries.entity.custom

import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entity.FakeEntity
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.packetevents.meta
import com.typewritermc.engine.paper.utils.Sound
import com.typewritermc.engine.paper.utils.move
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import me.tofaa.entitylib.meta.other.InteractionMeta
import org.bukkit.entity.Player

@Entry(
    "hit_box_definition",
    "A hit box for an entity to allow quest with a different entity",
    Colors.ORANGE,
    "mdi:cube-outline"
)
/**
 * The `HitBoxDefinition` class is an entry that represents a hit box for an entity to allow quest with a different entity.
 *
 * ## How could this be used?
 * This could be when using a display entity since they don't have a hit box to allow quest with.
 */
class HitBoxDefinition(
    override val id: String = "",
    override val name: String = "",
    val baseEntity: Ref<EntityDefinitionEntry> = emptyRef(),
    val offset: Vector = Vector.ZERO,
    val width: Double = 1.0,
    val height: Double = 1.0,
) : EntityDefinitionEntry {
    override val displayName: Var<String> get() = baseEntity.get()?.displayName ?: ConstVar("")
    override val sound: Sound get() = baseEntity.get()?.sound ?: Sound.EMPTY
    override val data: List<Ref<EntityData<*>>> get() = baseEntity.get()?.data ?: emptyList()

    override fun create(player: Player): FakeEntity {
        val entity = baseEntity.get()?.create(player)
            ?: throw IllegalStateException("A base entity must be specified for entry $name ($id)")
        return HitBoxEntity(player, entity, offset, width, height)
    }
}

class HitBoxEntity(
    player: Player,
    private val baseEntity: FakeEntity,
    private val offset: Vector,
    width: Double,
    height: Double,
) : WrapperFakeEntity(EntityTypes.INTERACTION, player) {
    override val entityId: Int
        get() = baseEntity.entityId

    init {
        entity.meta<InteractionMeta> {
            this.width = width.toFloat()
            this.height = height.toFloat()
            isResponsive = true
        }
    }

    override fun applyProperties(properties: List<EntityProperty>) {
        entity.entityMeta.setNotifyAboutChanges(false)
        properties.forEach(this::applyProperty)
        entity.entityMeta.setNotifyAboutChanges(true)
        baseEntity.consumeProperties(properties)
    }

    override fun applyProperty(property: EntityProperty) {
        when (property) {
            is PositionProperty -> {
                entity.move(property.add(offset))
            }
        }
    }

    override fun spawn(location: PositionProperty) {
        super.spawn(location.add(offset))
        baseEntity.spawn(location)
    }

    override fun addPassenger(entity: FakeEntity) {
        baseEntity.addPassenger(entity)
    }

    override fun removePassenger(entity: FakeEntity) {
        baseEntity.removePassenger(entity)
    }

    override fun contains(entityId: Int): Boolean {
        return super.contains(entityId) || baseEntity.contains(entityId)
    }

    override fun dispose() {
        super.dispose()
        baseEntity.dispose()
    }
}