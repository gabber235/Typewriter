package com.typewritermc.region.entries.display

import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.*
import it.unimi.dsi.fastutil.ints.IntOpenHashSet
import org.bukkit.entity.Player
import java.util.concurrent.ConcurrentHashMap

/** Where one boundary entity stands, as the entity displays hand it to [BoundaryEntities]. */
internal interface EntityPlacement {
    val x: Double
    val y: Double
    val z: Double

    fun positionProperty(): PositionProperty
}

/**
 * One player's fake entities along a region boundary, one per placement, built from
 * [definition]. Entities are keyed by placement index, so a placement that keeps its index
 * keeps its entity and only sends the packets its movement needs.
 *
 * Rendering runs off the main thread while removal from the audience and a reload both
 * dispose from another, so the map is concurrent and disposal is one way: once disposed, the
 * collection never accepts another entity. Without that, an entity spawned just after the
 * sweep survives as a fake nobody owns and nobody can despawn.
 */
internal class BoundaryEntities(val definition: EntityDefinitionEntry) {
    private val entities = ConcurrentHashMap<Int, BoundEntity>()

    @Volatile
    private var placements: List<EntityPlacement?> = emptyList()

    @Volatile
    private var disposed = false

    /**
     * Moves the entities to [placements] and ticks them. A `null` placement has no entity, and
     * with a [window] only the placements inside it do.
     */
    fun update(player: Player, placements: List<EntityPlacement?>, window: NearWindow?) {
        this.placements = placements
        reconcile(player, placements, window)

        for (entity in entities.values) {
            entity.entity.consumeProperties(entity.collectors.mapNotNull { it.collect(player) })
            entity.entity.tick()
        }
    }

    private fun reconcile(player: Player, placements: List<EntityPlacement?>, window: NearWindow?) {
        val active = IntOpenHashSet()
        for (index in placements.indices) {
            val placement = placements[index] ?: continue
            if (window == null || window.contains(placement.x, placement.y, placement.z)) active.add(index)
        }

        val iterator = entities.entries.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (entry.key in active) continue
            entry.value.entity.dispose()
            iterator.remove()
        }

        val activeIterator = active.intIterator()
        while (activeIterator.hasNext()) {
            val index = activeIterator.nextInt()
            if (entities.containsKey(index)) continue
            val placement = placements[index] ?: continue
            val entity = definition.create(player)
            entity.spawn(placement.positionProperty())
            if (!track(index, BoundEntity(entity, collectorsFor(index)))) entity.dispose()
        }
    }

    /**
     * The definition's data plus a [FakeProvider] that supplies the placement's position at
     * top priority, read from whatever placements the latest [update] handed in.
     */
    private fun collectorsFor(index: Int): List<PropertyCollector<EntityProperty>> {
        val position = FakeProvider(PositionProperty::class) { placements.getOrNull(index)?.positionProperty() }
        return (definition.data.withPriority() + (position to Int.MAX_VALUE)).toCollectors()
    }

    /** `false` when the collection was already disposed, leaving [entity] to the caller. */
    private fun track(index: Int, entity: BoundEntity): Boolean {
        var accepted = false
        entities.compute(index) { _, previous ->
            previous?.entity?.dispose()
            if (disposed) return@compute null
            accepted = true
            entity
        }
        return accepted
    }

    fun dispose() {
        disposed = true
        val iterator = entities.entries.iterator()
        while (iterator.hasNext()) {
            iterator.next().value.entity.dispose()
            iterator.remove()
        }
    }

    private class BoundEntity(
        val entity: FakeEntity,
        val collectors: List<PropertyCollector<EntityProperty>>,
    )
}
