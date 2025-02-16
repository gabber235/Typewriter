package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.Var
import java.time.Duration
import java.time.Instant
import kotlin.random.Random

@Entry("random_look_activity", "A random look activity", Colors.BLUE, "fa6-solid:eye")
/**
 * The `Random Look Activity` is used to make the entity look in random directions.
 *
 * ## How could this be used?
 * This could be used to make the entity look distracted.
 */
class RandomLookActivityEntry(
    override val id: String = "",
    override val name: String = "",
    @Default("{\"start\": -90.0, \"end\": 90.0}")
    val pitchRange: ClosedRange<Float> = -90f..90f,
    @Default("{\"start\": -180.0, \"end\": 180.0}")
    val yawRange: ClosedRange<Float> = -180f..180f,
    @Help("The duration between each look")
    val duration: Var<Duration> = ConstVar(Duration.ofSeconds(1)),
) : GenericEntityActivityEntry {
    override fun create(context: ActivityContext, currentLocation: PositionProperty): EntityActivity<ActivityContext> {
        return RandomLookActivity(pitchRange, yawRange, duration, currentLocation)
    }
}

class RandomLookActivity(
    private val pitchRange: ClosedRange<Float>,
    private val yawRange: ClosedRange<Float>,
    private val duration: Var<Duration>,
    override var currentPosition: PositionProperty,
) : GenericEntityActivity {
    private var targetPitch: Float = pitchRange.random()
    private var targetYaw: Float = yawRange.random()
    private val pitchVelocity = Velocity(0f)
    private val yawVelocity = Velocity(0f)
    private var nextChangeTime = Instant.now()


    override fun initialize(context: ActivityContext) {}

    override fun tick(context: ActivityContext): TickResult {
        val currentTime = Instant.now()
        if (currentTime > nextChangeTime) {
            targetPitch = pitchRange.random()
            targetYaw = yawRange.random()
            val duration = context.randomViewer?.let { viewer -> this.duration.get(viewer) } ?: Duration.ofSeconds(1)
            nextChangeTime = currentTime + duration
        }


        val (yaw, pitch) = updateLookDirection(
            LookDirection(currentPosition.yaw, currentPosition.pitch),
            LookDirection(targetYaw, targetPitch),
            yawVelocity,
            pitchVelocity,
            smoothTime = 0.5f,
        )

        currentPosition =
            PositionProperty(currentPosition.world, currentPosition.x, currentPosition.y, currentPosition.z, yaw, pitch)

        return TickResult.CONSUMED
    }

    override fun dispose(context: ActivityContext) {}
}

fun ClosedRange<Float>.random(): Float {
    return start + (endInclusive - start) * Random.nextFloat()
}