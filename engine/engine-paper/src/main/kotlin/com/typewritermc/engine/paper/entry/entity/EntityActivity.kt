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
    fun initialize(context: Context)
    fun tick(context: Context): TickResult
    fun dispose(context: Context)

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

interface SharedEntityActivity : EntityActivity<SharedActivityContext>
interface IndividualEntityActivity : EntityActivity<IndividualActivityContext>
interface GenericEntityActivity : EntityActivity<ActivityContext>

class IdleActivity(override var currentPosition: PositionProperty) : GenericEntityActivity {
    override fun initialize(context: ActivityContext) {}

    override fun tick(context: ActivityContext): TickResult = TickResult.IGNORED

    override fun dispose(context: ActivityContext) {}

    companion object : ActivityCreator {
        override fun create(context: ActivityContext, currentLocation: PositionProperty): EntityActivity<in ActivityContext> = IdleActivity(currentLocation)
    }
}

abstract class SingleChildActivity<Context : ActivityContext>(
    private val startLocation: PositionProperty,
) : EntityActivity<Context> {
    private var child: Ref<out EntityActivityEntry> = emptyRef()
    private var currentActivity: EntityActivity<in Context>? = null

    override fun initialize(context: Context) {
        child = currentChild(context)
        currentActivity = child.get()?.create(context, currentPosition)
        currentActivity?.initialize(context)
    }

    override fun tick(context: Context): TickResult {
        val correctChild = currentChild(context)
        if (child != correctChild) {
            child = correctChild
            val currentLocation = this.currentPosition
            currentActivity?.dispose(context)
            currentActivity = child.get()?.create(context, currentLocation)
            currentActivity?.initialize(context)
        }
        return currentActivity?.tick(context) ?: TickResult.IGNORED
    }

    override fun dispose(context: Context) {
        currentActivity?.dispose(context)
        currentActivity = null
        child = emptyRef()
    }

    override val currentPosition: PositionProperty
        get() = currentActivity?.currentPosition ?: startLocation

    override val currentProperties: List<EntityProperty>
        get() = currentActivity?.currentProperties ?: emptyList()

    abstract fun currentChild(context: Context): Ref<out EntityActivityEntry>
}

sealed interface ActivityContext {
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