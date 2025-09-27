package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.engine.paper.interaction.interactionContext
import com.typewritermc.engine.paper.utils.Sound
import java.time.Duration
import kotlin.math.max
import kotlin.random.Random


@Entry(
    "ambient_sound_activity",
    "Play an ambient sound for an entity",
    Colors.PALATINATE_BLUE,
    "mingcute:shuffle-2-fill"
)
/**
 * The `AmbientSoundActivityEntry` is an activity that plays an ambient sound for an entity.
 *
 * ## How could this be used?
 * This can be used to make an entity sound like it is doing something.
 * Like playing a sound when it is building a structure.
 * Or having it mumble to itself.
 */
class AmbientSoundActivityEntry(
    override val id: String = "",
    override val name: String = "",
    val sounds: List<AmbientSound> = emptyList(),
    @Help("How long to wait before playing the next sound")
    @Default("{\"start\": 2000, \"end\": 5000}")
    val delay: ClosedRange<Duration> = Duration.ZERO..Duration.ZERO,
    val activity: Ref<out EntityActivityEntry> = emptyRef(),
) : GenericEntityActivityEntry {
    override fun create(context: ActivityContext, currentLocation: PositionProperty): EntityActivity<ActivityContext> {
        return AmbientSoundActivity(sounds, delay, activity, currentLocation)
    }
}

data class AmbientSound(
    val sound: Sound = Sound.EMPTY,
    @Default("1.0")
    val weight: Double = 1.0,
)

class AmbientSoundActivity(
    private val sounds: List<AmbientSound>,
    private val delay: ClosedRange<Duration>,
    private val activity: Ref<out EntityActivityEntry>,
    startLocation: PositionProperty,
) : SingleChildActivity<ActivityContext>(startLocation) {
    private var nextPlay = System.currentTimeMillis() + delay.random().toMillis()

    override fun currentChild(context: ActivityContext): Ref<out EntityActivityEntry> = activity

    override fun tick(context: ActivityContext): TickResult {
        if (System.currentTimeMillis() >= nextPlay) {
            nextPlay = System.currentTimeMillis() + delay.random().toMillis()
            val sound = sounds.weightedRandom().sound
            context.viewers.forEach { viewer ->
                sound.play(viewer, viewer.interactionContext)
            }
        }
        return super.tick(context)
    }
}

fun ClosedRange<Duration>.random(): Duration {
    val start = start.toMillis()
    val end = endInclusive.toMillis()
    return Duration.ofMillis(start + Random.nextLong(end - start))
}

fun List<AmbientSound>.weightedRandom(): AmbientSound {
    if (isEmpty()) return AmbientSound(Sound.EMPTY)
    if (size == 1) return this[0]

    val discreteCumulativeWeights = this.scan(0.0) { acc, sound -> acc + max(sound.weight, 1.0) }.toList().drop(1)
    val random = Random.nextDouble() * discreteCumulativeWeights.last()
    return this.zip(discreteCumulativeWeights).first { (_, cumulativeWeight) ->
        cumulativeWeight > random
    }.first
}