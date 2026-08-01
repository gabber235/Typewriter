package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.EntityInstanceEntry
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import org.bukkit.entity.Player

interface ActivityCreator {
    fun create(context: ActivityContext, currentLocation: PositionProperty): EntityActivity<ActivityContext>
}

interface EntityActivity<Context : ActivityContext> {
    /**
     * Start running at [position].
     *
     * Called for the first activation and for every resume after a [deactivate]. The activity must
     * adopt [position]; it may differ from wherever the activity left off.
     */
    fun activate(context: Context, position: PositionProperty)

    fun tick(context: Context): TickResult

    /**
     * Stop running but keep progress. Cancel jobs, release listeners, drop temporary resources.
     *
     * The activity may be activated again afterwards.
     */
    fun deactivate(context: Context) {}

    /**
     * Final teardown. Never activated again.
     *
     * Takes no context because [deactivate] always runs first, so anything that touches viewers
     * belongs there.
     */
    fun dispose() {}

    val currentPosition: PositionProperty
    val currentProperties: List<EntityProperty> get() = listOf(currentPosition)
}

/**
 * Indicates what the result of the tick is.
 *
 * Some activities may want to do fallback actions if the tick is ignored.
 */
enum class TickResult {
    // The activity is done and everything is fine.
    CONSUMED,

    // The activity got ignored and did not activate.
    IGNORED,
}

interface SharedEntityActivity : EntityActivity<SharedActivityContext> {
    fun addedViewer(context: SharedActivityContext, viewer: Player) {}
    fun removedViewer(context: SharedActivityContext, viewer: Player) {}
}

interface IndividualEntityActivity : EntityActivity<IndividualActivityContext>
interface GenericEntityActivity : EntityActivity<ActivityContext>

class IdleActivity(override var currentPosition: PositionProperty) : GenericEntityActivity {
    override fun activate(context: ActivityContext, position: PositionProperty) {
        currentPosition = position
    }

    override fun tick(context: ActivityContext): TickResult = TickResult.IGNORED

    companion object : ActivityCreator {
        override fun create(
            context: ActivityContext,
            currentLocation: PositionProperty
        ): EntityActivity<in ActivityContext> = IdleActivity(currentLocation)
    }
}

abstract class SingleChildActivity<Context : ActivityContext>(
    startPosition: PositionProperty,
) : EntityActivity<Context> {
    private val children = entryActivityHolder<Context>(startPosition)

    protected val child: Ref<out EntityActivityEntry>?
        get() = children.currentKey

    override fun activate(context: Context, position: PositionProperty) {
        children.activate(currentChild(context), context, position)
    }

    override fun tick(context: Context): TickResult {
        children.switchTo(currentChild(context), context, children.currentPosition)
        return children.tick(context)
    }

    override fun deactivate(context: Context) = children.deactivate(context)

    override fun dispose() = children.dispose()

    override val currentPosition: PositionProperty
        get() = children.currentPosition

    override val currentProperties: List<EntityProperty>
        get() = children.currentProperties

    abstract fun currentChild(context: Context): Ref<out EntityActivityEntry>
}

interface ActivityContext {
    val instanceRef: Ref<out EntityInstanceEntry>
    val isViewed: Boolean

    val viewers: List<Player>
    val entityState: EntityState

    val randomViewer: Player?
        get() = viewers.randomOrNull()
}

class SharedActivityContext(
    override val instanceRef: Ref<out EntityInstanceEntry>,
    override val viewers: List<Player>,
    override val entityState: EntityState = EntityState(),
) : ActivityContext {
    override val isViewed: Boolean
        get() = viewers.isNotEmpty()
}

class IndividualActivityContext(
    override val instanceRef: Ref<out EntityInstanceEntry>,
    val viewer: Player,
    override val isViewed: Boolean = false,
    override val entityState: EntityState = EntityState(),
) : ActivityContext {
    override val viewers: List<Player>
        get() = listOf(viewer)
}