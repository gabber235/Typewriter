package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin

/**
 * A polyline tracing a characteristic edge of a shape, in local coordinates. Closed
 * polylines connect the last point back to the first.
 */
data class OutlinePolyline(val points: List<Vector>, val closed: Boolean) {
    init {
        require(points.size >= 2) { "An outline polyline needs at least two points, got ${points.size}" }
    }

    /** The polyline as segment pairs, including the closing segment for closed polylines. */
    fun segments(): List<Pair<Vector, Vector>> {
        val result = ArrayList<Pair<Vector, Vector>>(points.size)
        for (index in 0 until points.size - 1) {
            result += points[index] to points[index + 1]
        }
        if (closed) result += points.last() to points.first()
        return result
    }
}

/**
 * The characteristic edges of the shape: box edges, silhouette rings, cone generatrices,
 * polygon prism edges. Editor outlines and command visualizations render these as solid
 * lines so the shape reads at a glance, where surface samples alone stay ambiguous.
 *
 * [circleSegments] is the resolution of full rings; arcs use a proportional share.
 */
fun Shape.outlinePolylines(circleSegments: Int = 24): List<OutlinePolyline> = when (this) {
    is CuboidShape -> cuboidOutline(halfX, halfY, halfZ)
    is SphereShape -> axisRings(radius, radius, radius, circleSegments)
    is EllipsoidShape -> axisRings(radiusX, radiusY, radiusZ, circleSegments)
    is CapsuleShape -> capsuleOutline(radius, halfHeight, circleSegments)
    is ConeShape -> coneOutline(length, halfAngleDegrees, circleSegments)
    is PolygonShape -> polygonOutline(points, halfHeight)
}

private fun cuboidOutline(halfX: Double, halfY: Double, halfZ: Double): List<OutlinePolyline> {
    fun rect(y: Double) = OutlinePolyline(
        listOf(
            Vector(-halfX, y, -halfZ),
            Vector(halfX, y, -halfZ),
            Vector(halfX, y, halfZ),
            Vector(-halfX, y, halfZ),
        ),
        closed = true,
    )

    val verticals = listOf(-halfX to -halfZ, halfX to -halfZ, halfX to halfZ, -halfX to halfZ).map { (x, z) ->
        OutlinePolyline(listOf(Vector(x, -halfY, z), Vector(x, halfY, z)), closed = false)
    }
    return listOf(rect(-halfY), rect(halfY)) + verticals
}

/**
 * The three axis plane rings of an ellipsoid (or sphere, with equal radii): the XZ equator
 * and the XY and YZ meridians.
 */
private fun axisRings(radiusX: Double, radiusY: Double, radiusZ: Double, circleSegments: Int): List<OutlinePolyline> {
    if (radiusX <= 0.0 || radiusY <= 0.0 || radiusZ <= 0.0) return emptyList()
    fun ring(point: (angle: Double) -> Vector) = OutlinePolyline(
        List(circleSegments) { index -> point(2.0 * PI * index / circleSegments) },
        closed = true,
    )
    return listOf(
        ring { angle -> Vector(cos(angle) * radiusX, 0.0, sin(angle) * radiusZ) },
        ring { angle -> Vector(cos(angle) * radiusX, sin(angle) * radiusY, 0.0) },
        ring { angle -> Vector(0.0, sin(angle) * radiusY, cos(angle) * radiusZ) },
    )
}

/**
 * Two rings where the cylinder meets the hemispheres, and two stadium shaped profile loops
 * through the XY and ZY planes.
 */
private fun capsuleOutline(radius: Double, halfHeight: Double, circleSegments: Int): List<OutlinePolyline> {
    if (radius <= 0.0) return emptyList()
    val arcSegments = (circleSegments / 2).coerceAtLeast(4)

    fun ring(y: Double) = OutlinePolyline(
        List(circleSegments) { index ->
            val angle = 2.0 * PI * index / circleSegments
            Vector(cos(angle) * radius, y, sin(angle) * radius)
        },
        closed = true,
    )

    fun profile(point: (x: Double, y: Double) -> Vector): OutlinePolyline {
        val loop = mutableListOf(point(radius, -halfHeight))
        loop += point(radius, halfHeight)
        for (index in 1..arcSegments) {
            val angle = PI * index / arcSegments
            loop += point(cos(angle) * radius, halfHeight + sin(angle) * radius)
        }
        loop += point(-radius, -halfHeight)
        for (index in 1 until arcSegments) {
            val angle = PI + PI * index / arcSegments
            loop += point(cos(angle) * radius, -halfHeight - sin(angle - PI) * radius)
        }
        return OutlinePolyline(loop, closed = true)
    }

    return listOf(
        ring(halfHeight),
        ring(-halfHeight),
        profile { x, y -> Vector(x, y, 0.0) },
        profile { x, y -> Vector(0.0, y, x) },
    )
}

/**
 * The rim ring where the lateral surface meets the spherical cap, generatrix lines from
 * the apex to the rim, and two profile arcs over the cap. The generatrices make the cone's
 * direction and reach followable at a glance.
 */
private fun coneOutline(length: Double, halfAngleDegrees: Double, circleSegments: Int): List<OutlinePolyline> {
    if (length <= 0.0 || halfAngleDegrees <= 0.0) return emptyList()
    val halfAngle = Math.toRadians(halfAngleDegrees)
    val rimRadius = length * sin(halfAngle)
    val rimZ = length * cos(halfAngle)

    fun rimPoint(angle: Double) = Vector(cos(angle) * rimRadius, sin(angle) * rimRadius, rimZ)

    val rim =
        OutlinePolyline(List(circleSegments) { index -> rimPoint(2.0 * PI * index / circleSegments) }, closed = true)
    val generatrices = List(CONE_GENERATRIX_LINES) { index ->
        val angle = 2.0 * PI * index / CONE_GENERATRIX_LINES
        OutlinePolyline(listOf(Vector.ZERO, rimPoint(angle)), closed = false)
    }

    val arcSegments = (circleSegments / 2).coerceAtLeast(4)
    fun capArc(point: (lateral: Double, z: Double) -> Vector) = OutlinePolyline(
        List(arcSegments + 1) { index ->
            val angle = -halfAngle + 2.0 * halfAngle * index / arcSegments
            point(length * sin(angle), length * cos(angle))
        },
        closed = false,
    )

    return listOf(rim) + generatrices + listOf(
        capArc { lateral, z -> Vector(lateral, 0.0, z) },
        capArc { lateral, z -> Vector(0.0, lateral, z) },
    )
}

private fun polygonOutline(points: List<Vector>, halfHeight: Double): List<OutlinePolyline> {
    if (points.size < 3) return emptyList()
    fun ring(y: Double) = OutlinePolyline(points.map { Vector(it.x, y, it.z) }, closed = true)
    val verticals = points.map {
        OutlinePolyline(listOf(Vector(it.x, -halfHeight, it.z), Vector(it.x, halfHeight, it.z)), closed = false)
    }
    return listOf(ring(-halfHeight), ring(halfHeight)) + verticals
}

private const val CONE_GENERATRIX_LINES = 8
