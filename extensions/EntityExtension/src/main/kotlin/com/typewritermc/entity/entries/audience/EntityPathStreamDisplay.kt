package com.typewritermc.entity.entries.audience

import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityDefinitionEntry
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.PropertyCollector
import com.typewritermc.entity.entries.cinematic.FakeProvider
import com.typewritermc.roadnetwork.entries.PathStreamDisplay
import org.bukkit.entity.Player

class EntityPathStreamDisplay(
    val player: Player,
    val definition: EntityDefinitionEntry,
) : PathStreamDisplay {
    private var entity: FakeEntity? = null
    private var collectors: List<PropertyCollector<EntityProperty>> = emptyList()
    private var lastPosition: PositionProperty = PositionProperty.Companion.ORIGIN

    override fun display(position: Position) {
        lastPosition = position.toProperty()
        if (entity == null) {
            val prioritizedPropertySuppliers = definition.data.withPriority() +
                    (FakeProvider(PositionProperty::class) { lastPosition } to Int.MAX_VALUE)

            collectors = prioritizedPropertySuppliers.toCollectors()
            entity = definition.create(player)
            entity?.spawn(lastPosition)
        }

        val collectedProperties = collectors.mapNotNull { it.collect(player) }
        entity?.consumeProperties(collectedProperties)
        entity?.tick()
    }

    override fun dispose() {
        entity?.dispose()
    }
}