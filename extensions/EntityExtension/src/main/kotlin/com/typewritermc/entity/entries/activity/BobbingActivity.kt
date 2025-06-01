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

@Entry(
    "bobbing_activity",
    "Makes the entity bob up and down, like a floating item.",
    Colors.BLUE,
    "fa6-solid:arrows-up-down"
)
/**
 * Makes an entity gently bob up and down, creating a floating effect.
 *
 * This activity is perfect for:
 * - Making entities other than dropped items appear more dynamic like the dropped items.
 * - Giving decorative entities a subtle animation to make them feel more alive.
 * - Creating a visual cue for interactive objects, like a quest item that pulses slightly.
 *
 * You can control how fast the entity bobs and the amplitude of its motion.
 * It can also be combined with other movement activities. For example,
 * you could have an entity patrol along a path while also bobbing.
 */
class BobbingActivityEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The speed of the bobbing motion in cycles per second. Higher values mean faster bobbing.")
    @Default("1.0")
    val speed: Var<Float> = ConstVar(1.0f),
    @Help("The amplitude of the bobbing motion in blocks. For example, an amplitude of 0.5 means it will move 0.25 blocks up and 0.25 blocks down from its starting point.")
    @Default("0.5")
    val amplitude: Var<Float> = ConstVar(0.5f),
    @Help("The activity that supplies the base position. If not set, the entity will bob in place around its initial position.")
    val childActivity: Ref<out EntityActivityEntry> = emptyRef()
) : GenericEntityActivityEntry {
    override fun create(context: ActivityContext, currentLocation: PositionProperty): EntityActivity<ActivityContext> {
        val baseActivity = childActivity.get()?.create(context, currentLocation) ?: IdleActivity(currentLocation)
        return BobbingActivity(
            speed = speed,
            amplitude = amplitude,
            childActivity = baseActivity
        )
    }
}

class BobbingActivity(
    private val speed: Var<Float>,
    private val amplitude: Var<Float>,
    private val childActivity: EntityActivity<ActivityContext>
) : EntityActivity<ActivityContext> {
    private var startTime: Instant = Instant.now()
    private var lastOffset: Float = 0.0f

    override fun initialize(context: ActivityContext) {
        startTime = Instant.now()
        childActivity.initialize(context)
    }

    override fun tick(context: ActivityContext): TickResult {
        val currentSpeed = context.randomViewer?.let { speed.get(it) } ?: 1.0f
        val currentAmplitude = context.randomViewer?.let { amplitude.get(it) } ?: 0.5f

        val elapsedSeconds = Duration.between(startTime, Instant.now()).toMillis() / 1000.0f
        lastOffset = sin(elapsedSeconds * currentSpeed * 2 * Math.PI).toFloat() * currentAmplitude

        return childActivity.tick(context)
    }

    override fun dispose(context: ActivityContext) {
        childActivity.dispose(context)
    }

    override val currentPosition: PositionProperty
        get() = childActivity.currentPosition.withY { it + lastOffset }

    override val currentProperties: List<EntityProperty>
        get() = childActivity.currentProperties.filter { it !is PositionProperty } + currentPosition
}