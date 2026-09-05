package com.typewritermc.region.entries.display

import com.google.common.collect.Sets
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.entries.display.GroundOutlineCache.Companion.TERRAIN_REFRESH
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.tracker.RegionTracker
import kotlinx.coroutines.Dispatchers
import org.bukkit.World
import java.time.Duration
import java.time.Instant
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.*

/**
 * A point on the line where a region meets the ground. [outward] points horizontally away
 * from the region's footprint, or [Vector.ZERO] when the direction is ambiguous. [corner]
 * marks a point where the outline turns sharply; resampling keeps corners exactly in
 * place.
 */
internal data class GroundOutlinePoint(val position: Vector, val outward: Vector, val corner: Boolean = false)

/**
 * Caches one ground outline sampling. Terrain has no change signal the displays can
 * subscribe to, so a sampling stays valid for [TERRAIN_REFRESH] and is redone when the
 * region's resolved transform changes.
 *
 * The sampling reads blocks, which is only safe on the server thread, while the displays
 * that ask for it tick off it. So a stale cache does not resample in place: it schedules the
 * work on the main thread and keeps handing out the previous sampling until that lands. The
 * ground line is therefore up to one refresh behind a terrain change, and never reads a chunk
 * section while the server is writing to it.
 */
/**
 * Points from one sampling, with the stamp identifying it. Callers keeping derived state ask
 * whether the stamp changed rather than whether the points differ.
 */
internal class StampedPoints(val stamp: Instant, val points: List<GroundOutlinePoint>)

internal class GroundOutlineCache {
    @Volatile
    private var sampling: Sampling = Sampling.NONE
    private val spacings: MutableSet<Double> = Sets.newConcurrentHashSet()
    private val refreshing = AtomicBoolean(false)

    fun pointsFor(shape: Shape, transform: ResolvedTransform, world: World, now: Instant): List<GroundOutlinePoint> {
        val current = sampling
        if (current.isStale(transform, world, now)) refresh(shape, transform, world, now)
        return current.points
    }

    /**
     * The outline distributed evenly, one point per [spacing] blocks, memoized per sampling and
     * per spacing so callers resampling the same cache at different spacings never thrash a
     * shared memo.
     */
    fun resampledFor(
        shape: Shape,
        transform: ResolvedTransform,
        world: World,
        now: Instant,
        spacing: Double,
    ): StampedPoints {
        val current = samplingWith(shape, transform, world, now, spacing)
        // Falls back to the sampling's own resolution rather than nothing: an empty list would
        // blank the line for the tick or two before the refresh lands.
        return StampedPoints(current.computedAt, current.resampled[spacing] ?: current.points)
    }

    /**
     * The sampling to serve [spacing] from, scheduling a refresh when it is stale or when this
     * spacing is one the current sampling was not resampled for.
     *
     * Every caller takes its points and its stamp from the one sampling this returns. Reading the
     * stamp separately lets a refresh land in between, which stamps the old points as current and
     * keeps them on screen until the sampling after that.
     */
    private fun samplingWith(
        shape: Shape,
        transform: ResolvedTransform,
        world: World,
        now: Instant,
        spacing: Double,
    ): Sampling {
        // A spacing bound to a variable can differ per player and change as they move, so the
        // set is bounded rather than left to grow with every value it has ever seen. One entry
        // goes, not all of them, and never the one being asked for: emptying the set, or evicting
        // the caller's own spacing, makes the next call miss and schedule another refresh, so the
        // cache thrashes exactly when it is under load.
        if (spacing !in spacings) {
            while (spacings.size >= MAX_SPACINGS) {
                spacings.remove(spacings.firstOrNull { it != spacing } ?: break)
            }
        }
        val fresh = spacings.add(spacing)

        val current = sampling
        if (fresh || current.isStale(transform, world, now)) refresh(shape, transform, world, now)
        return current
    }

