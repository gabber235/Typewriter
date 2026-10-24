package com.typewritermc.region.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.engine.paper.utils.toBukkitVector
import com.typewritermc.region.RegionEngine
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.shape.averageUnitDirection
import kotlinx.coroutines.Dispatchers
import org.koin.java.KoinJavaComponent
import kotlin.math.abs

@Entry("region_boundary_push", "Push the player outward from the region's boundary", Colors.RED, "fa-solid:wind")
/**
 * Pushes the player away from the region's boundary. The action resolves the region's
 * shape, finds the nearest outward direction, and applies a velocity pulse along it.
 *
 * This is useful for engulf crossings, where a moving region reaches a stationary player.
 * There is no `PlayerMoveEvent` to cancel, but the push moves the player out on the next
 * physics tick.
 *
 * ## How could this be used?
 *
 * Pair it with a `RegionEnterEventEntry` and a criteria gate for low rank players. Cancel
 * the move when possible and fall back to the push when not.
 */
class RegionBoundaryPushActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("The region whose boundary to push the player away from.")
    @Default(RegionDefaults.REGION_REFERENCE)
    val region: RegionData = RegionReferenceData(),
    @Help("Magnitude of the push velocity (block/tick units).")
    @Default("0.6")
    val magnitude: Var<Double> = ConstVar(0.6),
    @Help("Vertical component added on top of the horizontal push, e.g. a small hop.")
    @Default("0.2")
    val verticalBoost: Var<Double> = ConstVar(0.2),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        val engine: RegionEngine = KoinJavaComponent.get(RegionEngine::class.java)
        val tracker = engine.query(region, player) ?: return
        val transform = tracker.lastTransform ?: return

        val position = player.position
        if (position.world != transform.world) return

        val local = transform.toLocal(Vector(position.x, position.y, position.z))
        val direction = averageUnitDirection(tracker.shape.outwardNormals(local)) ?: return
        var worldDirection = transform.rotateLocalToWorld(direction)

        // A grounded player whose nearest face is the floor or ceiling cannot be pushed
        // through it; send them toward the nearest lateral exit instead.
        if (player.isOnGround && abs(worldDirection.y) > VERTICAL_DOMINANCE) {
            tracker.horizontalEscapeDirection(position)?.let { worldDirection = it }
        }

        // The magnitude is clamped because it scales the direction away from the region, and a
        // negative one would pull the player in, which is the one thing this entry promises not
        // to do. The boost is left alone: it is added on the world Y axis, so a negative value is
        // a stomp downwards rather than a reversal.
        val strength = magnitude.get(player, context).coerceAtLeast(0.0)
        val boost = verticalBoost.get(player, context)
        val push = Vector(
            worldDirection.x * strength,
            worldDirection.y * strength + boost,
            worldDirection.z * strength,
        )

        // Velocity writes are only safe on the main thread; actions run on the
        // interaction coroutine.
        Dispatchers.Sync.launch {
            if (player.isOnline) player.velocity = player.velocity.add(push.toBukkitVector())
        }
    }

    companion object {
        private const val VERTICAL_DOMINANCE = 0.7
    }
}
