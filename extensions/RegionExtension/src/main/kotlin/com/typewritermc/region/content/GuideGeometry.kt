package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.region.shape.LocalBounds
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

internal const val GUIDE_THICKNESS = 0.16f

/** Beyond this distance from the region origin, the guides anchor near the player instead. */
internal const val GUIDE_NEAR_RANGE = 24.0

/** The axis length used when the guide is anchored at the boundary instead of the origin. */
internal const val FAR_ANCHOR_AXIS_LENGTH = 8.0

/** Far anchored rings only draw the arc within this range of the player. */
internal const val RING_VISIBLE_RANGE = 48.0

private const val AXIS_MARGIN = 1.0
private const val MIN_AXIS_LENGTH = 2.0
private const val MAX_AXIS_LENGTH = 24.0
private const val GUIDE_PIECE_LENGTH = 4.0
private const val ARROW_HEAD_FRACTION = 0.18
private const val MIN_ARROW_HEAD = 0.5
private const val MAX_ARROW_HEAD = 1.5
private const val ARROW_ANGLE_DEGREES = 30.0
private const val PRONG_SNAP_DEGREES = 15.0

private const val RING_MARGIN = 0.5
private const val MIN_RING_RADIUS = 1.25

// The ring is a compact gizmo at the origin, not a hoop around the region: the outline
// already shows the rotation live, so past this radius the ring only gets harder to read.
private const val MAX_NEAR_RING_RADIUS = 8.0
private const val RING_SEGMENT_LENGTH = 3.0
private const val MIN_RING_SEGMENTS = 16
private const val MAX_RING_SEGMENTS = 96

/** The twelve edges of a unit cube, relative to its minimum corner. */
internal val BLOCK_OUTLINE_SEGMENTS: List<Pair<Vector, Vector>> = buildList {
    val axes = listOf(Vector(1.0, 0.0, 0.0), Vector(0.0, 1.0, 0.0), Vector(0.0, 0.0, 1.0))
    for (axis in axes) {
        val (u, v) = axes.filter { it != axis }
        add(Vector.ZERO to axis)
        add(u to u + axis)
        add(v to v + axis)
        add(u + v to u + v + axis)
    }
}

/** The half extent of [bounds] along the world axis [direction] points down. */
internal fun halfExtentAlong(bounds: LocalBounds, direction: Vector): Double {
    val x = (bounds.maxX - bounds.minX) / 2
    val y = (bounds.maxY - bounds.minY) / 2
    val z = (bounds.maxZ - bounds.minZ) / 2
    return when {
        abs(direction.y) > abs(direction.x) && abs(direction.y) > abs(direction.z) -> y
        abs(direction.x) >= abs(direction.z) -> x
        else -> z
    }
}

/**
 * How far the move guide reaches: proportional to the region so a small one gets a small
 * arrow, but never so short that it disappears, nor so long that it stretches out of sight.
 */
internal fun moveAxisLength(bounds: LocalBounds, direction: Vector): Double =
    (halfExtentAlong(bounds, direction) + AXIS_MARGIN)
        .coerceIn(MIN_AXIS_LENGTH, MAX_AXIS_LENGTH)

/**
 * A segment cut into pieces of at most [pieceLength] blocks. Each guide piece gets its own
 * display entity anchored where it is drawn, so a long axis still reaches the client when
 * the player stands at its far end.
 */
internal fun splitGuideSegment(
    from: Vector,
    to: Vector,
    pieceLength: Double = GUIDE_PIECE_LENGTH,
): List<Pair<Vector, Vector>> {
    val count = ceil((to - from).length / pieceLength).toInt().coerceAtLeast(1)
    return (0 until count).map { index ->
        lerp(from, to, index.toDouble() / count) to lerp(from, to, (index + 1).toDouble() / count)
    }
}

/**
 * The direction the arrowhead prongs spread along: perpendicular to the axis, and chosen so
 * the flat arrow faces the viewer looking along [viewDirection]. Snapped to
 * [PRONG_SNAP_DEGREES] steps so the guide does not render again on every step the player takes.
 * Falls back to an arbitrary perpendicular when the view runs along the axis.
 */
