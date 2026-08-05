package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.logger
import org.bukkit.entity.Player

class ActivityManager<Context : ActivityContext>(
    private val activity: EntityActivity<in Context>,
    private val reportViolation: (String) -> Unit = { logger.severe(it) },
) {
    private enum class State { CREATED, ACTIVE, DISPOSED }

    private var state = State.CREATED
    private var reportedTickViolation = false

    val position: PositionProperty
        get() = activity.currentPosition

    val activeProperties: List<EntityProperty>
        get() = activity.currentProperties

    fun initialize(context: Context) {
        check(state == State.CREATED) { "An activity manager can only be initialized once, this one is $state" }
        activity.activate(context, position)
        state = State.ACTIVE
    }

    fun tick(context: Context) {
        if (state != State.ACTIVE) {
            if (reportedTickViolation) return
            reportedTickViolation = true
            reportViolation("Ticked an activity manager that is $state. This is a Typewriter bug, please report it.")
            return
        }
        activity.tick(context)
    }

    fun addedViewer(context: SharedActivityContext, viewer: Player) {
        when (activity) {
            is SharedEntityActivity -> activity.addedViewer(context, viewer)
        }
    }

    fun removedViewer(context: SharedActivityContext, viewer: Player) {
        when (activity) {
            is SharedEntityActivity -> activity.removedViewer(context, viewer)
        }
    }

    fun dispose(context: Context) {
        if (state == State.DISPOSED) return
        if (state == State.ACTIVE) activity.deactivate(context)
        activity.dispose()
        state = State.DISPOSED
    }
}
