package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.toVector
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry

@Entry("look_at_block_activity", "A look at block activity", Colors.BLUE, "fa6-solid:cube")
/**
 * The `LookAtBlockActivityEntry` makes the entity look at a specific block.
 *
 * ## Usage
 * This can be used to make an entity appear to observe blocks around it, such as observing a specific structure.
 */
class LookAtBlockActivityEntry(
    override val id: String = "",
    override val name: String = "",
    val blockPosition: Position = Position.ORIGIN,
    @Help("The activity that supplies the x, y, z of the block to look at.")
    val childActivity: Ref<out EntityActivityEntry> = emptyRef()
) : GenericEntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<in ActivityContext> {
        val activity = childActivity.get() ?: IdleActivity
        return LookAtBlockActivity(
            currentLocation,
            blockPosition.add(0.0, -1.0, 0.0),
            activity.create(context, currentLocation)
        )
    }
}

class LookAtBlockActivity(
    startLocation: PositionProperty,
    private val blockPosition: Position,
    private val childActivity: EntityActivity<ActivityContext>,
) : EntityActivity<ActivityContext> {
    private val yawVelocity = Velocity(0f)
    private val pitchVelocity = Velocity(0f)
    private var currentDirection: LookDirection = LookDirection(startLocation.yaw, startLocation.pitch)

    override fun initialize(context: ActivityContext) {
        childActivity.initialize(context)
    }

    override fun tick(context: ActivityContext): TickResult {
        val npcEyeVector = currentPosition.add(y = context.entityState.eyeHeight)

        val direction = blockPosition.minus(npcEyeVector).toVector().normalize()

        val targetYaw = getLookYaw(direction.x, direction.z)
        val targetPitch = getLookPitch(direction.x, direction.y, direction.z)

        val (yaw, pitch) = updateLookDirection(
            currentDirection,
            LookDirection(targetYaw, targetPitch),
            yawVelocity,
            pitchVelocity
        )

        currentDirection = LookDirection(yaw, pitch)

        return childActivity.tick(context)
    }

    override fun dispose(context: ActivityContext) {
        yawVelocity.value = 0f
        pitchVelocity.value = 0f
        childActivity.dispose(context)
    }

    override val currentPosition: PositionProperty
        get() = childActivity.currentPosition.copy(yaw = currentDirection.yaw, pitch = currentDirection.pitch)

    override val currentProperties: List<EntityProperty>
        get() = childActivity.currentProperties.filter { it !is PositionProperty } + currentPosition
}
