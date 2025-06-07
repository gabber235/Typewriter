package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.point.toVector
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.isLookable
import org.bukkit.entity.Player
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.max

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

    override fun initialize(context: ActivityContext) {}

    private fun findNewTarget(context: ActivityContext): Target? {
        val closestTarget = context.viewers
            .filter { it.isLookable }
            .minByOrNull { currentPosition.distanceSqrt(it.location) ?: Double.POSITIVE_INFINITY }

        if (closestTarget == null) {
            return null
        }
        val distance = currentPosition.distanceSqrt(closestTarget.location)

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
                if (player.location.world.uid.toString() != this@Target.position.world.identifier) return true
                if (this@Target.position.distanceSquared(player.location.toProperty()) > playerLookCloseRange * playerLookCloseRange) return true
                return System.currentTimeMillis() - lookupTime > 1000
            }

        val position: PositionProperty
            get() = player.location.toProperty()

        val eyePosition: PositionProperty
            get() = player.eyeLocation.toProperty()
    }

}

data class LookDirection(
    val yaw: Float,
    val pitch: Float,
)

fun updateLookDirection(
    current: LookDirection,
    target: LookDirection,
    yawVelocity: Velocity,
    pitchVelocity: Velocity,
    smoothTime: Float = 0.2f
): Pair<Float, Float> {
    val correctedYaw = if (current.yaw - target.yaw > 180) {
        current.yaw - 360
    } else if (current.yaw - target.yaw < -180) {
        current.yaw + 360
    } else {
        current.yaw
    }

    val yaw = smoothDamp(correctedYaw, target.yaw, yawVelocity, smoothTime)
    val pitch = smoothDamp(current.pitch, target.pitch, pitchVelocity, smoothTime)

    return yaw to pitch
}

fun normalizeYaw(yaw: Float): Float {
    return (yaw + 180) % 360 - 180
}

class Velocity(var value: Float)

fun smoothDamp(
    current: Float,
    target: Float,
    currentVelocity: Velocity,
    smoothTime: Float,
    maxSpeed: Float = Float.POSITIVE_INFINITY,
    deltaTime: Float = 1f / 20f // For 20 ticks per second
): Float {
    val smoothTime = smoothTime.coerceAtLeast(0.0001f)
    val omega = 2f / smoothTime

    val x = omega * deltaTime
    val exp = 1f / (1f + x + 0.48f * x * x + 0.235f * x * x * x)
    var change = current - target

    // Clamp maximum speed
    val maxChange = maxSpeed * smoothTime
    change = change.coerceIn(-maxChange, maxChange)
    val targetTemp = current - change

    val temp = (currentVelocity.value + omega * change) * deltaTime
    currentVelocity.value = (currentVelocity.value - omega * temp) * exp
    var output = targetTemp + (change + temp) * exp

    // Prevent overshooting
    if (target - current > 0f == output > target) {
        output = target
        currentVelocity.value = (output - target) / deltaTime
    }

    return output
}

fun getLookYaw(dx: Double, dz: Double): Float {
    val radians = atan2(dz, dx)
    val degrees = Math.toDegrees(radians).toFloat() - 90
    if (degrees < -180) return degrees + 360
    if (degrees > 180) return degrees - 360
    return degrees
}

fun getLookPitch(dx: Double, dy: Double, dz: Double): Float {
    val radians = -atan2(dy, max(abs(dx), abs(dz)))
    return Math.toDegrees(radians).toFloat()
}