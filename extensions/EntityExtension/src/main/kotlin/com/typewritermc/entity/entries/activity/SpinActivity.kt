package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.*
import java.time.Duration
import java.time.Instant
import kotlin.math.sin

enum class SpinAxis {
    YAW, PITCH
}

@Entry("spin_activity", "A spinning activity", Colors.BLUE, "fa6-solid:rotate")
/**
 * The `SpinActivity` makes the entity rotate around its axis.
 *
 * ## How could this be used?
 * This could be used to show off a cosmetic on the player.
 */
class SpinActivityEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The duration of one full rotation")
    val duration: Var<Duration> = ConstVar(Duration.ofSeconds(2)),
    @Default("true")
    val clockwise: Boolean = true,
    val axis: SpinAxis = SpinAxis.YAW,
    @Help("The activity that supplies the base position")
    val childActivity: Ref<out EntityActivityEntry> = emptyRef()
) : GenericEntityActivityEntry {
    override fun create(context: ActivityContext, currentLocation: PositionProperty): EntityActivity<ActivityContext> {
        val activity = childActivity.get() ?: IdleActivity
        return SpinActivity(duration, clockwise, axis, activity.create(context, currentLocation))
    }
}

class SpinActivity(
    private val duration: Var<Duration>,
    clockwise: Boolean,
    private val axis: SpinAxis,
    private val childActivity: EntityActivity<ActivityContext>,
) : EntityActivity<ActivityContext> {
    private var startTime = Instant.now()
    private var startRotation = 0f
    private val direction = if (clockwise) -1 else 1
    private var currentRotation = 0f

    override fun initialize(context: ActivityContext) {
        startTime = Instant.now()
        startRotation = when (axis) {
            SpinAxis.YAW -> childActivity.currentPosition.yaw
            SpinAxis.PITCH -> childActivity.currentPosition.pitch
        }
        currentRotation = startRotation
        childActivity.initialize(context)
    }

    override fun tick(context: ActivityContext): TickResult {
        val rotationDuration = context.randomViewer?.let { viewer -> duration.get(viewer) }
            ?: Duration.ofSeconds(2)

        val elapsed = Duration.between(startTime, Instant.now())
        val progress = (elapsed.toMillis() % rotationDuration.toMillis()) / rotationDuration.toMillis().toFloat()
        val angle = progress * 360 * direction

        currentRotation = when (axis) {
            SpinAxis.YAW -> {
                ((angle + 180) % 360 + 360) % 360 - 180
            }

            SpinAxis.PITCH -> {
                val radians = Math.toRadians(angle.toDouble())
                90f * sin(radians).toFloat()
            }
        }

        return childActivity.tick(context)
    }

    override fun dispose(context: ActivityContext) {
        childActivity.dispose(context)
    }

    override val currentPosition: PositionProperty
        get() = when (axis) {
            SpinAxis.YAW -> childActivity.currentPosition.copy(yaw = currentRotation)
            SpinAxis.PITCH -> childActivity.currentPosition.copy(pitch = currentRotation)
        }

    override val currentProperties: List<EntityProperty>
        get() = childActivity.currentProperties.filter { it !is PositionProperty } + currentPosition
}