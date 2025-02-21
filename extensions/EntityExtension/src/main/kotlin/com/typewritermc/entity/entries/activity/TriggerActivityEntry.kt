package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.engine.paper.entry.triggerFor

@Entry("trigger_activity", "Triggers a sequence when the activity active or inactive", Colors.PALATINATE_BLUE, "fa-solid:play")
/**
 * The `Trigger Activity` entry is an activity that triggers a sequence when the activity starts or stops.
 *
 * ## How could this be used?
 * This could be used to trigger dialogue when the entity arrives at a certain location.
 * Like a tour guide that triggers dialogue when the entity arrives at a point of interest.
 */
class TriggerActivityEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The activity to use when this is active.")
    val activity: Ref<out EntityActivityEntry> = emptyRef(),
    @Help("The sequence to trigger when the activity starts.")
    val onStart: Ref<TriggerableEntry> = emptyRef(),
    @Help("The sequence to trigger when the activity stops.")
    val onStop: Ref<TriggerableEntry> = emptyRef(),
) : GenericEntityActivityEntry {
    override fun create(context: ActivityContext, currentLocation: PositionProperty): EntityActivity<ActivityContext> {
        if (!activity.isSet) return IdleActivity.create(context, currentLocation)
        return TriggerActivity(activity, currentLocation, onStart, onStop)
    }
}

private class TriggerActivity(
    private val ref: Ref<out EntityActivityEntry>,
    startLocation: PositionProperty,
    private val onStart: Ref<TriggerableEntry>,
    private val onStop: Ref<TriggerableEntry>,
) : GenericEntityActivity {
    private var activity: EntityActivity<in ActivityContext> = IdleActivity(startLocation)

    override fun initialize(context: ActivityContext) {
        activity = ref.get()?.create(context, currentPosition) ?: IdleActivity(currentPosition)
        activity.initialize(context)
        context.viewers.forEach {
            onStart.triggerFor(it, context())
        }
    }

    override fun tick(context: ActivityContext): TickResult {
        return activity.tick(context)
    }

    override fun dispose(context: ActivityContext) {
        context.viewers.forEach {
            onStop.triggerFor(it, context())
        }
        activity.dispose(context)
    }

    override val currentPosition: PositionProperty
        get() = activity.currentPosition
}