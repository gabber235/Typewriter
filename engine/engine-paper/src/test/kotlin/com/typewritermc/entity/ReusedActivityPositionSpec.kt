package com.typewritermc.entity

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.EntityInstanceEntry
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import org.bukkit.entity.Player

private val world = World("reused-activity-world")

private fun positionAt(x: Double, y: Double, z: Double) = PositionProperty(world, x, y, z, 0f, 0f)

private class StubContext : ActivityContext {
    override val instanceRef: Ref<out EntityInstanceEntry> = emptyRef()
    override val isViewed: Boolean = false
    override val viewers: List<Player> = emptyList()
    override val entityState: EntityState = EntityState()
}

private class TeleportingActivity(private val destination: PositionProperty) : GenericEntityActivity {
    override var currentPosition: PositionProperty = destination

    override fun initialize(context: ActivityContext, position: PositionProperty) {
        currentPosition = position
    }

    override fun tick(context: ActivityContext): TickResult {
        currentPosition = destination
        return TickResult.CONSUMED
    }

    override fun dispose(context: ActivityContext) {}
}

private class TeleportingActivityEntry(
    override val id: String,
    override val name: String,
    private val destination: PositionProperty,
) : EntityActivityEntry {
    override fun create(context: ActivityContext, currentLocation: PositionProperty): EntityActivity<ActivityContext> =
        TeleportingActivity(destination)
}

private class TogglingActivity(
    startLocation: PositionProperty,
    private var childRef: Ref<out EntityActivityEntry>,
) : SingleChildActivity<ActivityContext>(startLocation) {
    override fun currentChild(context: ActivityContext): Ref<out EntityActivityEntry> = childRef

    fun switchTo(ref: Ref<out EntityActivityEntry>) {
        childRef = ref
    }
}

class ReusedActivityPositionSpec : FunSpec({
    val spawn = positionAt(0.0, 64.0, 0.0)
    val destination = positionAt(20.0, 64.0, 20.0)

    test("an idle activity moves to the position it is initialized with") {
        val activity = IdleActivity(spawn)

        activity.initialize(StubContext(), destination)

        activity.currentPosition shouldBe destination
    }

    test("a child activity that is used again reports where the entity is now") {
        val context = StubContext()
        val idleRef = emptyRef<EntityActivityEntry>()
        val travelRef = Ref(
            "travel",
            EntityActivityEntry::class,
            TeleportingActivityEntry("travel", "travel", destination),
        )

        val activity = TogglingActivity(spawn, idleRef)
        activity.initialize(context, spawn)
        activity.currentPosition shouldBe spawn

        activity.switchTo(travelRef)
        activity.tick(context)
        activity.currentPosition shouldBe destination

        activity.switchTo(idleRef)
        activity.tick(context)

        activity.currentPosition shouldBe destination
    }
})
