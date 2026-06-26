package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.distanceSquared
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.firstWalkableLocationBelow
import com.typewritermc.roadnetwork.RoadNetworkEntry
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
    @Help("If true, the activity will only activate once. Once the entity reaches the target location, it will not trigger again and defer to idle activity.")
    val once: Boolean = false,
) : GenericEntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<in ActivityContext> {
        return TargetLocationActivity(roadNetwork, targetLocation, idleActivity, once, currentLocation)
    }
}

class TargetLocationActivity(
    private val network: Ref<RoadNetworkEntry>,
    private val targetPosition: Position,
    private val idleActivity: Ref<out EntityActivityEntry>,
    val once: Boolean,
    startPosition: PositionProperty,
) : GenericEntityActivity {
    private val states = listOf(NavigatingState(), IdleState())
    private var state: State = states.first()
    private var currentActivity: EntityActivity<ActivityContext> = IdleActivity(startPosition)


    private interface State {
        val isValid: Boolean
        fun nextState(): State
        fun createActivity(
            context: ActivityContext,
            currentPosition: PositionProperty
        ): EntityActivity<ActivityContext>
    }

    private inner class IdleState : State {
        override val isValid: Boolean
            get() {
                if (once) return true
                val distance = currentPosition.distanceSquared(targetPosition) ?: return true
                return distance <= locationActivityRange * locationActivityRange
            }

        private var cachedActivity: EntityActivity<ActivityContext>? = null

        override fun nextState(): State = states[0]

        override fun createActivity(
            context: ActivityContext,
            currentPosition: PositionProperty
        ): EntityActivity<ActivityContext> {
            if (cachedActivity != null) return cachedActivity!!
            cachedActivity = (idleActivity.get() ?: IdleActivity).create(context, currentPosition)
            return cachedActivity!!
        }
    }

    private inner class NavigatingState : State {
        override val isValid: Boolean
            get() {
                val distance = currentPosition.distanceSquared(targetPosition) ?: return true
                return distance > locationActivityRange * locationActivityRange
            }

        override fun nextState(): State = states[1]

        override fun createActivity(
            context: ActivityContext,
            currentPosition: PositionProperty
        ): EntityActivity<ActivityContext> {
            return NavigationActivity(
                PointToPointGPS(
                    network,
                    {
                        val position = currentPosition.toPosition()
                        position.firstWalkableLocationBelow() ?: position
                    },
                    { targetPosition }
                ), currentPosition)
        }
    }

    override fun initialize(context: ActivityContext, position: PositionProperty) {
        if (!state.isValid) {
            state = state.nextState()
        }

        currentActivity = state.createActivity(context, position).also {
            it.initialize(context, position)
        }
    }

    override fun tick(context: ActivityContext): TickResult {
        if (!state.isValid) {
            currentActivity.dispose(context)
            state = state.nextState()
            currentActivity = state.createActivity(context, currentPosition)
            currentActivity.initialize(context, currentPosition)
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