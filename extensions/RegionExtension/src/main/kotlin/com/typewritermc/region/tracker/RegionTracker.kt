package com.typewritermc.region.tracker

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.engine.paper.interaction.interactionContext
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.region.data.*
import com.typewritermc.region.handler.EnterExitHandler
import com.typewritermc.region.handler.LazyInsideQueryHandler
import com.typewritermc.region.handler.ProximityHandler
import com.typewritermc.region.handler.RegionHandler
import com.typewritermc.region.shape.LocalBounds
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.shape.hitboxSampleOffsets
import org.bukkit.entity.Player
import org.bukkit.event.player.PlayerMoveEvent
import org.bukkit.util.BoundingBox
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicLong
import kotlin.math.floor
import kotlin.math.sqrt

/**
 * Tracks one region definition. When the definition's placement is fully constant, one
 * tracker is shared by every subscriber and [viewer] is `null`. Otherwise each viewer gets
 * their own tracker and [viewer] is that player.
 *
 * Enter and exit handlers are given the distance of the player's bounding box, so partial
 * overlap counts as inside; proximity handlers are given the distance of their position.
 *
 * The handler lists are copy on write. Dispatch, the hot path, reads a snapshot without
 * locking and the rare attach or detach pays for the copy. A suspending mutex cannot be
 * used because dispatch runs inside non suspending Bukkit event handlers.
 */
