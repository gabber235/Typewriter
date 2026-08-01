package com.typewritermc.entity

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityInstanceEntry
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import org.bukkit.entity.Player

private val managerWorld = World("manager-world")

private class ManagerContext : ActivityContext {
    override val instanceRef: Ref<out EntityInstanceEntry> = emptyRef()
    override val isViewed: Boolean = false
    override val viewers: List<Player> = emptyList()
    override val entityState: EntityState = EntityState()
}

private class CountingActivity(override var currentPosition: PositionProperty) : GenericEntityActivity {
    var activations = 0
    var deactivations = 0
    var disposals = 0

    override fun activate(context: ActivityContext, position: PositionProperty) {
        currentPosition = position
        activations++
    }

    override fun tick(context: ActivityContext): TickResult = TickResult.CONSUMED

    override fun deactivate(context: ActivityContext) {
        deactivations++
    }

    override fun dispose() {
        disposals++
    }
}

class ActivityManagerSpec : FunSpec({
    val spawn = PositionProperty(managerWorld, 0.0, 64.0, 0.0, 0f, 0f)

    test("initializing activates the activity where it already stands") {
        val activity = CountingActivity(spawn)
        val manager = ActivityManager(activity)

        manager.initialize(ManagerContext())

        activity.activations shouldBe 1
        activity.currentPosition shouldBe spawn
    }

    test("initializing twice is refused") {
        val manager = ActivityManager(CountingActivity(spawn))
        manager.initialize(ManagerContext())

        shouldThrow<IllegalStateException> { manager.initialize(ManagerContext()) }
    }

    test("disposing deactivates before it disposes") {
        val activity = CountingActivity(spawn)
        val manager = ActivityManager(activity)
        manager.initialize(ManagerContext())

        manager.dispose(ManagerContext())

        activity.deactivations shouldBe 1
        activity.disposals shouldBe 1
    }

    test("disposing twice only tears down once") {
        val activity = CountingActivity(spawn)
        val manager = ActivityManager(activity)
        manager.initialize(ManagerContext())

        manager.dispose(ManagerContext())
        manager.dispose(ManagerContext())

        activity.deactivations shouldBe 1
        activity.disposals shouldBe 1
    }
})
