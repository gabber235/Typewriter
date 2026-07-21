package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.point.distanceSquared
import com.typewritermc.core.utils.point.toVector
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.isLookable
import org.bukkit.entity.Player

private val playerLookCloseRange by snippet("entity.activity.look_close.range", 10.0)
private val playerLookCloseSmoothingTime by snippet(
    "entity.activity.look_close.smoothing",
    0.2f,
    "This determines how quickly the npc will look at the player."
)

@Entry("look_close_activity", "A look close activity", Colors.BLUE, "fa6-solid:eye")
/**
 * The `LookCloseActivityEntry` is an activity that makes the entity look to the player closest to it.
 *
 * The activity is specific to the player, then the entity will look at that player.
 *
 * ## How could this be used?
 * This could be used to make an entity look at the player closest to it.
 */
class LookCloseActivityEntry(
    override val id: String = "",
    override val name: String = "",
) : GenericEntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<in ActivityContext> {
        return LookCloseActivity(currentLocation)
    }
}

class LookCloseActivity(
    private val startPosition: PositionProperty,
) : EntityActivity<ActivityContext> {
    private var target: Target? = null
    private val yawVelocity = Velocity(0f)
    private val pitchVelocity = Velocity(0f)

    override var currentPosition: PositionProperty = startPosition

    override fun initialize(context: ActivityContext, position: PositionProperty) {
        currentPosition = position
        yawVelocity.value = 0f
        pitchVelocity.value = 0f
    }

    private fun findNewTarget(context: ActivityContext): Target? {
        val closestTarget = context.viewers
            .filter { it.isLookable }
            .minByOrNull { currentPosition.distanceSquared(it.location) ?: Double.POSITIVE_INFINITY }

        if (closestTarget == null) {
            return null
        }
        val distance = currentPosition.distanceSquared(closestTarget.location)

        if (distance == null || distance > playerLookCloseRange * playerLookCloseRange) {
            return null
        }

        return Target(closestTarget)
    }

    override fun tick(context: ActivityContext): TickResult {
        if (!context.isViewed) {
            this.target = null
            return TickResult.CONSUMED
        }
        if (target?.shouldRefresh == true) this.target = null

        var target = target
        if (target == null) target = findNewTarget(context)
        if (target == null) {
            // We want to rotate back to the start position, so the npc doesn't look at a wall or something like that.
            val targetYaw = startPosition.yaw
            val targetPitch = startPosition.pitch

            val (yaw, pitch) = updateLookDirection(
                LookDirection(currentPosition.yaw, currentPosition.pitch),
                LookDirection(targetYaw, targetPitch),
                yawVelocity,
                pitchVelocity,
                smoothTime = playerLookCloseSmoothingTime,
            )

            currentPosition =
                PositionProperty(
                    currentPosition.world,
                    currentPosition.x,
                    currentPosition.y,
                    currentPosition.z,
                    yaw,
                    pitch
                )

            return TickResult.IGNORED
        }

        this.target = target

        val npcEyePosition = currentPosition.add(y = context.entityState.eyeHeight)
        val direction = target.eyePosition.toVector().minus(npcEyePosition).normalize()

        val targetYaw = getLookYaw(direction.x, direction.z)
        val targetPitch = getLookPitch(direction.x, direction.y, direction.z)

        val (yaw, pitch) = updateLookDirection(
            LookDirection(currentPosition.yaw, currentPosition.pitch),
            LookDirection(targetYaw, targetPitch),
            yawVelocity,
            pitchVelocity
        )

        currentPosition =
            PositionProperty(currentPosition.world, currentPosition.x, currentPosition.y, currentPosition.z, yaw, pitch)
        return TickResult.CONSUMED
    }

    override fun dispose(context: ActivityContext) {
        target = null
        yawVelocity.value = 0f
        pitchVelocity.value = 0f
    }

    inner class Target(val player: Player, private val lookupTime: Long = System.currentTimeMillis()) {
        val shouldRefresh: Boolean
            get() {
                if (!player.isValid) return true
                val distanceSquared = this@Target.position.distanceSquared(player.location.toProperty()) ?: return true
                if (distanceSquared > playerLookCloseRange * playerLookCloseRange) return true
                return System.currentTimeMillis() - lookupTime > 1000
            }

        val position: PositionProperty
            get() = player.location.toProperty()

        val eyePosition: PositionProperty
            get() = player.eyeLocation.toProperty()
    }

}


