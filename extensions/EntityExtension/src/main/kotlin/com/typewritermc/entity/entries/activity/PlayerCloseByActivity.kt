package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.distanceSqrt
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.utils.isLookable
import java.time.Duration
import java.time.Instant
import java.util.*

@Entry(
    "player_close_by_activity",
    "A player close by activity",
    Colors.PALATINATE_BLUE,
    "material-symbols-light:frame-person"
)
/**
 * The `PlayerCloseByActivityEntry` is an activity that activates child activities when a viewer is close by.
 *
 * The activity will only activate when the viewer is within the defined range.
 * If the activationRange is set, the activity will only activate when the viewer enters this smaller range after it has been deactivated.
 *
 * When the maximum idle duration is reached, the activity will deactivate.
 * If the maximum idle duration is set to 0, then it won't use the timer.
 *
 * ## How could this be used?
 * When the player has to follow the NPC and walks away, let the NPC wander around (or stand still) around the point the player walked away. When the player returns, resume its path.
 *
 * If the activationRange is set, it can prevent the entity from repeatedly activating and deactivating when the player is at the edge of the range, or allow the player to get closer to the npc before it starts walking again.
 *
 * When the npc is walking, and a player comes in range Stand still.
 */
class PlayerCloseByActivityEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The range in which the player has to be close by to activate the activity.")
    @Default("10.0")
    val range: Double = 10.0,
    @Help("Optional range in which the player has to enter to activate the activity. Must be smaller than the main range.")
    val activationRange: Optional<Double> = Optional.empty(),
    @Help("The maximum duration a player can be idle in the same range before the activity deactivates.")
    @Default("30000")
    val maxIdleDuration: Duration = Duration.ofSeconds(30),
    @Help("The activity that will be used when there is a player close by.")
    val closeByActivity: Ref<out EntityActivityEntry> = emptyRef(),
    @Help("The activity that will be used when there is no player close by.")
    val idleActivity: Ref<out EntityActivityEntry> = emptyRef(),
) : GenericEntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<in ActivityContext> {
        val effectiveActivationRange = activationRange.map {
            if (it >= range) {
                logger.warning("The activation range must be smaller than the main range.")
                range
            } else {
                it
            }
        }.orElse(range)

        return PlayerCloseByActivity(
            range,
            effectiveActivationRange,
            maxIdleDuration,
            closeByActivity,
            idleActivity,
            currentLocation
        )
    }
}

class PlayerCloseByActivity(
    private val deactivationRange: Double,
    private val activationRange: Double,
    private val maxIdleDuration: Duration,
    private val closeByActivity: Ref<out EntityActivityEntry>,
    private val idleActivity: Ref<out EntityActivityEntry>,
    startLocation: PositionProperty,
) : SingleChildActivity<ActivityContext>(startLocation) {
    private var trackers = mutableMapOf<UUID, PlayerLocationTracker>()

    override fun currentChild(context: ActivityContext): Ref<out EntityActivityEntry> {
        val closeByPlayers = context.viewers
            .filter { it.isLookable }
            .filter {
                (it.location.toProperty().distanceSqrt(currentPosition)
                    ?: Double.MAX_VALUE) < deactivationRange * deactivationRange
            }

        trackers.keys.removeAll { uuid -> closeByPlayers.none { it.uniqueId == uuid } }

        closeByPlayers.forEach { player ->
            trackers.computeIfAbsent(player.uniqueId) {
                PlayerLocationTracker(
                    player.location.toProperty()
                )
            }
                .update(player.location.toProperty())
                .updateActivated(currentPosition, activationRange)
        }

        val isActive = trackers.any { it.value.isActive(maxIdleDuration) }

        return if (isActive) {
            closeByActivity
        } else {
            idleActivity
        }
    }

    private class PlayerLocationTracker(
        var location: PositionProperty,
        var lastSeen: Instant = Instant.now(),
        var activated: Boolean = false,
    ) {
        fun update(location: PositionProperty): PlayerLocationTracker {
            if ((this.location.distanceSqrt(location) ?: Double.MAX_VALUE) < 0.1) return this
            this.location = location
            lastSeen = Instant.now()
            return this
        }

        fun updateActivated(
            entityPosition: PositionProperty,
            activationRange: Double,
        ): PlayerLocationTracker {
            val distanceSq = location.distanceSqrt(entityPosition) ?: Double.MAX_VALUE
            if (!activated && distanceSq < activationRange * activationRange) {
                activated = true
            }
            return this
        }

        private fun isTimedOut(maxIdleDuration: Duration): Boolean {
            if (maxIdleDuration.isZero) return false
            return Duration.between(lastSeen, Instant.now()) > maxIdleDuration
        }

        fun isActive(
            maxIdleDuration: Duration
        ): Boolean {
            if (isTimedOut(maxIdleDuration)) return false
            return activated
        }
    }
}