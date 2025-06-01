package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.*

@Entry(
    "offset_activity",
    "Applies a constant offset to the entity's position.",
    Colors.PALATINATE_BLUE,
    "fa6-solid:arrows-up-down-left-right"
)
/**
 * Applies a constant offset to an entity's position.
 *
 * This activity is useful for:
 * - Adjusting the position of entities relative to their base position
 *
 * You can specify the offset as a Vector with x, y, and z components.
 * It can be combined with other movement activities by setting the childActivity.
 */
class OffsetActivityEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The offset to apply to the entity's position.")
    @Default(Vector.ZERO_JSON)
    val offset: Var<Vector> = ConstVar(Vector.ZERO),
    @Help("The activity that supplies the base position. If not set, the entity will be offset from its initial position.")
    val childActivity: Ref<out EntityActivityEntry> = emptyRef()
) : GenericEntityActivityEntry {
    override fun create(context: ActivityContext, currentLocation: PositionProperty): EntityActivity<ActivityContext> {
        val baseActivity = childActivity.get()?.create(context, currentLocation) ?: IdleActivity(currentLocation)
        return OffsetActivity(
            offset = offset,
            childActivity = baseActivity
        )
    }
}

class OffsetActivity(
    private val offset: Var<Vector>,
    private val childActivity: EntityActivity<ActivityContext>
) : EntityActivity<ActivityContext> {
    private var lastOffset: Vector = Vector.ZERO
    override fun initialize(context: ActivityContext) {
        childActivity.initialize(context)
        lastOffset = context.randomViewer?.let { offset.get(it) } ?: Vector.ZERO
    }

    override fun tick(context: ActivityContext): TickResult {
        if (offset !is ConstVar) {
            lastOffset = context.randomViewer?.let { offset.get(it) } ?: Vector.ZERO
        }
        return childActivity.tick(context)
    }

    override fun dispose(context: ActivityContext) {
        childActivity.dispose(context)
    }

    override val currentPosition: PositionProperty
        get() = childActivity.currentPosition + lastOffset

    override val currentProperties: List<EntityProperty>
        get() = childActivity.currentProperties.filter { it !is PositionProperty } + currentPosition
}