internal fun prongBasis(axis: Vector, viewDirection: Vector): Vector {
    val (u, v) = perpendicularBasis(axis)
    val raw = viewDirection.cross(axis)
    if (raw.length < 1e-6) return u
    val angle = atan2(raw.dot(v), raw.dot(u))
    val step = Math.toRadians(PRONG_SNAP_DEGREES)
    val snapped = step * (angle / step).roundToInt()
    return u * cos(snapped) + v * sin(snapped)
}

/**
 * The move guide as anchor relative segments: the axis from the anchor along [direction],
 * split so every piece's display stays near the player, and a flat two pronged arrowhead
 * at the tip, rotated by [viewDirection] (viewer toward tip) so it always faces the player.
 */
internal fun moveGuideSegments(
    bounds: LocalBounds,
    direction: Vector,
    viewDirection: Vector,
    length: Double = moveAxisLength(bounds, direction),
): List<Pair<Vector, Vector>> {
    val axis = direction.normalize()
    val tip = axis * length
    val head = (length * ARROW_HEAD_FRACTION).coerceIn(MIN_ARROW_HEAD, MAX_ARROW_HEAD)
    val angle = Math.toRadians(ARROW_ANGLE_DEGREES)
    val back = axis * (-cos(angle) * head)
    val spread = sin(angle) * head
    val side = prongBasis(axis, viewDirection)

    val prongs = listOf(side * spread, side * -spread).map { offset ->
        tip to (tip + back + offset)
    }
    return splitGuideSegment(Vector.ZERO, tip) + prongs
}

internal const val PUSH_AXIS_REACH = 1.5