    private fun refresh(shape: Shape, transform: ResolvedTransform, world: World, now: Instant) {
        if (!refreshing.compareAndSet(false, true)) return
        Dispatchers.Sync.launch {
            try {
                val points = sampleGroundOutline(shape, transform, world)
                sampling = Sampling(
                    transformHash = transform.hashCode(),
                    worldId = world.uid,
                    computedAt = now,
                    points = points,
                    resampled = spacings.associateWith { resampleBySpacing(points, it, shape, transform, world) },
                )
            } finally {
                refreshing.set(false)
            }
        }
    }

    private class Sampling(
        private val transformHash: Int?,
        private val worldId: UUID?,
        val computedAt: Instant,
        val points: List<GroundOutlinePoint>,
        val resampled: Map<Double, List<GroundOutlinePoint>>,
    ) {
        fun isStale(transform: ResolvedTransform, world: World, now: Instant): Boolean =
            transformHash != transform.hashCode() ||
                    worldId != world.uid ||
                    Duration.between(computedAt, now) >= TERRAIN_REFRESH

        companion object {
            val NONE = Sampling(null, null, Instant.EPOCH, emptyList(), emptyMap())
        }
    }

    // One field rather than a path and a stamp side by side: a display's tick is not pinned to one
    // thread, and two fields can be read as a pair that never existed.
    @Volatile
    private var cachedPath: StampedPath? = null

    /** The outline as a walkable loop, at animation resolution, memoized per sampling. */
    fun pathFor(shape: Shape, transform: ResolvedTransform, world: World, now: Instant): GroundLinePath {
        val current = samplingWith(shape, transform, world, now, ANIMATION_PATH_STEP)
        val cached = cachedPath
        if (cached != null && cached.stamp == current.computedAt) return cached.path

        val points = current.resampled[ANIMATION_PATH_STEP] ?: current.points
        return GroundLinePath(points).also { cachedPath = StampedPath(current.computedAt, it) }
    }

    private class StampedPath(val stamp: Instant, val path: GroundLinePath)

    companion object {
        private val TERRAIN_REFRESH: Duration = Duration.ofSeconds(2)

        /** How many distinct spacings one cache keeps resampled at a time. */
        private const val MAX_SPACINGS = 8
    }
}

/**
 * One [GroundOutlineCache] per sampling identity: every viewer of a statically placed
 * region shares one tracker and therefore one cache, so many players cost one terrain
 * sampling instead of one each. A viewer dependent region resolves per player and keeps a
 * cache per viewer. The boundary displays tick their players sequentially, so the shared
 * cache is never touched from two threads at once.
 */
internal class GroundCachePool {
    private val shared = GroundOutlineCache()
    private val perViewer = ConcurrentHashMap<UUID, GroundOutlineCache>()

    fun cacheFor(tracker: RegionTracker, playerId: UUID): GroundOutlineCache =
        if (tracker.viewer == null) shared else perViewer.computeIfAbsent(playerId) { GroundOutlineCache() }

    fun forget(playerId: UUID) {
        perViewer.remove(playerId)
    }

    fun clear() {
        perViewer.clear()
    }
}

/**
 * Samples the outline of the region's footprint on the ground: for every block column
 * under the region, the lowest walkable surface (solid block with a non solid block above)
 * inside the region's vertical span is located and the column is classified by whether the
 * region contains the point just above that surface. The outline is every inside column
 * that borders an outside one. A region floating in the air, or one with no surface below
 * it in its span, produces no points.
 *
 * Outline points near the footprint silhouette are then projected onto it with the shape's
 * horizontal signed distance, so the line follows the true boundary instead of the block
 * centers, and silhouette corners falling between two block columns (a rotated cuboid's
 * tip) get an explicit point where the two edges meet. Points deep inside the footprint,
 * where the line follows a terrain break like a cliff, keep their block column.
 *
 * Points come back ordered by angle around the anchor with sharp turns marked as corners,
 * so [resampleBySpacing] can distribute them evenly, and consecutive samplings of
 * unchanged terrain produce an identical list.
 *
 * Reads blocks, so it runs on the main thread, scheduled by [GroundOutlineCache]. Unloaded
 * chunks are skipped and never counted as outside.
 */
