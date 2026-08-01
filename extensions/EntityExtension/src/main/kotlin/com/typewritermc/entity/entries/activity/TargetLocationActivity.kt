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
    private val once: Boolean,
    startPosition: PositionProperty,
) : GenericEntityActivity {
    private enum class Mode { NAVIGATING, IDLE }

    private var searchStart: PositionProperty = startPosition
    private var reachedTarget = false

    private val children = ChildActivityHolder<Mode, ActivityContext>(startPosition) { mode, context, position ->
        when (mode) {
            Mode.NAVIGATING -> NavigationActivity(
                PointToPointGPS(
                    network,
                    {
                        val start = searchStart.toPosition()
                        start.firstWalkableLocationBelow() ?: start
                    },
                    { targetPosition },
                ),
                position,
            )

            Mode.IDLE -> idleActivity.get()?.create(context, position)
        }
    }

    override fun activate(context: ActivityContext, position: PositionProperty) {
        enter(modeFor(position), context, position)
    }

    override fun tick(context: ActivityContext): TickResult {
        val position = currentPosition
        val mode = modeFor(position)
        if (mode != children.currentKey) enter(mode, context, position)

        return children.tick(context)
    }

    override fun deactivate(context: ActivityContext) = children.deactivate(context)

    override fun dispose() = children.dispose()

    override val currentPosition: PositionProperty
        get() = children.currentPosition

    override val currentProperties: List<EntityProperty>
        get() = children.currentProperties

    private fun modeFor(position: PositionProperty): Mode {
        if (once && reachedTarget) return Mode.IDLE
        // Another world gives no distance, so keep doing whatever we were already doing.
        val distance = position.distanceSquared(targetPosition) ?: return children.currentKey ?: Mode.NAVIGATING
        if (distance <= locationActivityRange * locationActivityRange) return Mode.IDLE
        return Mode.NAVIGATING
    }

    private fun enter(mode: Mode, context: ActivityContext, position: PositionProperty) {
        if (mode == Mode.IDLE) reachedTarget = true
        searchStart = position
        children.activate(mode, context, position)
    }
}