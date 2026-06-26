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
    val width: Double = 0.6,
    val height: Double = 1.8,
) {
    operator fun component1(): Double = eyeHeight
    operator fun component2(): Float = speed
    operator fun component3(): Double = width
    operator fun component4(): Double = height

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is EntityState) return false

        if (eyeHeight != other.eyeHeight) return false
        if (speed != other.speed) return false
        if (width != other.width) return false
        if (height != other.height) return false

        return true
    }

    override fun hashCode(): Int {
        var result = eyeHeight.hashCode()
        result = 31 * result + speed.hashCode()
        result = 31 * result + width.hashCode()
        result = 31 * result + height.hashCode()
        return result
    }

    override fun toString(): String {
        return "EntityState(eyeHeight=$eyeHeight, speed=$speed, width=$width, height=$height)"
    }
}

/**
 * Encapsulates the movement and interaction capabilities of an entity for which the pathfinding is being performed.
 *
 * @param height          The entity's height in blocks, used for vertical clearance checks.
 * @param width           The entity's width in blocks, used for horizontal clearance checks.
 * @param maxStepHeight   The maximum height in blocks the entity can step up without jumping.
 * @param maxJumpHeight   The maximum height in blocks the entity can jump. This is measured
 *                        from the surface of the starting block to the surface of the destination block.
 * @param maxFallDistance The maximum vertical distance in blocks the entity will pathfind
 *                        downwards in a single move.
 * @param jumpStrength    The entity jump strength, used for jump velocity calculation
 * @param canJump         Determines whether the entity can perform jumps.
 * @param canInteract     Determines whether the entity can open interactable blocks like wooden
 *                        doors, fence gates, and trapdoors.
 * @param canSwim         Determines whether the entity can move through liquids.
 * @param canClimb        Determines whether the entity can climb objects like ladders and vines.
 */
data class EntityPathingCapabilities(
    val width: Double = 0.6,
    val height: Double = 1.8,
    val maxStepHeight: Double = 0.6,
    val maxJumpHeight: Double = 1.25,
    val maxFallDistance: Double = 2.1,
    val jumpStrength: Double = 0.42,
    val canJump: Boolean = true,
    val canInteract: Boolean = false,
    val canSwim: Boolean = false,
    val canClimb: Boolean = false
) {
    companion object {
        val DEFAULT = EntityPathingCapabilities()
    }

    init {
        require(width > 0) { "Entity width must be positive, but was $width" }
        require(height > 0) { "Entity height must be positive, but was $height" }
        require(maxStepHeight >= 0) { "Max step height must be non-negative, but was $maxStepHeight" }
        require(maxJumpHeight >= 0) { "Max jump height must be non-negative, but was $maxJumpHeight" }
        require(maxFallDistance >= 0) { "Max fall distance must be non-negative, but was $maxFallDistance" }
        require(jumpStrength >= 0) { "Entity jump strength must be non-negative, but was $jumpStrength" }
    }
}