internal fun sampleGroundOutline(
    shape: Shape,
    transform: ResolvedTransform,
    world: World,
    terrain: GroundTerrain = SnapshotTerrain(world),
): List<GroundOutlinePoint> {
    val bounds = shape.localBounds.rotated(transform.yawDegrees, transform.pitchDegrees, transform.rollDegrees)
    val anchor = transform.worldOrigin
    val minX = floor(anchor.x + bounds.minX).toInt()
    val maxX = floor(anchor.x + bounds.maxX).toInt()
    val minZ = floor(anchor.z + bounds.minZ).toInt()
    val maxZ = floor(anchor.z + bounds.maxZ).toInt()
    if (maxX < minX || maxZ < minZ) return emptyList()

    val span = scanSpan(shape, transform, world) ?: return emptyList()
    val scanTop = span.top
    val scanBottom = span.bottom

    val stride = strideFor((maxX - minX + 1).toLong() * (maxZ - minZ + 1))
    val columns = HashMap<Long, ColumnSample>()
    var x = minX
    while (x <= maxX) {
        var z = minZ
        while (z <= maxZ) {
            sampleColumn(shape, transform, terrain, x, z, scanTop, scanBottom)?.let { columns[packColumn(x, z)] = it }
            z += stride
        }
        x += stride
    }

    val points = mutableListOf<GroundOutlinePoint>()
    for ((key, column) in columns) {
        if (!column.inside) continue
        val columnX = unpackColumnX(key)
        val columnZ = unpackColumnZ(key)

        var outwardX = 0.0
        var outwardZ = 0.0
        var boundary = false
        for ((dx, dz) in NEIGHBOR_STEPS) {
            val nx = columnX + dx * stride
            val nz = columnZ + dz * stride
            val neighbor = if (nx in minX..maxX && nz in minZ..maxZ) {
                columns[packColumn(nx, nz)] ?: continue
            } else {
                OUTSIDE_FOOTPRINT
            }
            if (neighbor.inside) continue
            boundary = true
            outwardX += dx
            outwardZ += dz
        }
        if (!boundary) continue

        val outwardLength = sqrt(outwardX * outwardX + outwardZ * outwardZ)
        val outward =
            if (outwardLength > 1e-9) Vector(outwardX / outwardLength, 0.0, outwardZ / outwardLength) else Vector.ZERO
        points += GroundOutlinePoint(
            Vector(columnX + 0.5, column.surfaceY + SURFACE_LIFT, columnZ + 0.5),
            outward,
        )
    }

    val refined = points.map { refineOntoSilhouette(it, shape, transform, terrain, scanTop, scanBottom) }
        .sortedBy { atan2(it.point.position.z - anchor.z, it.point.position.x - anchor.x) }
    return markCornerApexes(insertSilhouetteCorners(refined, shape, transform, terrain, scanTop, scanBottom))
}

/**
 * Distributes points evenly along the outline loop, [spacing] blocks apart. Corner points
 * stay exactly where they are and every stretch between them is divided into equal arc
 * steps, so a box gets a point on each corner and identical gaps along each edge, and a
 * cornerless loop becomes one uniform ring whose closing seam is spaced like everywhere
 * else. Gaps wider than [RESAMPLE_BREAK] mark holes in the line, like unloaded chunks or
 * the footprint leaving the terrain, and are never bridged with fabricated points.
 *
 * Every generated point is pulled onto the silhouette (chords sag inward on curved
 * footprints) and draped onto the walkable surface; a point whose column has no valid
 * surface is dropped.
 */
