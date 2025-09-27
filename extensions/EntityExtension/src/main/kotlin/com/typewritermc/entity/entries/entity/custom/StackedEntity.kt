package com.typewritermc.entity.entries.entity.custom

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entity.EntityState
import com.typewritermc.engine.paper.entry.entity.FakeEntity
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.Sound
import org.bukkit.entity.Player

@Entry("stacked_entity_definition", "A stacking of entities", Colors.ORANGE, "ic:baseline-stacked-bar-chart")
/**
 * The `StackedEntityDefinition` class is an entry that represents a stacking of entities.
 *
 * :::caution
 * All properties will be shared between all entities.
 * Even if it is defined on only one entity.
 * :::
 *
 * Only the bottom entity will have the location of the `StackedEntity` instance.
 *
 * ## How could this be used?
 * This could be used to stack entities on top of each other.
 * Like having a hologram above a mob.
 */
class StackedEntityDefinition(
    override val id: String = "",
    override val name: String = "",
    @Help("The entities that will be stacked on top of each other. First entity will be the bottom entity.")
    val definitions: List<Ref<EntityDefinitionEntry>> = emptyList(),
) : EntityDefinitionEntry {
    override val displayName: Var<String> get() = definitions.firstOrNull()?.get()?.displayName ?: ConstVar("")
    override val sound: Var<Sound> get() = definitions.firstOrNull()?.get()?.sound ?: ConstVar(Sound.EMPTY)
    override val data: List<Ref<EntityData<*>>>
        get() = definitions.mapNotNull { it.get() }.flatMap { it.data }

    override fun create(player: Player): FakeEntity = StackedEntity(player, definitions.mapNotNull { it.get() }.map { it.create(player) })
}

class StackedEntity(
    player: Player,
    private val entities: List<FakeEntity>,
) : FakeEntity(player) {
    override val entityId: Int
        get() = entities.firstOrNull()?.entityId ?: -1

    override val state: EntityState
        get() = entities.firstOrNull()?.state ?: EntityState()

    override fun applyProperties(properties: List<EntityProperty>) {
        if (entities.isEmpty()) return
        entities.asSequence().forEach { it.consumeProperties(properties) }
    }

    override fun spawn(location: PositionProperty) {
        if (entities.isEmpty()) return
        val baseEntity = entities.first()
        for (entity in entities) {
            entity.spawn(location)
            if (baseEntity == entity) continue
            baseEntity.addPassenger(entity)
        }
    }

    override fun tick() {
        super.tick()
        entities.forEach { it.tick() }
    }

    override fun addPassenger(entity: FakeEntity) {
        entities.firstOrNull()?.addPassenger(entity)
    }

    override fun removePassenger(entity: FakeEntity) {
        entities.firstOrNull()?.removePassenger(entity)
    }

    override fun contains(entityId: Int): Boolean = entities.any { it.contains(entityId) }

    override fun dispose() {
        entities.forEach { it.dispose() }
    }
}