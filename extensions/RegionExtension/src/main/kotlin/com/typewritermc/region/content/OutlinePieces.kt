package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.shape.outlinePolylines
import org.joml.Quaternionf
import org.joml.Vector3f
import kotlin.math.ceil
import kotlin.math.max

internal const val OUTLINE_CIRCLE_SEGMENTS = 16
internal const val MAX_CIRCLE_SEGMENTS = 128
internal const val PIECE_LENGTH = 4.0
internal const val MAX_LINE_DISPLAYS = 96

/**
 * How many segments this shape's outline circles need: enough that the arc chords stay
 * near [PIECE_LENGTH], so a big sphere reads as round instead of a hexadecagon, clamped
 * between the classic [OUTLINE_CIRCLE_SEGMENTS] and [MAX_CIRCLE_SEGMENTS].
 */
internal fun adaptiveCircleSegments(shape: Shape, pieceLength: Double = PIECE_LENGTH): Int {
    val bounds = shape.localBounds
    val diameter = maxOf(
        bounds.maxX - bounds.minX,
        bounds.maxY - bounds.minY,
        bounds.maxZ - bounds.minZ,
    )
    return ceil(Math.PI * diameter / pieceLength).toInt()
        .coerceIn(OUTLINE_CIRCLE_SEGMENTS, MAX_CIRCLE_SEGMENTS)
}

/**
 * One drawable stretch of a region's outline.
 *
 * [anchorOffset] is where the piece's display entity sits and [midOffset] is its unscaled
 * midpoint used for distance culling; both are offsets from the region anchor already rotated
 * into the world frame. Anchoring each piece where it is drawn is required for a big region's
 * outline to arrive at all: a display entity is only sent to a client near the entity itself, so
 * lines anchored on a distant region anchor are never sent.
 *
 * [from] and [to] are the line the entity draws, in the region's local (unrotated) frame: the
 * entity's own rotation carries them into the world, via the `rotation` argument of
 * [RegionOutline.lineTransformation]. They carry the workspace pulse's scale, while
 * [anchorOffset] and [midOffset] stay unscaled, so the pulse rewrites transformations only,
 * never teleporting a display, and the culling in [visibleOutlinePieces] does not churn while a
 * region pulses.
 */
internal data class OutlinePiece(
    val anchorOffset: Vector,
    val from: Vector,
    val to: Vector,
    val midOffset: Vector,
)

/** The most pieces one outline may be cut into, however large the region is. */
private const val MAX_OUTLINE_PIECES = 20_000

/**
 * [preferred], or longer when the outline at that length would exceed [MAX_OUTLINE_PIECES].
 */
private fun pieceLengthFor(shape: Shape, preferred: Double, circleSegments: Int): Double {
    var total = 0.0
    for (polyline in shape.outlinePolylines(circleSegments)) {
        for ((from, to) in polyline.segments()) total += (to - from).length
    }
    if (total <= 0.0) return preferred
    return max(preferred, total / MAX_OUTLINE_PIECES)
}

/**
 * The region's outline cut into pieces of at most [pieceLength] blocks. Each piece's anchor and
 * midpoint are offset from the region anchor and rotated into the world frame; its line stays
 * in the region's local frame, for [RegionOutline] to rotate along with the entity itself.
 */
internal fun buildOutlinePieces(
    shape: Shape,
    yawDegrees: Float,
    pitchDegrees: Float,
    rollDegrees: Float,
    scale: Float,
    circleSegments: Int = OUTLINE_CIRCLE_SEGMENTS,
    pieceLength: Double = PIECE_LENGTH,
): List<OutlinePiece> {
    val rotation = RegionOutline.regionRotation(yawDegrees, pitchDegrees, rollDegrees)
    val stretch = scale.toDouble()
    val pieces = mutableListOf<OutlinePiece>()

    // The piece length adapts to the region's size instead of being fixed. A stray zero in a
    // radius makes the outline millions of pieces long at a fixed length, all built on the main
    // thread before the display cap ever sees them, and a large enough one never finishes.
    val length = pieceLengthFor(shape, pieceLength, circleSegments)

    for (polyline in shape.outlinePolylines(circleSegments)) {
        for ((localFrom, localTo) in polyline.segments()) {
            val count = ceil((localTo - localFrom).length / length).toInt().coerceAtLeast(1)
            for (index in 0 until count) {
                val a = lerp(localFrom, localTo, index.toDouble() / count)
                val b = lerp(localFrom, localTo, (index + 1).toDouble() / count)
                pieces += OutlinePiece(
                    anchorOffset = rotate(rotation, a),
                    from = a * stretch - a,
                    to = b * stretch - a,
                    midOffset = rotate(rotation, lerp(a, b, 0.5)),
                )
            }
        }
    }
    return pieces
}

/**
 * The pieces to draw for a player, paired with their index in the full list so a piece keeps
 * the same display entity while the player walks along the border.
 *
 * An outline that fits within [budget] is drawn whole, whatever the distance, so a normal sized
 * region behaves exactly as it always has. A larger one is cut down to the pieces within
 * [renderDistance] of the player, nearest first.
 */
internal fun visibleOutlinePieces(
    pieces: List<OutlinePiece>,
    anchor: Vector,
    viewer: Vector,
    renderDistance: Double,
    budget: Int,
): List<IndexedValue<OutlinePiece>> {
    if (pieces.size <= budget) return pieces.withIndex().toList()

    val limit = renderDistance * renderDistance
    return pieces.withIndex()
        .map { it to (anchor + it.value.midOffset - viewer).lengthSquared }
        .filter { (_, distance) -> distance <= limit }
        .sortedBy { (_, distance) -> distance }
        .take(budget)
        .map { (piece, _) -> piece }
}

private fun rotate(rotation: Quaternionf, vector: Vector): Vector {
    val rotated = Vector3f(vector.x.toFloat(), vector.y.toFloat(), vector.z.toFloat()).rotate(rotation)
    return Vector(rotated.x.toDouble(), rotated.y.toDouble(), rotated.z.toDouble())
}

private fun lerp(from: Vector, to: Vector, fraction: Double): Vector = from + (to - from) * fraction
