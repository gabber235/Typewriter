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

private val world = World("holder-world")

private fun positionAt(x: Double, y: Double, z: Double) = PositionProperty(world, x, y, z, 0f, 0f)

private class HolderContext : ActivityContext {
    override val instanceRef: Ref<out EntityInstanceEntry> = emptyRef()
    override val isViewed: Boolean = false
    override val viewers: List<Player> = emptyList()
    override val entityState: EntityState = EntityState()
}

private class RecordingActivity(override var currentPosition: PositionProperty) : GenericEntityActivity {
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

private class RecordingEntry(
    override val id: String,
    override val name: String,
    private val activity: RecordingActivity,
) : EntityActivityEntry {
    override fun create(context: ActivityContext, currentLocation: PositionProperty): EntityActivity<ActivityContext> =
        activity
}

private fun refTo(id: String, activity: RecordingActivity) =
    Ref(id, EntityActivityEntry::class, RecordingEntry(id, id, activity))

class ChildActivityHolderSpec : FunSpec({
    val spawn = positionAt(0.0, 64.0, 0.0)
    val target = positionAt(20.0, 64.0, 20.0)

    test("switching activates the incoming child at the given position") {
        val context = HolderContext()
        val walking = RecordingActivity(spawn)
        val holder = entryActivityHolder<ActivityContext>(spawn)

        holder.switchTo(refTo("walking", walking), context, target)

        walking.activations shouldBe 1
        holder.currentPosition shouldBe target
    }

    test("switching deactivates the outgoing child exactly once") {
        val context = HolderContext()
        val first = RecordingActivity(spawn)
        val second = RecordingActivity(spawn)
        val holder = entryActivityHolder<ActivityContext>(spawn)

        holder.switchTo(refTo("first", first), context, spawn)
        holder.switchTo(refTo("second", second), context, target)

        first.deactivations shouldBe 1
        second.activations shouldBe 1
    }

    test("a child that is used again is activated at the position it is given") {
        val context = HolderContext()
        val idle = RecordingActivity(spawn)
        val walking = RecordingActivity(spawn)
        val idleRef = refTo("idle", idle)

        val holder = entryActivityHolder<ActivityContext>(spawn)
        holder.switchTo(idleRef, context, spawn)
        holder.switchTo(refTo("walking", walking), context, spawn)
        holder.switchTo(idleRef, context, target)

        idle.activations shouldBe 2
        holder.currentPosition shouldBe target
    }

    test("activating the same child again moves it to the new position") {
        val context = HolderContext()
        val child = RecordingActivity(spawn)
        val ref = refTo("child", child)
        val holder = entryActivityHolder<ActivityContext>(spawn)

        holder.activate(ref, context, spawn)
        holder.activate(ref, context, target)

        child.activations shouldBe 2
        child.deactivations shouldBe 0
        holder.currentPosition shouldBe target
    }

    test("deactivating twice in a row only reaches the child once") {
        val context = HolderContext()
        val child = RecordingActivity(spawn)
        val holder = entryActivityHolder<ActivityContext>(spawn)

        holder.switchTo(refTo("child", child), context, spawn)
        holder.deactivate(context)
        holder.deactivate(context)

        child.deactivations shouldBe 1
    }

    test("a deactivated holder keeps reporting where the child stopped") {
        val context = HolderContext()
        val child = RecordingActivity(spawn)
        val holder = entryActivityHolder<ActivityContext>(spawn)

        holder.switchTo(refTo("child", child), context, target)
        holder.deactivate(context)

        holder.currentPosition shouldBe target
    }

    test("disposing tears down children that are no longer showing") {
        val context = HolderContext()
        val idle = RecordingActivity(spawn)
        val walking = RecordingActivity(spawn)
        val holder = entryActivityHolder<ActivityContext>(spawn)

        holder.switchTo(refTo("idle", idle), context, spawn)
        holder.switchTo(refTo("walking", walking), context, target)
        holder.deactivate(context)
        holder.dispose()

        idle.disposals shouldBe 1
        walking.disposals shouldBe 1
    }

    test("an unset ref falls back to an idle child that still adopts the position") {
        val context = HolderContext()
        val holder = entryActivityHolder<ActivityContext>(spawn)
        val idleRef = emptyRef<EntityActivityEntry>()
        val walking = RecordingActivity(spawn)

        holder.switchTo(idleRef, context, spawn)
        holder.switchTo(refTo("walking", walking), context, spawn)
        holder.switchTo(idleRef, context, target)

        holder.currentPosition shouldBe target
    }

    test("a child that could not be built yet is tried again on the next activation") {
        val context = HolderContext()
        val walking = RecordingActivity(spawn)
        var resolves = false
        val holder = ChildActivityHolder<Mode, ActivityContext>(spawn) { _, _, _ ->
            if (resolves) walking else null
        }

        holder.activate(Mode.NAVIGATING, context, spawn)
        walking.activations shouldBe 0
        holder.currentPosition shouldBe spawn

        resolves = true
        holder.activate(Mode.NAVIGATING, context, target)

        walking.activations shouldBe 1
        holder.currentPosition shouldBe target
    }

    test("a holder keyed by something other than a ref builds one child per key") {
        val context = HolderContext()
        val built = mutableListOf<Mode>()
        val holder = ChildActivityHolder<Mode, ActivityContext>(spawn) { mode, _, position ->
            built += mode
            RecordingActivity(position)
        }

        holder.activate(Mode.NAVIGATING, context, spawn)
        holder.switchTo(Mode.IDLE, context, target)
        holder.switchTo(Mode.NAVIGATING, context, spawn)

        built shouldBe listOf(Mode.NAVIGATING, Mode.IDLE)
        holder.currentKey shouldBe Mode.NAVIGATING
        holder.currentPosition shouldBe spawn
    }
})

private enum class Mode { NAVIGATING, IDLE }