class RegionTracker internal constructor(
    val viewer: Player?,
    private val definition: RegionDefinition,
) {
    private val handlerGeneration = AtomicLong()
    private val enterExitHandlers = CopyOnWriteArrayList<EnterExitHandler>()
    private val proximityHandlers = CopyOnWriteArrayList<ProximityHandler>()
    private val lazyQueryHandlers = CopyOnWriteArrayList<LazyInsideQueryHandler>()

    val shape: Shape = definition.buildShape()

    /** Names this region in diagnostics. An inline definition has no entry to name. */
    internal val definitionName: String
        get() = (definition as? RegionDefinitionEntry)?.name ?: "inline region"

    val tier: Tier = if (definition.hasConstPlacement) Tier.Static else Tier.Dynamic

    val refreshRateTicks: Int get() = definition.refreshRateTicks

    @Volatile
    var lastTransform: ResolvedTransform? = null
        private set

    /**
     * Cached world AABB of the resolved shape expanded by the largest constant proximity
     * distance. `null` until the first [refresh] or when the transform cannot resolve.
     */
    @Volatile
    internal var cachedAabb: WorldAabb? = null
        private set

    /**
     * `true` when an attached proximity handler has a non constant distance or measures
     * horizontally. No finite AABB margin covers such a handler, so the engine skips
     * spatial pre filtering for this tracker.
     */
    @Volatile
    internal var marginUnbounded: Boolean = false
        private set

    /**
     * Set by the engine while the tracker lives in the registry. The scheduler drops
     * unregistered trackers when they come due. Query cache trackers are never registered.
     */
    @Volatile
    internal var isRegistered: Boolean = false

    internal fun attach(handler: RegionHandler) {
        when (handler) {
            is EnterExitHandler -> enterExitHandlers.add(handler)
            is ProximityHandler -> proximityHandlers.add(handler)
            is LazyInsideQueryHandler -> lazyQueryHandlers.add(handler)
        }
        handlerGeneration.incrementAndGet()
        refreshAabb()
    }

    internal fun detach(handler: RegionHandler) {
        when (handler) {
            is EnterExitHandler -> enterExitHandlers.remove(handler)
            is ProximityHandler -> proximityHandlers.remove(handler)
            is LazyInsideQueryHandler -> lazyQueryHandlers.remove(handler)
        }
        handlerGeneration.incrementAndGet()
        refreshAabb()
    }

    internal fun isEmpty(): Boolean =
        enterExitHandlers.isEmpty() && proximityHandlers.isEmpty() && lazyQueryHandlers.isEmpty()

    internal fun wantsDispatch(): Boolean =
        enterExitHandlers.isNotEmpty() || proximityHandlers.isNotEmpty()

    /**
     * Resolves the current world space transform and rebuilds the cached AABB. Called once
     * at registration for static trackers and once per scheduled refresh for dynamic ones.
     */
    internal fun refresh() {
        val viewer = viewer
        if (viewer != null && !viewer.isOnline) {
            lastTransform = null
            cachedAabb = null
            return
        }

        val context = viewer?.interactionContext
        val origin = definition.origin.get(viewer, context)
        val offset = definition.offset.get(viewer, context)
        val yaw = definition.yaw.get(viewer, context)
        val pitch = definition.pitch.get(viewer, context)
        val roll = definition.roll.get(viewer, context)
        if (origin == null || offset == null || yaw == null || pitch == null || roll == null) {
            lastTransform = null
            cachedAabb = null
            return
        }

        val rotate = definition.rotateWithOrigin
        val yawDegrees = if (rotate) yaw + origin.yaw else yaw
        val pitchDegrees = if (rotate) pitch + origin.pitch else pitch
        lastTransform = ResolvedTransform.fromOriginAndOffset(origin, offset, yawDegrees, pitchDegrees, roll)
        refreshAabb()
    }

    /**
     * Recomputes the cached AABB, and does it again whenever a handler arrived or left while it
     * was computing.
     *
     * Two audience filters attaching at once would otherwise race, and the loser writes what it
     * read before the winner's handler existed: a proximity band whose margin no AABB covers can
     * end up recorded as bounded and two blocks wide, which takes the tracker into the chunk
     * index and stops the band firing for anyone further out.
     */
    private fun refreshAabb() {
        do {
            val generation = handlerGeneration.get()
            writeAabb()
        } while (generation != handlerGeneration.get())
    }

    private fun writeAabb() {
        val transform = lastTransform
        if (transform == null) {
            cachedAabb = null
            return
        }

        var margin = 0.0
        var unbounded = false
        for (handler in proximityHandlers) {
            if (handler.distanceMode == DistanceMode.HORIZONTAL) {
                unbounded = true
                continue
            }
            val distance = handler.distance
            if (distance is ConstVar) {
                margin = maxOf(margin, distance.value)
            } else {
                unbounded = true
            }
        }
        if (enterExitHandlers.isNotEmpty()) margin = maxOf(margin, HITBOX_MARGIN)

        marginUnbounded = unbounded
        val rotated = shape.localBounds.rotated(
            transform.yawDegrees,
            transform.pitchDegrees,
            transform.rollDegrees,
        )
        cachedAabb = WorldAabb.of(transform, rotated, margin.coerceAtLeast(0.0))
    }

    fun isInside(worldPosition: Position): Boolean {
        val transform = lastTransform ?: return false
        if (transform.world != worldPosition.world) return false

        val local = transform.toLocal(Vector(worldPosition.x, worldPosition.y, worldPosition.z))
        return shape.contains(local)
    }

    /**
     * `true` when any part of the player's bounding box overlaps the resolved shape. This
     * is the same membership check enter and exit classification uses.
     */
    fun isInside(player: Player): Boolean {
        val signed = classifyHitbox(player, player.position) ?: return false
        return signed <= 0.0
    }

    /**
     * How many of [players] have any part of their body inside the region, answered once per
     * server tick.
     *
     * A count fact is read once per reader per refresh, and every read classifies every player's
     * hitbox, so a sidebar showing the count on a full server ran players squared distance
     * evaluations several times a second. Nothing about the count changes within a tick, so one
     * tick's answer serves every reader of that tick.
     */
    fun countInside(players: Collection<Player>): Int {
        val tick = server.currentTick
        val memo = insideCount
        if (memo != null && memo.tick == tick) return memo.count
        var count = 0
        for (player in players) if (isInside(player)) count++
        insideCount = InsideCount(tick, count)
        return count
    }

    @Volatile
    private var insideCount: InsideCount? = null

    private class InsideCount(val tick: Int, val count: Int)

    /**
     * Signed distance from the position to the shape boundary. Negative inside, positive
     * outside. Returns `null` when the transform is unresolved or the position is in
     * another world.
     */
    fun signedDistance(worldPosition: Position): Double? = classify(worldPosition)

    /** [signedDistance] against the vertical silhouette only, ignoring floor and ceiling faces. */
    fun signedDistanceHorizontal(worldPosition: Position): Double? = classifyHorizontal(worldPosition)

    fun signedDistance(worldPosition: Position, mode: DistanceMode): Double? = when (mode) {
        DistanceMode.FULL -> classify(worldPosition)
        DistanceMode.HORIZONTAL -> classifyHorizontal(worldPosition)
    }

    /**
     * The smallest signed distance over the player's bounding box at their live position.
     * This is the metric enter and exit classification observes; expose it so diagnostics
     * can report exactly what the handlers see.
     */
    fun hitboxDistance(player: Player): Double? = classifyHitbox(player, player.position)

    /**
     * Unit direction in the world XZ plane along which the signed distance to the region
     * grows fastest, or radially away from the region anchor when the gradient vanishes.
     * The barrier and push action use it to steer grounded players toward a lateral exit
     * instead of into the floor or ceiling. Returns `null` only when the transform is
     * unresolved or the position is in another world.
     */
    fun horizontalEscapeDirection(worldPosition: Position): Vector? {
        val transform = lastTransform ?: return null
        if (transform.world != worldPosition.world) return null

        // The silhouette, not the full field: this is only ever called when the nearest face is
        // the floor or the ceiling, and there the full field's horizontal gradient is flat, so
        // differencing it hands back nothing and the player keeps being pushed into the floor.
        fun distanceAt(dx: Double, dz: Double): Double = shape.signedDistanceHorizontal(
            transform.toLocal(Vector(worldPosition.x + dx, worldPosition.y, worldPosition.z + dz)),
        )

        val gradientX = distanceAt(GRADIENT_STEP, 0.0) - distanceAt(-GRADIENT_STEP, 0.0)
        val gradientZ = distanceAt(0.0, GRADIENT_STEP) - distanceAt(0.0, -GRADIENT_STEP)
        val gradientLength = sqrt(gradientX * gradientX + gradientZ * gradientZ)
        if (gradientLength > Vector.EPSILON) {
            return Vector(gradientX / gradientLength, 0.0, gradientZ / gradientLength)
        }

        val anchorX = worldPosition.x - transform.worldOrigin.x
        val anchorZ = worldPosition.z - transform.worldOrigin.z
        val anchorLength = sqrt(anchorX * anchorX + anchorZ * anchorZ)
        if (anchorLength > Vector.EPSILON) {
            return Vector(anchorX / anchorLength, 0.0, anchorZ / anchorLength)
        }

        // Dead center of a symmetric region: every lateral direction leads out as well as the
        // next. The caller only asks here because the face it found points at the floor or the
        // ceiling, and answering nothing leaves the player pressed into one of them.
        return CENTERED_ESCAPE
    }

    /**
     * `true` when any attached enter/exit handler currently counts [player] as entered.
     * Diagnostics report it next to the geometric membership, so a gap between
     * "geometrically inside" and "enter fired" is directly visible.
     */
    fun countsAsEntered(player: Player): Boolean = enterExitHandlers.any { it.tracks(player) }

    /**
     * Snapshot of the tracker's state for the `/typewriter region debug` command.
     */
    fun debugSnapshot(): DebugSnapshot = DebugSnapshot(
        registered = isRegistered,
        enterExitHandlers = enterExitHandlers.size,
        proximityHandlers = proximityHandlers.size,
        lazyQueryHandlers = lazyQueryHandlers.size,
        transform = lastTransform,
    )

    data class DebugSnapshot(
        val registered: Boolean,
        val enterExitHandlers: Int,
        val proximityHandlers: Int,
        val lazyQueryHandlers: Int,
        val transform: ResolvedTransform?,
    )

    /**
     * Classifies [player] at [position] and notifies every attached handler with the metric
     * that handler observes. Returns `true` when a handler requests cancellation of
     * [moveEvent]. The engine ignores the result on the async reconcile path, where there
     * is no move event.
     */
    internal fun dispatch(
        player: Player,
        position: Position,
        cause: CrossingCause,
        moveEvent: PlayerMoveEvent?,
    ): Boolean {
        // The check comes before the metrics: classifying a player's whole hitbox is forty five signed
        // distance evaluations, and every handler here would throw the result away.
        if (!wantsPlayer(player)) return false
        val metrics = metricsAt(player, position)
        var cancel = false
        forEachDispatchHandler { handler ->
            if (handler.onClassification(player, metrics.metricFor(handler), cause, moveEvent)) cancel = true
        }
        return cancel
    }

    /**
     * Updates every handler's membership for [player] as if they stood at [position],
     * without firing callbacks, and marks the crossing refused. The engine calls this after
     * cancelling a move, so no handler keeps state from the rolled back crossing and none of
     * them fires it again on the next move.
     */
    internal fun resyncAt(player: Player, position: Position) {
        val metrics = metricsAt(player, position)
        // The refusal comes before the resync. It tells a handler which side it was heading
        // for, and the resync needs that: the player is left standing where their body still
        // overlaps the region, so deriving membership from the geometry alone would put them
        // back on the side they were just refused from.
        forEachDispatchHandler { it.refuse(player) }
        forEachDispatchHandler { it.resync(player, metrics.metricFor(it)) }
    }

    /** Forgets the refusals [resyncAt] recorded, once [player] completes a move. */
    internal fun clearRefusals(player: Player) {
        forEachDispatchHandler { it.clearRefusal(player) }
    }

    /**
     * Aligns a fresh handler's membership with the player's current position without
     * firing callbacks, using the same metric the handler observes during dispatch.
     */
    internal fun seedHandler(player: Player, handler: RegionHandler) {
        val metric = when (handler) {
            is EnterExitHandler -> classifyHitbox(player, player.position)
            is ProximityHandler -> when (handler.distanceMode) {
                DistanceMode.FULL -> classify(player.position)
                DistanceMode.HORIZONTAL -> classifyHorizontal(player.position)
            }

            is LazyInsideQueryHandler -> return
        }
        handler.resync(player, metric)
    }

    /** Aligns every attached handler's membership with [players], firing nothing. */
    internal fun seedHandlers(players: Collection<Player>) {
        for (player in players) forEachDispatchHandler { seedHandler(player, it) }
    }

    /**
     * Final dispatch for a player leaving the server. Every handler sees a `null`
     * classification, fires a leave for current members, and drops their state.
     */
    internal fun evict(player: Player, cause: CrossingCause) {
        forEachDispatchHandler { it.onClassification(player, null, cause, null) }
    }

    /**
     * `true` when any attached handler still considers [player] a member. The engine only
     * skips a tracker for a player outside its world AABB when this is `false`, otherwise
     * the exit would never be dispatched.
     */
    internal fun hasMember(player: Player): Boolean =
        enterExitHandlers.any { it.tracks(player) } || proximityHandlers.any { it.tracks(player) }

    private fun wantsPlayer(player: Player): Boolean {
        val uuid = player.uniqueId
        return enterExitHandlers.any { it.tracked == null || it.tracked == uuid } ||
                proximityHandlers.any { it.tracked == null || it.tracked == uuid }
    }

    private inline fun forEachDispatchHandler(action: (RegionHandler) -> Unit) {
        for (handler in enterExitHandlers) action(handler)
        for (handler in proximityHandlers) action(handler)
    }

    private fun classify(position: Position): Double? {
        val transform = lastTransform ?: return null
        if (transform.world != position.world) return null

        val local = transform.toLocal(Vector(position.x, position.y, position.z))
        return shape.signedDistance(local)
    }

    private fun classifyHorizontal(position: Position): Double? {
        val transform = lastTransform ?: return null
        if (transform.world != position.world) return null

        val local = transform.toLocal(Vector(position.x, position.y, position.z))
        return shape.signedDistanceHorizontal(local)
    }

    /**
     * The smallest signed distance over sample points of the player's bounding box,
     * anchored at [position]. Negative as soon as a sample lands in the shape, so a player
     * brushing a thin region (like a cone near its apex) still classifies as inside, down
     * to the lattice's spacing.
     */
    private fun classifyHitbox(player: Player, position: Position): Double? {
        val transform = lastTransform ?: return null
        if (transform.world != position.world) return null

        val box = player.boundingBox
        var min = Double.MAX_VALUE
        for ((x, y, z) in hitboxSampleOffsets(box.widthX / 2.0, box.height)) {
            val local = transform.toLocal(
                Vector(position.x + x, position.y + y, position.z + z),
            )
            val signed = shape.signedDistance(local)
            if (signed < min) min = signed
        }
        return min
    }

    private fun metricsAt(player: Player, position: Position): Metrics {
        var needFull = false
        var needHorizontal = false
        for (handler in proximityHandlers) {
            when (handler.distanceMode) {
                DistanceMode.FULL -> needFull = true
                DistanceMode.HORIZONTAL -> needHorizontal = true
            }
        }
        return Metrics(
            hitbox = if (enterExitHandlers.isNotEmpty()) classifyHitbox(player, position) else null,
            full = if (needFull) classify(position) else null,
            horizontal = if (needHorizontal) classifyHorizontal(position) else null,
        )
    }

    private class Metrics(val hitbox: Double?, val full: Double?, val horizontal: Double?) {
        fun metricFor(handler: RegionHandler): Double? = when (handler) {
            is EnterExitHandler -> hitbox
            is ProximityHandler -> when (handler.distanceMode) {
                DistanceMode.FULL -> full
                DistanceMode.HORIZONTAL -> horizontal
            }

            is LazyInsideQueryHandler -> null
        }
    }

    companion object {
        /**
         * AABB slack covering the largest player bounding box, so a player whose feet are
         * outside the shape's AABB but whose body overlaps the region is still dispatched.
         */
        private const val HITBOX_MARGIN = 2.0

        /** Half width of the central difference used by [horizontalEscapeDirection]. */
        private const val GRADIENT_STEP = 0.25

        /** The lateral direction [horizontalEscapeDirection] falls back on at a region's center. */
        private val CENTERED_ESCAPE = Vector(1.0, 0.0, 0.0)
    }
}

