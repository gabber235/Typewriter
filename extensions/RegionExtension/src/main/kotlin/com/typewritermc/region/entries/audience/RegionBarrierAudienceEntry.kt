package com.typewritermc.region.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.engine.paper.utils.toBukkitVector
import com.typewritermc.region.RegionEngine
import com.typewritermc.region.content.RegionEditRegistry
import com.typewritermc.region.data.DistanceMode
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.handler.LazyInsideQueryHandler
import com.typewritermc.region.shape.averageUnitDirection
import com.typewritermc.region.tracker.RegionTracker
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.sqrt
import kotlinx.coroutines.Dispatchers
import org.bukkit.entity.Player
import org.bukkit.util.Vector as BukkitVector
import org.koin.java.KoinJavaComponent

enum class BarrierMode {
    KEEP_IN,
    KEEP_OUT,
}

@Entry(
    "region_barrier_audience",
    "Continuously push players back at a region boundary",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:shield-half-full"
)
/**
 * Continuously pushes audience players back when they approach or cross the region
 * boundary from the wrong side. [BarrierMode.KEEP_IN] holds players inside the region and
 * [BarrierMode.KEEP_OUT] holds them outside.
 *
 * The push ramps up across [activationDistance] blocks around the boundary and is applied
 * as velocity, so it turns players back rather than blocking them outright. For hard blocking,
 * use a `RegionEnterEventEntry` or `RegionExitEventEntry` with `cancel` instead. The
 * barrier also covers crossings that cannot be cancelled, like a moving region engulfing a
 * player.
 *
 * The ramp only builds where the push has somewhere to go. A player on the allowed side whose
 * nearest face is under their feet is left alone, because a region resting on the terrain has
 * its floor face exactly where everyone stands and the ramp would lift the lot of them. They
 * are pushed once they actually cross.
 *
 * With [DistanceMode.HORIZONTAL] the boundary is the region's vertical silhouette: floor and
 * ceiling faces neither push nor count toward the activation distance, so a region resting
 * on the ground pushes only against its walls, ramp included.
 *
 * A player who ends up on the wrong side is actively expelled. When they stand on the
 * ground and the nearest face is the floor or ceiling, the push is redirected toward the
 * nearest lateral exit, so they walk out through a wall instead of being pushed into the floor.
 *
 * Players inside a region content mode (editor, workspace or debugger) are left alone, so
 * the barrier cannot push the player editing it.
 *
 * ## How could this be used?
 *
 * Keep players in the arena during a boss fight, or gently push low level players away
 * from a high level zone while a title explains why.
 */
class RegionBarrierAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The region whose boundary to enforce.")
    @Default(RegionDefaults.REGION_REFERENCE)
    val region: RegionData = RegionReferenceData(),
    @Help("KeepIn holds audience players inside the region; KeepOut holds them outside.")
    val mode: BarrierMode = BarrierMode.KEEP_IN,
    @Help("Peak push velocity (blocks/tick) at and beyond the boundary. The barrier never drives a player faster than 1 block per tick, so values above that behave the same as 1.")
    @Default("0.6")
    val strength: Var<Double> = ConstVar(0.6),
    @Help("Distance from the boundary (on the allowed side) where the push starts ramping up. A face underfoot does not ramp; use Horizontal to ramp against the walls of a region standing on the ground.")
    @Default("1.5")
    val activationDistance: Var<Double> = ConstVar(1.5),
    @Help("Measure against the whole boundary, or only the vertical silhouette (Horizontal).")
    val distanceMode: DistanceMode = DistanceMode.FULL,
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay =
        RegionBarrierDisplay(region, mode, strength, activationDistance, distanceMode, id)
}

