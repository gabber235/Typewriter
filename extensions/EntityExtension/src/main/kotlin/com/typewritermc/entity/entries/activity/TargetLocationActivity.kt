package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.distanceSqrt
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.toBukkitLocation
import com.typewritermc.roadnetwork.gps.PointToPointGPS

private val locationActivityRange by snippet("entity.activity.target_location.range", 1.0)

@Entry("target_location_activity", "A location activity", Colors.BLUE, "mdi:map-marker-account")
/**
 * The `TargetLocationActivityEntry` is an activity that makes the entity navigate to a specific location.
 *
 * The activity will only activate when the entity is outside a certain range.
 *
 * ## How could this be used?
 * This could be used to make an entity navigate to a specific location.
 */
class TargetLocationActivityEntry(
    override val id: String = "",
    override val name: String = "",
    val roadNetwork: Ref<RoadNetworkEntry> = emptyRef(),
    val targetLocation: Position = Position.ORIGIN,
    @Help("The activity that will be used when the entity is at the target location.")
    val idleActivity: Ref<out EntityActivityEntry> = emptyRef(),
) : GenericEntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<in ActivityContext> {
        return TargetLocationActivity(roadNetwork, targetLocation, idleActivity, currentLocation)
    }
}

class TargetLocationActivity(
    private val network: Ref<RoadNetworkEntry>,
    private val targetPosition: Position,
    private val idleActivity: Ref<out EntityActivityEntry>,
    startPosition: PositionProperty,
) : GenericEntityActivity {
    private var state: State = IdleState()
    private var currentActivity: EntityActivity<ActivityContext> = IdleActivity(startPosition)


    private interface State {
        val isValid: Boolean
        fun nextState(): State
        fun createActivity(
            context: ActivityContext,
            currentLocation: PositionProperty
        ): EntityActivity<ActivityContext>
    }

    private inner class IdleState : State {
        override val isValid: Boolean
            get() {
                val distance = currentPosition.distanceSqrt(targetPosition) ?: return false
                return distance <= locationActivityRange * locationActivityRange
            }

        override fun nextState(): State = NavigatingState()

        override fun createActivity(
            context: ActivityContext,
            currentLocation: PositionProperty
        ): EntityActivity<ActivityContext> {
            return (idleActivity.get() ?: IdleActivity).create(context, currentLocation)
        }
    }

    private inner class NavigatingState : State {
        override val isValid: Boolean
            get() {
                val distance = currentPosition.distanceSqrt(targetPosition) ?: return true
                return distance > locationActivityRange * locationActivityRange
            }

        override fun nextState(): State = IdleState()

        override fun createActivity(
            context: ActivityContext,
            currentLocation: PositionProperty
        ): EntityActivity<ActivityContext> {
            return NavigationActivity(
                PointToPointGPS(
                network,
                { currentLocation.toBukkitLocation() },
                { targetPosition.toBukkitLocation() }
            ), currentLocation)
        }
    }

    override fun initialize(context: ActivityContext) {
        if (!state.isValid) {
            state = state.nextState()
        }

        currentActivity = state.createActivity(context, currentPosition)
        currentActivity.initialize(context)
    }

    override fun tick(context: ActivityContext): TickResult {
        if (!state.isValid) {
            currentActivity.dispose(context)
            state = state.nextState()
            currentActivity = state.createActivity(context, currentPosition)
            currentActivity.initialize(context)
        }

        return currentActivity.tick(context)
    }

    override fun dispose(context: ActivityContext) {
        val oldPosition = currentPosition
        currentActivity.dispose(context)
        currentActivity = IdleActivity(oldPosition)
    }

    override val currentPosition: PositionProperty
        get() = currentActivity.currentPosition

    override val currentProperties: List<EntityProperty>
        get() = currentActivity.currentProperties
}