private val POINT_BOUNDS = LocalBounds(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

/**
 * The push axis of a selected polygon point: a line through the point along [direction],
 * with the arrowhead on the push end only, so the bare tail marks the pull direction.
 * [viewDirection] turns the flat arrowhead toward the viewer, like the move guide's.
 */
internal fun pushAxisSegments(
    direction: Vector,
    viewDirection: Vector,
    reach: Double = PUSH_AXIS_REACH,
): List<Pair<Vector, Vector>> =
    listOf(direction * -reach to Vector.ZERO) +
            moveGuideSegments(POINT_BOUNDS, direction, viewDirection, reach)

/** The radius of the rotation ring: hugging a small region, capped to a compact gizmo. */
internal fun rotationRingRadius(bounds: LocalBounds, pitchPlane: Boolean): Double {
    val horizontal = maxOf(bounds.maxX - bounds.minX, bounds.maxZ - bounds.minZ) / 2
    val vertical = (bounds.maxY - bounds.minY) / 2
    val extent = if (pitchPlane) maxOf(horizontal, vertical) else horizontal
    return (extent + RING_MARGIN).coerceIn(MIN_RING_RADIUS, MAX_NEAR_RING_RADIUS)
}

/**
 * The radius of a far anchored rotation ring. It passes through the player while they are
 * inside the region, tracing the arc their own spot would sweep, but it never grows past
 * the region's reach in the ring's plane: outside the region that arc says nothing about
 * the rotation, so the ring falls back to the border radius. The near gizmo radius is the
 * floor, which also keeps the ring drawable for a player standing on the rotation axis.
 */
internal fun farRingRadius(bounds: LocalBounds, playerDistance: Double, pitchPlane: Boolean): Double {
    val lower = rotationRingRadius(bounds, pitchPlane)
    val upper = (planarReach(bounds, pitchPlane) + RING_MARGIN).coerceAtLeast(lower)
    return playerDistance.coerceIn(lower, upper)
}

/** The farthest [bounds] reaches from the anchor within the ring's plane. */
private fun planarReach(bounds: LocalBounds, pitchPlane: Boolean): Double {
    val x = maxOf(abs(bounds.minX), abs(bounds.maxX))
    val y = maxOf(abs(bounds.minY), abs(bounds.maxY))
    val z = maxOf(abs(bounds.minZ), abs(bounds.maxZ))
    val radial = if (pitchPlane) y else x
    return sqrt(radial * radial + z * z)
}

/** The center of [bounds], as an offset from the region anchor the guides hang on. */
internal fun boundsCenter(bounds: LocalBounds): Vector = Vector(
    (bounds.minX + bounds.maxX) / 2,
    (bounds.minY + bounds.maxY) / 2,
    (bounds.minZ + bounds.maxZ) / 2,
)

/**
 * The tilt facing quantized to the region's own frame: whichever of the region's four
 * horizontal cardinals (its yaw rotated forward and sideways axes, either way along each)
 * lies nearest the viewer's direction toward the region, given as ([dx], [dz]). A tilt is
 * then always a clean pitch or a clean roll of the region instead of a diagonal mix, and
 * the dial only renders again when the player crosses into another quadrant. A viewer right
 * above the center gets the region's own facing.
 */
internal fun quantizedTiltFacing(dx: Double, dz: Double, yawDegrees: Float): Vector {
    val yaw = Math.toRadians(yawDegrees.toDouble())
    val forward = Vector(-sin(yaw), 0.0, cos(yaw))
    val sideways = Vector(cos(yaw), 0.0, sin(yaw))
    return listOf(forward, forward * -1.0, sideways, sideways * -1.0)
        .maxBy { it.x * dx + it.z * dz }
}

/**
 * Steps the stored tilt angles by [deltaDegrees] in the plane the quantized [facing]
 * selects: pitch when the viewer looks along the region's forward axis, roll from the
 * flanks. A positive delta always tips the region's top away from the viewer. The angles
 * step directly so every tilt stays a clean pitch or roll; composing the rotation in
 * world space and decomposing it back would smear one step across all three angles once
 * the region is already rotated. Returns the new pitch and roll.
 */
internal fun steppedTilt(
    pitchDegrees: Float,
    rollDegrees: Float,
    facing: Vector,
    yawDegrees: Float,
    deltaDegrees: Float,
): Pair<Float, Float> {
    val yaw = Math.toRadians(yawDegrees.toDouble())
    val along = -sin(yaw) * facing.x + cos(yaw) * facing.z
    val across = cos(yaw) * facing.x + sin(yaw) * facing.z
    if (abs(along) >= abs(across)) {
        val step = if (along >= 0.0) deltaDegrees else -deltaDegrees
        return normalizeDegrees(pitchDegrees + step) to rollDegrees
    }
    val step = if (across >= 0.0) -deltaDegrees else deltaDegrees
    return pitchDegrees to normalizeDegrees(rollDegrees + step)
}

/** How many segments a ring of [radius] needs for its chords to stay near [RING_SEGMENT_LENGTH]. */
internal fun ringSegmentCount(radius: Double): Int =
    ceil(2.0 * Math.PI * radius / RING_SEGMENT_LENGTH).toInt().coerceIn(MIN_RING_SEGMENTS, MAX_RING_SEGMENTS)

/**
 * A ring of [ringSegmentCount] chords in the plane spanned by [uBasis] and [vBasis], offset
 * by [planeOffset] from the anchor. The bases carry the caller's frame, so the same builder
 * serves the world aligned yaw ring and the region rotated pitch ring.
 */
internal fun ringSegments(
    radius: Double,
    planeOffset: Vector,
    uBasis: Vector,
    vBasis: Vector,
): List<Pair<Vector, Vector>> {
    val count = ringSegmentCount(radius)
    val points = (0 until count).map { index ->
        val angle = 2.0 * Math.PI * index / count
        planeOffset + uBasis * (sin(angle) * radius) + vBasis * (cos(angle) * radius)
    }
    return points.indices.map { points[it] to points[(it + 1) % points.size] }
}

/** The segments whose midpoint lies within [range] of [viewerOffset] (both anchor relative). */
internal fun cullSegmentsNear(
    segments: List<Pair<Vector, Vector>>,
    viewerOffset: Vector,
    range: Double = RING_VISIBLE_RANGE,
): List<Pair<Vector, Vector>> {
    val limit = range * range
    return segments.filter { (from, to) ->
        (lerp(from, to, 0.5) - viewerOffset).lengthSquared <= limit
    }
}

private fun lerp(from: Vector, to: Vector, fraction: Double): Vector = from + (to - from) * fraction

/**
 * The marked block the view ray passes through, nearest along the ray. The cubes are
 * inflated a touch so aiming at a point does not demand pixel precision, and terrain is
 * ignored on purpose: outline points usually sit inside walls, where the clicked block
 * can never reach them.
 */
internal fun pickHoveredBlock(
    blocks: List<CapturedBlock>,
    worldId: String,
    eye: Vector,
    direction: Vector,
    range: Double,
): CapturedBlock? {
    var best: CapturedBlock? = null
    var bestEntry = Double.MAX_VALUE
    for (block in blocks) {
        if (block.world.identifier != worldId) continue
        val entry = rayCubeEntry(block, eye, direction) ?: continue
        if (entry > range || entry >= bestEntry) continue
        bestEntry = entry
        best = block
    }
    return best
}

/**
 * Distance along the ray to where it enters the block's inflated cube, `0.0` when the eye
 * is already inside it, or `null` when the ray misses.
 */
private fun rayCubeEntry(block: CapturedBlock, eye: Vector, direction: Vector): Double? {
    var entry = 0.0
    var exit = Double.MAX_VALUE
    for (axis in 0..2) {
        val origin = when (axis) {
            0 -> eye.x
            1 -> eye.y
            else -> eye.z
        }
        val dir = when (axis) {
            0 -> direction.x
            1 -> direction.y
            else -> direction.z
        }
        val low = when (axis) {
            0 -> block.x
            1 -> block.y
            else -> block.z
        } - HOVER_INFLATE
        val high = low + 1.0 + 2 * HOVER_INFLATE
        if (abs(dir) < Vector.EPSILON) {
            if (origin < low || origin > high) return null
            continue
        }
        val near = (low - origin) / dir
        val far = (high - origin) / dir
        entry = maxOf(entry, minOf(near, far))
        exit = minOf(exit, maxOf(near, far))
        if (entry > exit) return null
    }
    return entry
}

private const val HOVER_INFLATE = 0.1

/** How close the aim must come to a corner edge to acquire it, and to keep it once selected. */
internal const val VERTEX_PICK_RADIUS = 0.4
internal const val VERTEX_KEEP_RADIUS = 0.65

/**
 * The closest approach between the view ray `eye + t * direction`, `t >= 0`, and the
 * segment from [a] to [b]: the distance and the ray parameter at that point. [direction]
 * must be unit length.
 */
internal fun raySegmentDistance(eye: Vector, direction: Vector, a: Vector, b: Vector): Pair<Double, Double> {
    val v = b - a
    val w = eye - a
    val vv = v.dot(v)
    val uv = direction.dot(v)
    val uw = direction.dot(w)
    val vw = w.dot(v)
    val denominator = vv - uv * uv
    var s = when {
        vv < 1e-12 -> 0.0
        abs(denominator) < 1e-9 -> (vw / vv).coerceIn(0.0, 1.0)
        else -> ((vw - uw * uv) / denominator).coerceIn(0.0, 1.0)
    }
    val t = (s * uv - uw).coerceAtLeast(0.0)
    if (vv >= 1e-12) s = ((w + direction * t).dot(v) / vv).coerceIn(0.0, 1.0)
    val offset = w + direction * t - v * s
    return offset.length to t
}

/**
 * The corner whose vertical edge the view ray passes closest to, straight through terrain.
 * [preferredIndex] adds hysteresis, mirroring [pickFace]: the already selected corner wins
 * while it is still a full hit within [VERTEX_PICK_RADIUS]; a clear hit on another corner
 * beats a selection that has drifted into the [VERTEX_KEEP_RADIUS] band; and the band only
 * holds the selection while nothing else qualifies, so the pick neither flickers at the
 * acquire boundary nor refuses a corner the player is now aiming dead at.
 */
internal fun pickVertexEdge(
    edges: List<Pair<Vector, Vector>>,
    eye: Vector,
    direction: Vector,
    range: Double,
    preferredIndex: Int? = null,
): Int? {
    var best: Int? = null
    var bestAlong = Double.MAX_VALUE
    var preferredDistance = Double.MAX_VALUE
    for ((index, edge) in edges.withIndex()) {
        val (distance, along) = raySegmentDistance(eye, direction, edge.first, edge.second)
        if (along > range) continue
        if (index == preferredIndex) preferredDistance = distance
        if (distance > VERTEX_PICK_RADIUS) continue
        if (along < bestAlong) {
            bestAlong = along
            best = index
        }
    }
    if (preferredDistance <= VERTEX_PICK_RADIUS) return preferredIndex
    if (best != null) return best
    if (preferredDistance <= VERTEX_KEEP_RADIUS) return preferredIndex
    return null
}