internal fun resampleBySpacing(
    points: List<GroundOutlinePoint>,
    spacing: Double,
    shape: Shape,
    transform: ResolvedTransform,
    world: World,
    terrain: GroundTerrain = SnapshotTerrain(world),
): List<GroundOutlinePoint> {
    if (points.size < 2) return points
    val step = spacing.coerceAtLeast(MIN_RESAMPLE_SPACING)
    val span = scanSpan(shape, transform, world) ?: return points

    val breaks = BooleanArray(points.size) { index ->
        horizontalDistanceSquared(points[index].position, points[(index + 1) % points.size].position) >
                RESAMPLE_BREAK * RESAMPLE_BREAK
    }

    val result = mutableListOf<GroundOutlinePoint>()
    fun emitRun(run: List<GroundOutlinePoint>, endsAtBreak: Boolean) {
        result += run.first()
        if (run.size < 2) return
        val lengths = DoubleArray(run.size - 1) {
            sqrt(horizontalDistanceSquared(run[it].position, run[it + 1].position))
        }
        val total = lengths.sum()
        if (total > 1e-6) {
            val count = (total / step).roundToInt().coerceAtLeast(1)
            for (notch in 1 until count) {
                pointAtArcDistance(run, lengths, notch * total / count, shape, transform, terrain, span)
                    ?.let { result += it }
            }
        }
        if (endsAtBreak) result += run.last()
    }

    val start = points.indices.firstOrNull { index ->
        points[index].corner || breaks[(index + points.size - 1) % points.size]
    }
    if (start == null) {
        // No corners and no holes: one closed ring, resampled seamlessly across the wrap.
        val run = points + points.first()
        val lengths = DoubleArray(run.size - 1) {
            sqrt(horizontalDistanceSquared(run[it].position, run[it + 1].position))
        }
        val total = lengths.sum()
        if (total < 1e-6) return listOf(points.first())
        val count = (total / step).roundToInt().coerceAtLeast(1)
        return (0 until count).mapNotNull { notch ->
            pointAtArcDistance(run, lengths, notch * total / count, shape, transform, terrain, span)
        }
    }

    var run = mutableListOf(points[start])
    for (offset in 1..points.size) {
        val index = (start + offset) % points.size
        val closesLoop = offset == points.size
        if (breaks[(start + offset - 1) % points.size]) {
            emitRun(run, endsAtBreak = true)
            if (closesLoop) break
            run = mutableListOf(points[index])
            continue
        }
        run.add(points[index])
        if (closesLoop) {
            // The loop closed back onto the starting vertex, which the first run emitted.
            emitRun(run, endsAtBreak = false)
            break
        }
        if (points[index].corner) {
            emitRun(run, endsAtBreak = false)
            run = mutableListOf(points[index])
        }
    }
    return result
}

/** The vertical block range a sampling scans for walkable surfaces. */
private class ScanSpan(val top: Int, val bottom: Int)

private fun scanSpan(shape: Shape, transform: ResolvedTransform, world: World): ScanSpan? {
    val bounds = shape.localBounds.rotated(transform.yawDegrees, transform.pitchDegrees, transform.rollDegrees)
    val anchor = transform.worldOrigin
    val top = min(floor(anchor.y + bounds.maxY).toInt(), world.maxHeight - 1)
    val bottom = max(floor(anchor.y + bounds.minY).toInt() - 1, world.minHeight)
    if (top < bottom) return null
    return ScanSpan(top, bottom)
}

/** The point [distance] blocks along [run]'s polyline, draped and pulled onto the silhouette. */
private fun pointAtArcDistance(
    run: List<GroundOutlinePoint>,
    lengths: DoubleArray,
    distance: Double,
    shape: Shape,
    transform: ResolvedTransform,
    terrain: GroundTerrain,
    span: ScanSpan,
): GroundOutlinePoint? {
    var remaining = distance
    var index = 0
    while (index < lengths.size - 1 && remaining > lengths[index]) {
        remaining -= lengths[index]
        index++
    }
    val segment = lengths[index]
    val fraction = if (segment < 1e-9) 0.0 else (remaining / segment).coerceIn(0.0, 1.0)
    return interpolatedPoint(run[index], run[index + 1], fraction, shape, transform, terrain, span)
}