/**
 * Inclusive world space AABB. The engine uses it to cheaply reject players before
 * classifying and to compute the chunk span for the spatial index.
 */
internal data class WorldAabb(
    val world: World,
    val minX: Double,
    val minY: Double,
    val minZ: Double,
    val maxX: Double,
    val maxY: Double,
    val maxZ: Double,
) {
    val minChunkX: Int get() = floor(minX).toInt() shr 4
    val maxChunkX: Int get() = floor(maxX).toInt() shr 4
    val minChunkZ: Int get() = floor(minZ).toInt() shr 4
    val maxChunkZ: Int get() = floor(maxZ).toInt() shr 4

    fun contains(position: Position): Boolean =
        position.x in minX..maxX && position.y in minY..maxY && position.z in minZ..maxZ

    /**
     * Whether a player standing at [position] could overlap this box with any part of [box].
     *
     * The classification samples the whole hitbox but the position is the player's feet, so the
     * box has to be accounted for here too. A scaled player is the case that makes this matter:
     * `generic.scale` reaches 16, which is a hitbox 28.8 blocks tall, far past any fixed slack.
     */
    fun reachableBy(position: Position, box: BoundingBox): Boolean {
        if (world != position.world) return false
        val halfWidth = box.widthX / 2.0
        return position.x in (minX - halfWidth)..(maxX + halfWidth) &&
                position.y in (minY - box.height)..maxY &&
                position.z in (minZ - halfWidth)..(maxZ + halfWidth)
    }

    companion object {
        fun of(transform: ResolvedTransform, rotated: LocalBounds, margin: Double): WorldAabb {
            val origin = transform.worldOrigin
            return WorldAabb(
                world = transform.world,
                minX = origin.x + rotated.minX - margin,
                minY = origin.y + rotated.minY - margin,
                minZ = origin.z + rotated.minZ - margin,
                maxX = origin.x + rotated.maxX + margin,
                maxY = origin.y + rotated.maxY + margin,
                maxZ = origin.z + rotated.maxZ + margin,
            )
        }
    }
}
