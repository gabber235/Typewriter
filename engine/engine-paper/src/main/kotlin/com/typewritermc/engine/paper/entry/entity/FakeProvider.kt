package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.PropertySupplier
import org.bukkit.entity.Player
import kotlin.reflect.KClass

/**
 * A [PropertySupplier] backed by a plain supplier function, for driving a fake entity's
 * properties from code instead of from entry data.
 *
 * Compose it with an entity definition's data through [withPriority] and [toCollectors] to
 * override individual properties in the collector pipeline. This is how a cinematic feeds
 * its recorded position and pose into an entity, and how a boundary display places its
 * entities, while the definition's other data (skin, equipment) keeps applying normally.
 */
class FakeProvider<P : EntityProperty>(private val klass: KClass<P>, private val supplier: () -> P?) :
    PropertySupplier<P> {
    override fun type(): KClass<P> = klass

    override fun build(player: Player): P {
        return supplier() ?: throw IllegalStateException("Could not build property $klass")
    }

    override fun canApply(player: Player): Boolean {
        return supplier() != null
    }
}
