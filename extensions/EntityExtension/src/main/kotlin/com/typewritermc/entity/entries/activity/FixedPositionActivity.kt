package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry

@Entry("fixed_position_activity", "A fixed position activity", Colors.BLUE, "mdi:map-marker-account")
/**
 * The `FixedPositionActivityEntry` pins the entity to a specific position.
 *
 * The entity is placed at the target position immediately, and stays there for as long as the
 * activity is active.
 *
 * ## How could this be used?
 * This could be used to make an entity appear at a specific location instantly.
 */
class FixedPositionActivityEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The position the entity will be placed at.")
    val targetPosition: Position = Position.ORIGIN,
    @Help("The activity that will be used when the entity is at the target position.")
    val child: Ref<out EntityActivityEntry> = emptyRef(),
) : GenericEntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<in ActivityContext> {
        return FixedPositionActivity(targetPosition.toProperty(), child)
    }
}

class FixedPositionActivity(
    private val targetPosition: PositionProperty,
    private val child: Ref<out EntityActivityEntry>
) : GenericEntityActivity {
    private val children = entryActivityHolder<ActivityContext>(targetPosition)

    override fun activate(context: ActivityContext, position: PositionProperty) = children.activate(child, context, targetPosition)

    override fun tick(context: ActivityContext): TickResult = children.tick(context)

    override fun deactivate(context: ActivityContext) = children.deactivate(context)

    override fun dispose() = children.dispose()

    override val currentPosition: PositionProperty
        get() = children.currentPosition

    override val currentProperties: List<EntityProperty>
        get() = children.currentProperties
}
