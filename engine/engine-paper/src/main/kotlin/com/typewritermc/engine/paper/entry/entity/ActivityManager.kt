package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.engine.paper.entry.entries.EntityProperty
import org.bukkit.entity.Player

class ActivityManager<Context : ActivityContext>(
    private val activity: EntityActivity<in Context>,
) {
    val position: PositionProperty
        get() = activity.currentPosition

    val activeProperties: List<EntityProperty>
        get() = activity.currentProperties

    fun initialize(context: Context) {
        activity.initialize(context)
    }

    fun tick(context: Context) {
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
        activity.dispose(context)
    }
}