class RegionBarrierDisplay(
    private val region: RegionData,
    private val mode: BarrierMode,
    private val strength: Var<Double>,
    private val activationDistance: Var<Double>,
    private val distanceMode: DistanceMode,
    private val entryId: String?,
) : AudienceDisplay(), TickableDisplay {
    private val engine: RegionEngine by KoinJavaComponent.inject(RegionEngine::class.java)
    private val editRegistry: RegionEditRegistry by KoinJavaComponent.inject(RegionEditRegistry::class.java)
    private val subscriptions = ConcurrentHashMap<UUID, RegionEngine.Subscription>()

    override fun onPlayerAdd(player: Player) {
        engine.observe(region, player, LazyInsideQueryHandler(this, player.uniqueId))
            ?.also { subscriptions[player.uniqueId] = it }
    }

    override fun onPlayerRemove(player: Player) {
        subscriptions.remove(player.uniqueId)?.cancel()
    }

    override fun dispose() {
        subscriptions.values.forEach(RegionEngine.Subscription::cancel)
        subscriptions.clear()
        super.dispose()
    }

    override fun tick() {
        val pushes = players.mapNotNull { player ->
            if (editRegistry.inRegionMode(player.uniqueId)) return@mapNotNull null
            if (editRegistry.isSuppressed(player.uniqueId, entryId, region)) return@mapNotNull null
            pushFor(player)?.let { player to it }
        }
        if (pushes.isEmpty()) return

        // TickableDisplay.tick runs off main; velocity writes belong on the main thread.
        // One hop applies every push of this tick.
        Dispatchers.Sync.launch {
            for ((player, push) in pushes) {
                if (player.isOnline) player.velocity = pushedVelocity(player.velocity, push)
            }
        }
    }

    /**
     * The push added to [velocity], unless the player is already moving that way faster than
     * [MAX_PUSH_SPEED].
     *
     * The push repeats every tick for as long as the player is on the wrong side, and adding
     * it unconditionally compounds against Minecraft's drag into a launch. Capping the
     * component the barrier is responsible for keeps the speed it can reach bounded, and
     * still leaves speed from an elytra or an explosion alone.
     */
    private fun pushedVelocity(velocity: BukkitVector, push: Vector): BukkitVector {
        val magnitude = sqrt(push.x * push.x + push.y * push.y + push.z * push.z)
        if (magnitude < MIN_ACTIVATION) return velocity
        val along = (velocity.x * push.x + velocity.y * push.y + velocity.z * push.z) / magnitude
        val room = MAX_PUSH_SPEED - along
        if (room <= 0.0) return velocity

        // The push is scaled to what is left under the cap instead of added whole, so a high
        // strength cannot overshoot the cap by its own value on the tick it first engages.
        val scale = minOf(1.0, room / magnitude)
        return velocity.add(push.mul(scale).toBukkitVector())
    }

    private fun pushFor(player: Player): Vector? =
        subscriptions[player.uniqueId]?.tracker?.let { pushFor(player, it) }

    /** The push [player] receives from [tracker], or `null` for no push. Internal for the specs. */
    internal fun pushFor(player: Player, tracker: RegionTracker): Vector? {
        val transform = tracker.lastTransform ?: return null

        val position = player.position
        if (position.world != transform.world) return null

        val signed = tracker.signedDistance(position, distanceMode) ?: return null
        val factor = pushFactor(player, signed)
        if (factor <= 0.0) return null

        val violating = when (mode) {
            BarrierMode.KEEP_IN -> signed > 0.0
            BarrierMode.KEEP_OUT -> signed < 0.0
        }
        var worldDirection = when (distanceMode) {
            DistanceMode.FULL -> {
                val local = transform.toLocal(Vector(position.x, position.y, position.z))
                val outward = averageUnitDirection(tracker.shape.outwardNormals(local)) ?: return null
                transform.rotateLocalToWorld(if (mode == BarrierMode.KEEP_IN) outward.mul(-1.0) else outward)
            }

            DistanceMode.HORIZONTAL -> {
                val escape = tracker.horizontalEscapeDirection(position) ?: return null
                if (mode == BarrierMode.KEEP_IN) escape.mul(-1.0) else escape
            }
        }

        // A player on the wrong side of the barrier is often nearest to a floor or ceiling
        // face, and a grounded player pushed into either only feels slowed. Steer them
        // toward the nearest lateral exit instead. The silhouette mode is lateral already.
        if (distanceMode == DistanceMode.FULL &&
            violating && player.isOnGround && abs(worldDirection.y) > VERTICAL_DOMINANCE
        ) {
            tracker.horizontalEscapeDirection(position)?.let { escape ->
                worldDirection = if (mode == BarrierMode.KEEP_IN) escape.mul(-1.0) else escape
            }
        }

        // A player standing where the barrier wants them is never shoved upwards. The nearest
        // boundary of a region resting on the terrain is the floor underfoot, so the ramp would
        // otherwise lift everyone in the arena a block and a half into the air, land them, and do
        // it again for as long as they stay. Only for a player something is holding up, the ground
        // or their own flight: someone falling towards the same face is on their way to crossing
        // it, and someone already on the wrong side is pushed regardless, with the redirect above
        // walking them out sideways.
        if (!violating && (player.isOnGround || player.isFlying) && worldDirection.y > VERTICAL_DOMINANCE) {
            return null
        }

        val magnitude = strength.get(player).coerceAtLeast(0.0) * factor
        if (magnitude <= 0.0) return null
        return Vector(
            worldDirection.x * magnitude,
            worldDirection.y * magnitude,
            worldDirection.z * magnitude,
        )
    }

    /**
     * How hard to push. The value ramps across the activation band, from 0 when the player
     * is fully on the allowed side to 1 at or past the boundary.
     */
    private fun pushFactor(player: Player, signedDistance: Double): Double {
        val activation = activationDistance.get(player).coerceAtLeast(0.0)
        val ramp = max(activation, MIN_ACTIVATION)
        val factor = when (mode) {
            BarrierMode.KEEP_IN -> (signedDistance + activation) / ramp
            BarrierMode.KEEP_OUT -> (activation - signedDistance) / ramp
        }
        return factor.coerceIn(0.0, 1.0)
    }

    companion object {
        private const val MIN_ACTIVATION = 0.001

        /**
         * Above this vertical share of the push direction, a grounded violating player is
         * redirected laterally instead.
         */
        private const val VERTICAL_DOMINANCE = 0.7

        /** Fastest the barrier will drive a player away from the boundary, in blocks per tick. */
        private const val MAX_PUSH_SPEED = 1.0
    }
}
