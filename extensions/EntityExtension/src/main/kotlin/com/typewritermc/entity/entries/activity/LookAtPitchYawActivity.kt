package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.*

@Entry("look_at_pitch_yaw_activity", "A look at pitch and yaw activity", Colors.BLUE, "fa6-solid:compass")
/**
 * The `LookAtPitchYawActivityEntry` makes the entity look at a specific pitch and yaw.
 *
 * ## Usage
 * This can be used to make an entity face a specific direction without focusing on a block.
 */
class LookAtPitchYawActivityEntry(
    override val id: String = "",
    override val name: String = "",
    @InnerMin(Min(-90))
    @InnerMax(Max(90))
    val pitch: Var<Float> = ConstVar(0f),
    @InnerMin(Min(-180))
    @InnerMax(Max(180))
    val yaw: Var<Float> = ConstVar(0f),
    @Help("The activity which may return xyz")
    val childActivity: Ref<out EntityActivityEntry> = emptyRef()
) : GenericEntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<in ActivityContext> {
        val activity = childActivity.get() ?: IdleActivity
        return LookAtPitchYawActivity(currentLocation, yaw, pitch, activity.create(context, currentLocation))
    }
}

class LookAtPitchYawActivity(
    startLocation: PositionProperty,
    private val targetYaw: Var<Float>,
    private val targetPitch: Var<Float>,
    private val childActivity: EntityActivity<ActivityContext>,
) : EntityActivity<ActivityContext> {
    private val yawVelocity = Velocity(0f)
    private val pitchVelocity = Velocity(0f)
    private var currentDirection: LookDirection = LookDirection(startLocation.yaw, startLocation.pitch)

    override fun activate(context: ActivityContext, position: PositionProperty) {
        currentDirection = LookDirection(position.yaw, position.pitch)
        childActivity.activate(context, position)
    }

    override fun tick(context: ActivityContext): TickResult {
        val player = context.randomViewer ?: return TickResult.IGNORED
        val (yaw, pitch) = updateLookDirection(
            currentDirection,
            LookDirection(targetYaw.get(player), targetPitch.get(player)),
            yawVelocity,
            pitchVelocity
        )

        currentDirection = LookDirection(yaw, pitch)

        return childActivity.tick(context)
    }

    override fun deactivate(context: ActivityContext) {
        yawVelocity.value = 0f
        pitchVelocity.value = 0f

        childActivity.deactivate(context)
    }

    override fun dispose() {
        childActivity.dispose()
    }

    override val currentPosition: PositionProperty
        get() = childActivity.currentPosition.copy(yaw = currentDirection.yaw, pitch = currentDirection.pitch)

    override val currentProperties: List<EntityProperty>
        get() = childActivity.currentProperties.filter { it !is PositionProperty } + currentPosition
}
