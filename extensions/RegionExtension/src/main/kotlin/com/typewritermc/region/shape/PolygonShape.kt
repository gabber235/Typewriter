package com.typewritermc.region.shape

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.core.utils.point.Vector
import kotlin.math.*

/**
 * A vertical prism whose horizontal cross section is the polygon spanned by [points],
 * extruded [halfHeight] blocks up and down from the local origin's Y level.
 *
 * Only the X and Z components of each point are used. Points are relative to the resolved
 * region origin and may be listed in either winding order. The polygon may be concave but
 * must not self intersect.
 *
 * A polygon needs at least three points. With fewer, the shape contains nothing and
 * reports far outside distances instead of failing the page load while the user is still
 * drawing the outline in the editor.
 */
@AlgebraicTypeInfo("polygon_shape", Colors.PURPLE, "mdi:vector-polygon")
data class PolygonShape(
    @Help("Polygon outline points relative to the origin; only X and Z are used. Needs at least 3.")
    val points: List<Vector> = emptyList(),
    @Min(0)
    @Help("Half the prism's height in blocks; the prism spans origin Y ± this value.")
    @Default("1.0")
    val halfHeight: Double = 1.0,
) : Shape {
    private val degenerate: Boolean get() = points.size < 3

    // Points in a straight line pass the count and still enclose nothing, which the area catches.
    override val usable: Boolean get() = !degenerate && halfHeight > 0.0 && twiceCapArea() > EDGE_EPSILON

    override val localBounds: LocalBounds
        get() {
            if (degenerate) return LocalBounds(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
            return LocalBounds(
                points.minOf { it.x }, -halfHeight, points.minOf { it.z },
                points.maxOf { it.x }, halfHeight, points.maxOf { it.z },
            )
        }

    override fun contains(localLoc: Vector): Boolean {
        if (degenerate) return false
        if (abs(localLoc.y) > halfHeight) return false
        return lateralContains(localLoc.x, localLoc.z)
    }

    override fun signedDistance(localLoc: Vector): Double {
        if (degenerate) return FAR_OUTSIDE
        val lateral = closestBoundary2d(localLoc.x, localLoc.z)
        val dy = abs(localLoc.y) - halfHeight
        val inside = min(max(lateral.signedDistance, dy), 0.0)
        val ox = max(lateral.signedDistance, 0.0)
        val oy = max(dy, 0.0)
        return inside + sqrt(ox * ox + oy * oy)
    }

    override fun signedDistanceHorizontal(localLoc: Vector): Double {
        if (degenerate) return FAR_OUTSIDE
        return closestBoundary2d(localLoc.x, localLoc.z).signedDistance
    }

    override fun nearestOutside(localLoc: Vector): Vector {
        // An outline still being drawn has no surface. [signedDistance] answers FAR_OUTSIDE for
        // it, so the nearest point has to be that far away too, or a caller comparing the two
        // sees a surface it can touch.
        if (degenerate) return Vector(localLoc.x, localLoc.y + FAR_OUTSIDE, localLoc.z)
        val lateral = closestBoundary2d(localLoc.x, localLoc.z)
        val dy = abs(localLoc.y) - halfHeight
        val capY = if (localLoc.y >= 0) halfHeight else -halfHeight
        if (lateral.signedDistance <= 0.0 && dy <= 0.0) {
            return if (-lateral.signedDistance <= -dy) Vector(lateral.x, localLoc.y, lateral.z)
            else Vector(localLoc.x, capY, localLoc.z)
        }
        if (lateral.signedDistance <= 0.0) return Vector(localLoc.x, capY, localLoc.z)
        val clampedY = localLoc.y.coerceIn(-halfHeight, halfHeight)
        return Vector(lateral.x, clampedY, lateral.z)
    }

    override fun outwardNormals(localLoc: Vector): List<Vector> {
        if (degenerate) return emptyList()
        // Past the rim the direction away from the closest surface point is the one the barrier
        // and the push want. A wall normal plus a cap normal averages to a fixed 45 degrees,
        // which aims off the prism and swings as the player crosses the plane of either.
        outsideDirection(localLoc)?.let { return listOf(it) }

        val lateral = closestBoundary2d(localLoc.x, localLoc.z)
        val dy = abs(localLoc.y) - halfHeight
        val normals = mutableListOf<Vector>()
        if (dy > -EDGE_EPSILON) {
            normals.add(Vector(0.0, if (localLoc.y >= 0) 1.0 else -1.0, 0.0))
        }
        if (lateral.signedDistance > -EDGE_EPSILON) {
            lateralNormal(localLoc, lateral)?.let(normals::add)
        }
        if (normals.isEmpty()) {
            if (-lateral.signedDistance <= -dy) lateralNormal(localLoc, lateral)?.let(normals::add)
            if (normals.isEmpty()) normals.add(Vector(0.0, if (localLoc.y >= 0) 1.0 else -1.0, 0.0))
        }
        return normals
    }

    /** The unit direction away from the closest surface point, or `null` for a point not outside. */
    private fun outsideDirection(localLoc: Vector): Vector? {
        if (signedDistance(localLoc) <= EDGE_EPSILON) return null
        val offset = localLoc - nearestOutside(localLoc)
        if (offset.length <= EDGE_EPSILON) return null
        return offset.normalize()
    }

    /** The prism's wall plus its two caps. */
    private fun surfaceArea(): Double {
        if (degenerate) return 0.0
        var perimeter = 0.0
        var j = points.size - 1
        for (i in points.indices) {
            val from = points[j]
            val to = points[i]
            perimeter += sqrt((to.x - from.x) * (to.x - from.x) + (to.z - from.z) * (to.z - from.z))
            j = i
        }
        return perimeter * 2.0 * halfHeight + twiceCapArea()
    }

    /** Twice the outline's enclosed area, by the shoelace formula. Zero for a line. */
    private fun twiceCapArea(): Double {
        if (degenerate) return 0.0
        var doubled = 0.0
        var j = points.size - 1
        for (i in points.indices) {
            doubled += points[j].x * points[i].z - points[i].x * points[j].z
            j = i
        }
        return abs(doubled)
    }

    /**
     * Samples the walls in evenly divided columns whose rows land exactly on the top and
     * bottom edges, then fills the caps with the grid points strictly inside the outline.
     * Each edge's endpoint is the next edge's start and the wall already covers the cap
     * rims, so no sample is emitted twice.
     */
    override fun sampleBoundary(density: Double): Sequence<Vector> {
        if (degenerate) return emptySequence()
        val step = sampleStep(density, surfaceArea())
        return sequence {
            val ys = axisSamples(-halfHeight, halfHeight, step)
            var j = points.size - 1
            for (i in points.indices) {
                val ax = points[j].x
                val az = points[j].z
                val ex = points[i].x - ax
                val ez = points[i].z - az
                val length = sqrt(ex * ex + ez * ez)
                j = i
                if (length < EDGE_EPSILON) continue
                val segments = max(1, ceil(length / step).toInt())
                for (segment in 0 until segments) {
                    val fraction = segment.toDouble() / segments
                    val px = ax + ex * fraction
                    val pz = az + ez * fraction
                    for (y in ys) yield(Vector(px, y, pz))
                }
            }
            val bounds = localBounds
            val xs = axisSamples(bounds.minX, bounds.maxX, step)
            for (z in axisSamples(bounds.minZ, bounds.maxZ, step)) {
                val crossings = rowCrossings(z)
                var pair = 0
                while (pair + 1 < crossings.size) {
                    var index = xs.firstIndexAtLeast(crossings[pair])
                    while (index < xs.size && xs[index] <= crossings[pair + 1]) {
                        val x = xs[index]
                        index++
                        if (closestBoundary2d(x, z).signedDistance >= -CAP_INSET) continue
                        yield(Vector(x, -halfHeight, z))
                        if (halfHeight > 0.0) yield(Vector(x, halfHeight, z))
                    }
                    pair += 2
                }
            }
        }.withinSampleBudget()
    }

    private fun lateralNormal(localLoc: Vector, lateral: LateralHit): Vector? {
        val toPointX = localLoc.x - lateral.x
        val toPointZ = localLoc.z - lateral.z
        val length = sqrt(toPointX * toPointX + toPointZ * toPointZ)
        if (length < EDGE_EPSILON) return wallNormal(lateral)
        val sign = if (lateral.signedDistance >= 0.0) 1.0 else -1.0
        return Vector(sign * toPointX / length, 0.0, sign * toPointZ / length)
    }

    /**
     * The outward perpendicular of the wall [lateral] lies on, for a point standing exactly on
     * it. Winding is not assumed: the side that leaves the outline is found by probing.
     *
     * A corner belongs to both of the edges that meet there, and at a sharp one a single edge's
     * perpendicular runs almost along the other, so it points along the outline rather than out
     * of it. Both edges are averaged there, which gives the bisector.
     */
    private fun wallNormal(lateral: LateralHit): Vector? {
        val corner = points.indexOfFirst {
            abs(it.x - lateral.x) < EDGE_EPSILON && abs(it.z - lateral.z) < EDGE_EPSILON
        }
        if (corner < 0) return edgeNormal(lateral.x, lateral.z, lateral.edgeX, lateral.edgeZ)

        val here = points[corner]
        val previous = neighbourOf(corner, -1) ?: return null
        val next = neighbourOf(corner, 1) ?: return null
        val incoming = edgeNormal(
            (previous.x + here.x) / 2.0, (previous.z + here.z) / 2.0,
            here.x - previous.x, here.z - previous.z,
        )
        val outgoing = edgeNormal(
            (here.x + next.x) / 2.0, (here.z + next.z) / 2.0,
            next.x - here.x, next.z - here.z,
        )
        return averageUnitDirection(listOfNotNull(incoming, outgoing))
    }

    /**
     * The nearest point [step] hops away from [index] that does not sit on the point at [index],
     * or `null` when every point does.
     *
     * The editor lets a builder drop a vertex on one already placed, and the zero length edge that
     * makes has no perpendicular. Taking the listed neighbour regardless leaves a sharp corner with
     * one edge's perpendicular, which is the direction that runs along the outline rather than out
     * of it, and a barrier there pushes a player along the wall instead of off it.
     */
    private fun neighbourOf(index: Int, step: Int): Vector? {
        val here = points[index]
        for (hop in 1 until points.size) {
            val candidate = points[Math.floorMod(index + step * hop, points.size)]
            if (abs(candidate.x - here.x) >= EDGE_EPSILON || abs(candidate.z - here.z) >= EDGE_EPSILON) {
                return candidate
            }
        }
        return null
    }

    /** The outward perpendicular of the edge along ([edgeX], [edgeZ]), probed from ([x], [z]) on it. */
    private fun edgeNormal(x: Double, z: Double, edgeX: Double, edgeZ: Double): Vector? {
        val length = sqrt(edgeX * edgeX + edgeZ * edgeZ)
        if (length < EDGE_EPSILON) return null
        val nx = edgeZ / length
        val nz = -edgeX / length
        val outward = !lateralContains(x + nx * NORMAL_PROBE, z + nz * NORMAL_PROBE)
        return if (outward) Vector(nx, 0.0, nz) else Vector(-nx, 0.0, -nz)
    }

    /**
     * Ray cast parity test in the XZ plane.
     */
    private fun lateralContains(px: Double, pz: Double): Boolean {
        var inside = false
        var j = points.size - 1
        for (i in points.indices) {
            val zi = points[i].z
            val zj = points[j].z
            if ((zi > pz) != (zj > pz) && px < (points[j].x - points[i].x) * (pz - zi) / (zj - zi) + points[i].x) {
                inside = !inside
            }
            j = i
        }
        return inside
    }

    /**
     * The x coordinates where the outline crosses the row at [z], sorted.
     *
     * By the parity rule [lateralContains] uses, the points between the first and the second
     * crossing are inside, as are the points between the third and the fourth, and so on.
     *
     * The cap fill walks these spans rather than the whole bounding box. The sample budget cannot
     * bound that walk: it counts the samples emitted, and a point rejected for being outside the
     * outline is rejected for free. A thin outline lying across its bounding box diagonally rejects
     * nearly everything it tests, which costs a million outline tests per render on a band a
     * thousand blocks long.
     */
    private fun rowCrossings(z: Double): DoubleArray {
        val crossings = DoubleArray(points.size)
        var count = 0
        var j = points.size - 1
        for (i in points.indices) {
            val zi = points[i].z
            val zj = points[j].z
            if ((zi > z) != (zj > z)) {
                crossings[count] = (points[j].x - points[i].x) * (z - zi) / (zj - zi) + points[i].x
                count += 1
            }
            j = i
        }
        return crossings.copyOf(count).also { it.sort() }
    }

    /**
     * The closest point on the polygon outline plus the signed lateral distance, negative
     * when the point is laterally inside. The sign comes from [lateralContains], so it
     * works for both winding orders.
     */
    private fun closestBoundary2d(px: Double, pz: Double): LateralHit {
        var bestDistSq = Double.MAX_VALUE
        var bestX = px
        var bestZ = pz
        var bestEdgeX = 0.0
        var bestEdgeZ = 0.0
        var j = points.size - 1
        for (i in points.indices) {
            val ax = points[j].x
            val az = points[j].z
            val ex = points[i].x - ax
            val ez = points[i].z - az
            val lenSq = ex * ex + ez * ez
            val t = if (lenSq < EDGE_EPSILON) 0.0
            else (((px - ax) * ex + (pz - az) * ez) / lenSq).coerceIn(0.0, 1.0)
            val cx = ax + ex * t
            val cz = az + ez * t
            val dx = px - cx
            val dz = pz - cz
            val distSq = dx * dx + dz * dz
            if (distSq < bestDistSq) {
                bestDistSq = distSq
                bestX = cx
                bestZ = cz
                bestEdgeX = ex
                bestEdgeZ = ez
            }
            j = i
        }
        val distance = sqrt(bestDistSq)
        val signed = if (lateralContains(px, pz)) -distance else distance
        return LateralHit(bestX, bestZ, signed, bestEdgeX, bestEdgeZ)
    }

    /**
     * A point on the outline, its signed distance, and the direction of the wall it lies on.
     *
     * The wall direction is carried because a point sitting exactly on the outline has no
     * direction of its own to normalize, and the wall's own perpendicular is the answer there.
     */
    private data class LateralHit(
        val x: Double,
        val z: Double,
        val signedDistance: Double,
        val edgeX: Double,
        val edgeZ: Double,
    )

    companion object {
        private const val EDGE_EPSILON = 1e-6
        private const val FAR_OUTSIDE = 1.0e9

        /** How far off a wall to probe to find which side of it is outside. */
        private const val NORMAL_PROBE = 1e-4

        /**
         * Cap grid points closer to the outline than this sample as wall points instead,
         * so grid lines that coincide with an axis aligned edge do not double the wall.
         */
        private const val CAP_INSET = 1e-9
    }
}

/** The first index of this sorted list whose value is at least [threshold], or the list's size. */
private fun List<Double>.firstIndexAtLeast(threshold: Double): Int {
    val found = binarySearch(threshold)
    return if (found >= 0) found else -(found + 1)
}