private fun interpolatedPoint(
    a: GroundOutlinePoint,
    b: GroundOutlinePoint,
    fraction: Double,
    shape: Shape,
    transform: ResolvedTransform,
    terrain: GroundTerrain,
    span: ScanSpan,
): GroundOutlinePoint? {
    val chordX = a.position.x + (b.position.x - a.position.x) * fraction
    val chordZ = a.position.z + (b.position.z - a.position.z) * fraction
    val y = a.position.y + (b.position.y - a.position.y) * fraction
    val chordOutward = lerpOutward(a.outward, b.outward, fraction)

    var x = chordX
    var z = chordZ
    var outward = chordOutward
    val local = transform.toLocal(Vector(chordX, y, chordZ))
    if (shape.signedDistanceHorizontal(local) > -DEEP_INSIDE) {
        projectToSilhouette(local, shape)?.let { projection ->
            val target = transform.toWorld(projection.local)
            val movedX = target.x - chordX
            val movedZ = target.z - chordZ
            if (movedX * movedX + movedZ * movedZ <= MAX_CHORD_CORRECTION * MAX_CHORD_CORRECTION) {
                x = target.x
                z = target.z
                worldOutward(transform, projection.outwardLocal)?.let { outward = it }
            }
        }
    }

    resampledSurfaceY(shape, transform, terrain, x, z, span)?.let { surface ->
        return GroundOutlinePoint(Vector(x, surface + SURFACE_LIFT, z), outward)
    }
    if (x == chordX && z == chordZ) return null
    val surface = resampledSurfaceY(shape, transform, terrain, chordX, chordZ, span) ?: return null
    return GroundOutlinePoint(Vector(chordX, surface + SURFACE_LIFT, chordZ), chordOutward)
}

/**
 * The walkable surface under a resampled point. Like [drapedSurfaceY], but a point whose
 * own spot the region does not reach still counts when its block column's center is
 * inside: refined silhouette points overhang their column the same way when the widest
 * slice sits above the ground, and the generated points must not be stricter than the
 * samples they interpolate.
 */
private fun resampledSurfaceY(
    shape: Shape,
    transform: ResolvedTransform,
    terrain: GroundTerrain,
    x: Double,
    z: Double,
    span: ScanSpan,
): Double? {
    val columnX = floor(x).toInt()
    val columnZ = floor(z).toInt()
    if (!terrain.isColumnLoaded(columnX, columnZ)) return null
    val surface = groundSurfaceY(terrain, columnX, columnZ, span.top, span.bottom) ?: return null
    if (shape.contains(transform.toLocal(Vector(x, surface + PROBE_HEIGHT, z)))) return surface
    if (shape.contains(transform.toLocal(Vector(columnX + 0.5, surface + PROBE_HEIGHT, columnZ + 0.5)))) return surface
    return null
}

private fun lerpOutward(a: Vector, b: Vector, fraction: Double): Vector {
    if (a == Vector.ZERO) return b
    if (b == Vector.ZERO) return a
    val x = a.x + (b.x - a.x) * fraction
    val z = a.z + (b.z - a.z) * fraction
    val length = sqrt(x * x + z * z)
    if (length < 1e-9) return a
    return Vector(x / length, 0.0, z / length)
}

/**
 * Marks points where the outline's outward direction bends sharply on both sides, like the
 * corner column of an unrotated box or of a cliff cut. Corners recovered between columns
 * arrive already marked by [cornerBetween].
 */
private fun markCornerApexes(points: List<GroundOutlinePoint>): List<GroundOutlinePoint> {
    if (points.size < 3) return points
    return points.mapIndexed { index, point ->
        if (point.corner || point.outward == Vector.ZERO) return@mapIndexed point
        val previous = points[(index + points.size - 1) % points.size].outward
        val next = points[(index + 1) % points.size].outward
        if (previous == Vector.ZERO || next == Vector.ZERO) return@mapIndexed point
        val bendsBefore = previous.x * point.outward.x + previous.z * point.outward.z <= CORNER_APEX_COSINE
        val bendsAfter = next.x * point.outward.x + next.z * point.outward.z <= CORNER_APEX_COSINE
        if (bendsBefore && bendsAfter) point.copy(corner = true) else point
    }
}

private data class ColumnSample(val surfaceY: Double, val inside: Boolean)

/** An outline point plus whether it sits on the footprint silhouette or a terrain break. */
private class OutlineSample(val point: GroundOutlinePoint, val onSilhouette: Boolean)

private class SilhouetteProjection(val local: Vector, val outwardLocal: Vector)

