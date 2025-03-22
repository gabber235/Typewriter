package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.engine.paper.entry.entries.EntityProperty
import org.bukkit.entity.Player
import kotlin.reflect.KClass
import kotlin.reflect.full.safeCast

interface EntityCreator {
    fun create(player: Player): FakeEntity
}

abstract class FakeEntity(
    protected val player: Player
) {
    protected val properties = mutableMapOf<KClass<*>, EntityProperty>()

    abstract val entityId: Int
    abstract val state: EntityState

    fun consumeProperties(vararg properties: EntityProperty) {
        consumeProperties(properties.toList())
    }

    fun consumeProperties(properties: List<EntityProperty>) {
        val changedProperties = properties.filter {
            this.properties[it::class] != it
        }
        if (changedProperties.isEmpty()) return

        changedProperties.forEach {
            this.properties[it::class] = it
        }
        applyProperties(changedProperties)
    }

    abstract fun applyProperties(properties: List<EntityProperty>)

    open fun tick() {}

    open fun spawn(location: PositionProperty) {
        properties[PositionProperty::class] = location
    }

    abstract fun addPassenger(entity: FakeEntity)
    abstract fun removePassenger(entity: FakeEntity)
    abstract operator fun contains(entityId: Int): Boolean
    open fun dispose() {
    }

    fun <P : EntityProperty> property(type: KClass<P>): P? {
        return type.safeCast(properties[type])
    }

    inline fun <reified P : EntityProperty> property(): P? {
        return property(P::class)
    }
}

open class EntityState(
    val eyeHeight: Double = 0.0,
    val speed: Float = 0.2085f,
) {
    operator fun component1(): Double = eyeHeight
    operator fun component2(): Float = speed

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is EntityState) return false

        if (eyeHeight != other.eyeHeight) return false
        if (speed != other.speed) return false

        return true
    }

    override fun hashCode(): Int {
        var result = eyeHeight.hashCode()
        result = 31 * result + speed.hashCode()
        return result
    }

    override fun toString(): String {
        return "EntityState(eyeHeight=$eyeHeight, speed=$speed)"
    }
}