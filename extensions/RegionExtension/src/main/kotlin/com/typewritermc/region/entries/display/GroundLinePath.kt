package com.typewritermc.region.entries.display

import com.typewritermc.core.utils.point.Vector
import kotlin.math.hypot

internal const val ANIMATION_PATH_STEP = 1.0

/** Where the outline is walkable by arc length, and never bridged across a hole. */
private const val HOLE_THRESHOLD = 2.0

/** A vertex of the ground line: where it is, which way is out, and which way the loop runs. */
data class PathPoint(val position: Vector, val outward: Vector, val tangent: Vector)

/**
 * The ground outline as a closed loop that can be walked by arc length: a point every
 * [ANIMATION_PATH_STEP] blocks, cumulative distances, and the direction the loop winds. An
 * animated line needs all three.
 *
 * Stretches longer than [HOLE_THRESHOLD] are holes, where the line left the terrain or ran into
 * an unloaded chunk. [pointAt] returns `null` inside one, so no point is placed across a gap.
 *
 * The type is public so [GroundLineAnimation] and [GroundLineFacing], which are public for the
 * web panel, can take it in their signatures; the constructor stays module internal, built only
 * by [GroundOutlineCache].
 */
class GroundLinePath internal constructor(points: List<GroundOutlinePoint>) {
    val vertices: List<PathPoint> = buildVertices(points)
    private val arcs: DoubleArray = DoubleArray(vertices.size)
    private val holes: BooleanArray = BooleanArray(vertices.size)
    val totalArc: Double

    /** The distance along the loop at which vertex [index] sits. */
    fun arcOf(index: Int): Double = arcs[index]

    /** `1` when walking the vertices in order runs clockwise seen from above, `-1` otherwise. */
    val clockwiseDirection: Int = windingOf(vertices)

    init {
        var arc = 0.0
        for (index in vertices.indices) {
            arcs[index] = arc
            val next = vertices[(index + 1) % vertices.size].position
            val length = horizontalDistance(vertices[index].position, next)
            holes[index] = length > HOLE_THRESHOLD
            arc += length
        }
        totalArc = arc
    }

    /**
     * The point [arc] blocks along the loop from its first vertex, or `null` when that lands
     * strictly inside a hole. A hole only blocks its interior; the vertex that starts it is
     * still a real point. Negative and overlong distances wrap.
     */
    fun pointAt(arc: Double): PathPoint? {
        if (vertices.size < 2 || totalArc < 1e-6) return vertices.firstOrNull()
        val target = arc.mod(totalArc)

        // Binary search, not a scan: every entity on the line looks its position up every tick.
        val found = arcs.binarySearch(target)
        val index = if (found >= 0) found else (-found - 2).coerceAtLeast(0)

        val start = vertices[index]
        val end = vertices[(index + 1) % vertices.size]
        val segment = horizontalDistance(start.position, end.position)
        if (segment < 1e-9) return start
        val fraction = ((target - arcs[index]) / segment).coerceIn(0.0, 1.0)
        if (fraction <= 0.0) return start
        if (holes[index]) return null

        return PathPoint(
            position = start.position + (end.position - start.position) * fraction,
            outward = lerpDirection(start.outward, end.outward, fraction),
            tangent = lerpDirection(start.tangent, end.tangent, fraction),
        )
    }
}

private fun buildVertices(points: List<GroundOutlinePoint>): List<PathPoint> {
    if (points.isEmpty()) return emptyList()
    if (points.size == 1) return listOf(PathPoint(points[0].position, points[0].outward, Vector.ZERO))
    if (points.size == 2) return buildTwoPointVertices(points)

    return points.mapIndexed { index, point ->
        val previous = points[(index + points.size - 1) % points.size].position
        val next = points[(index + 1) % points.size].position
        val tangent = Vector(next.x - previous.x, 0.0, next.z - previous.z).normalize()
        PathPoint(point.position, point.outward, tangent)
    }
}

/** With only two points the loop doubles back on itself, so both vertices share one tangent. */
private fun buildTwoPointVertices(points: List<GroundOutlinePoint>): List<PathPoint> {
    val (first, second) = points
    val tangent = Vector(second.position.x - first.position.x, 0.0, second.position.z - first.position.z).normalize()
    return listOf(
        PathPoint(first.position, first.outward, tangent),
        PathPoint(second.position, second.outward, tangent),
    )
}

/**
 * The winding of the loop from the sign of its shoelace sum over the XZ plane. Seen from above,
 * with X running east and Z running south, a positive sum walks clockwise.
 */
private fun windingOf(vertices: List<PathPoint>): Int {
    if (vertices.size < 3) return 1
    var sum = 0.0
    for (index in vertices.indices) {
        val current = vertices[index].position
        val next = vertices[(index + 1) % vertices.size].position
        sum += current.x * next.z - next.x * current.z
    }
    return if (sum >= 0.0) 1 else -1
}

private fun lerpDirection(from: Vector, to: Vector, fraction: Double): Vector {
    if (from == Vector.ZERO) return to
    if (to == Vector.ZERO) return from
    val lerped = from + (to - from) * fraction
    if (lerped.length < 1e-9) return from
    return lerped.normalize()
}

private fun horizontalDistance(from: Vector, to: Vector): Double = hypot(to.x - from.x, to.z - from.z)