/**
 * Moves an outline point from its block column center onto the footprint silhouette, kept
 * [SILHOUETTE_INSET] inside so the point's column stays part of the footprint. Points deep
 * inside the footprint mark a terrain break, not the silhouette, and stay where they are;
 * so does any point whose projection cannot be draped back onto valid ground.
 */
private fun refineOntoSilhouette(
    point: GroundOutlinePoint,
    shape: Shape,
    transform: ResolvedTransform,
    terrain: GroundTerrain,
    scanTop: Int,
    scanBottom: Int,
): OutlineSample {
    val local = transform.toLocal(point.position)
    if (shape.signedDistanceHorizontal(local) <= -DEEP_INSIDE) return OutlineSample(point, onSilhouette = false)

    val projection = projectToSilhouette(local, shape) ?: return OutlineSample(point, onSilhouette = false)
    val target = transform.toWorld(projection.local)
    val movedX = target.x - point.position.x
    val movedZ = target.z - point.position.z
    if (movedX * movedX + movedZ * movedZ > MAX_REFINE_DISTANCE * MAX_REFINE_DISTANCE) {
        return OutlineSample(point, onSilhouette = false)
    }

    val sameColumn = floor(target.x).toInt() == floor(point.position.x).toInt() &&
            floor(target.z).toInt() == floor(point.position.z).toInt()
    val y = if (sameColumn) {
        point.position.y
    } else {
        val surface = drapedSurfaceY(shape, transform, terrain, target.x, target.z, scanTop, scanBottom)
            ?: return OutlineSample(point, onSilhouette = false)
        surface + SURFACE_LIFT
    }

    val outward = worldOutward(transform, projection.outwardLocal) ?: point.outward
    return OutlineSample(GroundOutlinePoint(Vector(target.x, y, target.z), outward), onSilhouette = true)
}

/**
 * Newton projection in the local XZ plane onto the [SILHOUETTE_INSET] level of the shape's
 * horizontal signed distance, with a numeric gradient. `null` when the gradient vanishes
 * or the iterations do not converge, like at the exact center of a symmetric shape.
 */
private fun projectToSilhouette(local: Vector, shape: Shape): SilhouetteProjection? {
    var x = local.x
    var z = local.z
    var outwardX = 0.0
    var outwardZ = 0.0
    repeat(PROJECTION_ITERATIONS) {
        val distance = shape.signedDistanceHorizontal(Vector(x, local.y, z))
        // Central differences: a one sided difference reads zero on the inside of a
        // min of faces distance whenever the step moves away from the nearest face.
        val gradientX = shape.signedDistanceHorizontal(Vector(x + GRADIENT_EPSILON, local.y, z)) -
                shape.signedDistanceHorizontal(Vector(x - GRADIENT_EPSILON, local.y, z))
        val gradientZ = shape.signedDistanceHorizontal(Vector(x, local.y, z + GRADIENT_EPSILON)) -
                shape.signedDistanceHorizontal(Vector(x, local.y, z - GRADIENT_EPSILON))
        val length = sqrt(gradientX * gradientX + gradientZ * gradientZ)
        if (length < 1e-9) return null
        outwardX = gradientX / length
        outwardZ = gradientZ / length
        val step = distance + SILHOUETTE_INSET
        x -= outwardX * step
        z -= outwardZ * step
    }
    if (abs(
            shape.signedDistanceHorizontal(
                Vector(
                    x,
                    local.y,
                    z
                )
            ) + SILHOUETTE_INSET
        ) > PROJECTION_TOLERANCE
    ) return null
    return SilhouetteProjection(Vector(x, local.y, z), Vector(outwardX, 0.0, outwardZ))
}

/**
 * Where the outward direction bends sharply between two neighboring silhouette points, the
 * silhouette turns a corner between them whose own block column sampled as outside, like
 * the tip of a rotated cuboid. The corner is recovered as the intersection of the two edge
 * lines and draped onto the terrain, so every corner of the footprint gets a point. When a
 * sample already sits on the recovered corner, that sample is marked as the corner instead
 * of inserting a duplicate next to it.
 */
