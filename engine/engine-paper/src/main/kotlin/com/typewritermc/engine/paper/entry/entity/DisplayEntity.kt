package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.core.utils.point.distanceSqrt
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.PropertyCollector
import com.typewritermc.engine.paper.entry.entries.PropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.PropertySupplier
import com.typewritermc.engine.paper.utils.toBukkitLocation
import org.bukkit.SoundCategory
import org.bukkit.entity.Player
import kotlin.reflect.KClass
import kotlin.reflect.full.companionObjectInstance

internal class DisplayEntity(
    private val player: Player,
    creator: EntityCreator,
    private val activityManager: ActivityManager<*>,
    private val collectors: List<PropertyCollector<*>>,
) {
    private val entity = creator.create(player)

    private var lastSoundLocation = activityManager.position

    val state: EntityState
        get() = entity.state

    val entityId: Int
        get() = entity.entityId

    init {
        entity.spawn(activityManager.position)
        applyProperties()
    }

    fun tick() {
        applyProperties()
        entity.tick()

        // When the entity has moved far enough, play a sound
        // FIXME: Magic number
        if ((lastSoundLocation.distanceSqrt(activityManager.position) ?: 0.0) > 1.7) {
            lastSoundLocation = activityManager.position
            val sound = lastSoundLocation.toBukkitLocation().block.blockData.soundGroup.stepSound
            player.playSound(lastSoundLocation.toBukkitLocation(), sound, SoundCategory.NEUTRAL, 0.4f, 1.0f)
        }
    }

    private fun applyProperties() {
        val activeProperties = activityManager.activeProperties
        // Active properties should override the properties from the collectors
        val properties = collectors
            .filter { activeProperties.none { active -> it.type.isInstance(active) } }
            .mapNotNull { it.collect(player) }

        entity.consumeProperties(activeProperties + properties)
    }

    operator fun contains(entityId: Int): Boolean = entity.contains(entityId)

    fun <P : EntityProperty> property(type: KClass<P>) = entity.property(type)

    fun dispose() {
        entity.dispose()
    }
}

/**
 * Group suppliers to collectors based on what they supply.
 */
fun List<Pair<PropertySupplier<*>, Int>>.toCollectors(): List<PropertyCollector<EntityProperty>> {
    return groupBy { it.first.type() }
        .map { (type, suppliers) ->
            val typeSuppliers = suppliers.sortedByDescending { it.second }
                .map { it.first }

            val companion = type.companionObjectInstance
            if (companion !is PropertyCollectorSupplier<*>) {
                error("${type.simpleName} needs to have a companion object that implements PropertyCollectorSupplier")
            }

            val comp = companion as PropertyCollectorSupplier<in EntityProperty>
            comp.collector(typeSuppliers)
        }
}