private fun insertSilhouetteCorners(
    samples: List<OutlineSample>,
    shape: Shape,
    transform: ResolvedTransform,
    terrain: GroundTerrain,
    scanTop: Int,
    scanBottom: Int,
): List<GroundOutlinePoint> {
    if (samples.size < 2) return samples.map { it.point }

    val result = mutableListOf<GroundOutlinePoint>()
    var flagNext = false
    for (index in samples.indices) {
        var point = samples[index].point
        if (flagNext) {
            point = point.copy(corner = true)
            flagNext = false
        }
        val next = samples[(index + 1) % samples.size]
        val corner = cornerBetween(samples[index], next, shape, transform, terrain, scanTop, scanBottom)
        when {
            corner == null -> result += point

            horizontalDistanceSquared(corner.position, point.position) <
                    MIN_CORNER_SEPARATION * MIN_CORNER_SEPARATION -> result += point.copy(corner = true)

            horizontalDistanceSquared(corner.position, next.point.position) <
                    MIN_CORNER_SEPARATION * MIN_CORNER_SEPARATION -> {
                result += point
                flagNext = true
            }

            else -> {
                result += point
                result += corner
            }
        }
    }
    if (flagNext) result[0] = result[0].copy(corner = true)
    return result
}

private fun cornerBetween(
    first: OutlineSample,
    second: OutlineSample,
    shape: Shape,
    transform: ResolvedTransform,
    terrain: GroundTerrain,
    scanTop: Int,
    scanBottom: Int,
): GroundOutlinePoint? {
    if (!first.onSilhouette || !second.onSilhouette) return null
    val a = first.point
    val b = second.point
    if (horizontalDistanceSquared(a.position, b.position) > CORNER_GAP_MAX * CORNER_GAP_MAX) return null

    val n1 = a.outward
    val n2 = b.outward
    if (n1 == Vector.ZERO || n2 == Vector.ZERO) return null
    if (n1.x * n2.x + n1.z * n2.z > CORNER_BEND_COSINE) return null

    // The edge through each point is the line x·n = p·n; the corner is where the two meet.
    val determinant = n1.x * n2.z - n1.z * n2.x
    if (abs(determinant) < 1e-6) return null
    val c1 = n1.x * a.position.x + n1.z * a.position.z
    val c2 = n2.x * b.position.x + n2.z * b.position.z
    val cornerX = (c1 * n2.z - c2 * n1.z) / determinant
    val cornerZ = (n1.x * c2 - n2.x * c1) / determinant

    val corner = Vector(cornerX, a.position.y, cornerZ)
    val fromFirst = horizontalDistanceSquared(corner, a.position)
    val fromSecond = horizontalDistanceSquared(corner, b.position)
    if (fromFirst > CORNER_GAP_MAX * CORNER_GAP_MAX || fromSecond > CORNER_GAP_MAX * CORNER_GAP_MAX) return null

    val local = transform.toLocal(corner)
    if (abs(shape.signedDistanceHorizontal(local) + SILHOUETTE_INSET) > PROJECTION_TOLERANCE) return null

    val surface = drapedSurfaceY(shape, transform, terrain, cornerX, cornerZ, scanTop, scanBottom) ?: return null
    val outward = averageOutward(n1, n2) ?: return null
    return GroundOutlinePoint(Vector(cornerX, surface + SURFACE_LIFT, cornerZ), outward, corner = true)
}

/**
 * The walkable surface under the exact position, checked to actually lie inside the
 * region. `null` for unloaded chunks, columns without a surface in the scan span, and
 * surfaces the region does not reach.
 */
private fun drapedSurfaceY(
    shape: Shape,
    transform: ResolvedTransform,
    terrain: GroundTerrain,
    x: Double,
    z: Double,
    scanTop: Int,
    scanBottom: Int,
): Double? {
    val columnX = floor(x).toInt()
    val columnZ = floor(z).toInt()
    if (!terrain.isColumnLoaded(columnX, columnZ)) return null
    val surface = groundSurfaceY(terrain, columnX, columnZ, scanTop, scanBottom) ?: return null
    if (!shape.contains(transform.toLocal(Vector(x, surface + PROBE_HEIGHT, z)))) return null
    return surface
}

private fun worldOutward(transform: ResolvedTransform, outwardLocal: Vector): Vector? {
    val rotated = transform.rotateLocalToWorld(outwardLocal)
    val length = sqrt(rotated.x * rotated.x + rotated.z * rotated.z)
    if (length < 1e-9) return null
    return Vector(rotated.x / length, 0.0, rotated.z / length)
}

private fun averageOutward(first: Vector, second: Vector): Vector? {
    val x = first.x + second.x
    val z = first.z + second.z
    val length = sqrt(x * x + z * z)
    if (length < 1e-9) return null
    return Vector(x / length, 0.0, z / length)
}

private fun horizontalDistanceSquared(a: Vector, b: Vector): Double {
    val dx = a.x - b.x
    val dz = a.z - b.z
    return dx * dx + dz * dz
}

private val OUTSIDE_FOOTPRINT = ColumnSample(0.0, inside = false)

private val NEIGHBOR_STEPS = listOf(1 to 0, -1 to 0, 0 to 1, 0 to -1)

private const val SURFACE_LIFT = 0.05
private const val PROBE_HEIGHT = 0.1
private const val MAX_COLUMNS = 4096.0
private const val DEEP_INSIDE = 1.0
private const val SILHOUETTE_INSET = 0.05
private const val PROJECTION_ITERATIONS = 3
private const val GRADIENT_EPSILON = 0.01
private const val PROJECTION_TOLERANCE = 0.15
private const val MAX_REFINE_DISTANCE = 1.5
private const val CORNER_GAP_MAX = 3.0
private const val CORNER_BEND_COSINE = 0.87
private const val MIN_CORNER_SEPARATION = 0.3
private const val CORNER_APEX_COSINE = 0.9
private const val RESAMPLE_BREAK = 2.0
private const val MIN_RESAMPLE_SPACING = 0.5
private const val MAX_CHORD_CORRECTION = 0.5

private fun strideFor(footprintColumns: Long): Int =
    max(1.0, ceil(sqrt(footprintColumns / MAX_COLUMNS))).toInt()

private fun sampleColumn(
    shape: Shape,
    transform: ResolvedTransform,
    terrain: GroundTerrain,
    x: Int,
    z: Int,
    scanTop: Int,
    scanBottom: Int,
): ColumnSample? {
    if (!terrain.isColumnLoaded(x, z)) return null
    val surface = groundSurfaceY(terrain, x, z, scanTop, scanBottom)
        ?: return ColumnSample(0.0, inside = false)
    val local = transform.toLocal(Vector(x + 0.5, surface + PROBE_HEIGHT, z + 0.5))
    return ColumnSample(surface, shape.contains(local))
}

/**
 * The top of the lowest solid block with a non solid block above, within the scan span.
 * The lowest walkable surface is the ground the player actually walks on: anything solid
 * higher in the region's vertical span, like a tree canopy, an overhang or a roof, sits
 * above the ground and must not capture the line.
 */
private fun groundSurfaceY(terrain: GroundTerrain, x: Int, z: Int, scanTop: Int, scanBottom: Int): Double? {
    // A region's vertical span is whatever a builder drew, often hundreds of blocks of open air
    // above the terrain. The heightmap bounds the walk to the ground below it.
    val highest = terrain.highestBlockY(x, z)
    if (highest < scanBottom) return null
    val top = min(scanTop, highest)

    var solid = terrain.isSolid(x, scanBottom, z)
    for (y in scanBottom until top) {
        val aboveSolid = terrain.isSolid(x, y + 1, z)
        if (solid && !aboveSolid) return y + 1.0
        solid = aboveSolid
    }
    val aboveTop = top + 1 <= terrain.maxHeight - 1 && terrain.isSolid(x, top + 1, z)
    if (solid && !aboveTop) return top + 1.0
    return null
}

private fun packColumn(x: Int, z: Int): Long = (x.toLong() shl 32) or (z.toLong() and 0xFFFFFFFFL)

private fun unpackColumnX(key: Long): Int = (key shr 32).toInt()

private fun unpackColumnZ(key: Long): Int = key.toInt()
