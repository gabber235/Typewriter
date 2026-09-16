package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.ceil

private val offsetCache = ConcurrentHashMap<Pair<Double, Double>, List<Vector>>()

private const val OFFSET_CACHE_MAX = 64

/**
 * The widest gap allowed between neighbouring hitbox samples.
 *
 * A lattice detects a shape only when a sample lands inside it, so the spacing is the
 * thinnest shape the classification can see. Three levels over a standing player's 1.8
 * blocks would leave a 0.9 block gap, wide enough for a narrow vision cone to pass through
 * a player's chest without a sample landing inside it.
 */
private const val MAX_SAMPLE_SPACING = 0.5

/**
 * The most points one lattice may hold.
 *
 * Spacing alone does not bound the count, which grows with the cube of the box: the vanilla
 * `scale` attribute goes to 16, and a player that size would ask for twenty six thousand
 * signed distance evaluations per tracker per move, on the main thread. A giant is easy to
 * hit, so it loses resolution rather than the server losing the tick.
 */
private const val MAX_SAMPLES = 125

/**
 * Sample offsets covering a bounding box of the given dimensions, relative to the box's
 * bottom center, spaced no further apart than [MAX_SAMPLE_SPACING] on every axis until the
 * box is large enough for [MAX_SAMPLES] to widen it. A shape at least that thick passing
 * through any part of the box is detected. Includes the bottom center itself, so a shape
 * that contains the player's feet is always detected.
 *
 * The lattice is cached per box dimensions. Player boxes only come in a handful of sizes
 * (standing, sneaking, swimming), and classification runs on every dispatch, so the cache
 * removes the per call allocation from the hot path.
 */
internal fun hitboxSampleOffsets(halfWidth: Double, height: Double): List<Vector> {
    require(halfWidth >= 0.0) { "Hitbox half-width must be non-negative, was $halfWidth" }
    require(height >= 0.0) { "Hitbox height must be non-negative, was $height" }

    val key = halfWidth to height
    offsetCache[key]?.let { return it }

    if (offsetCache.size >= OFFSET_CACHE_MAX) offsetCache.clear()
    val spacing = spacingFor(halfWidth, height)
    val lateral = axisSamples(-halfWidth, halfWidth, spacing)
    val vertical = axisSamples(0.0, height, spacing)
    val offsets = ArrayList<Vector>(vertical.size * lateral.size * lateral.size)
    for (y in vertical) for (x in lateral) for (z in lateral) {
        offsets.add(Vector(x, y, z))
    }
    return offsetCache.putIfAbsent(key, offsets) ?: offsets
}

/** The tightest spacing at or above [MAX_SAMPLE_SPACING] that keeps the lattice within [MAX_SAMPLES]. */
private fun spacingFor(halfWidth: Double, height: Double): Double {
    var spacing = MAX_SAMPLE_SPACING
    while (latticeSize(halfWidth, height, spacing) > MAX_SAMPLES) spacing *= 2.0
    return spacing
}

private fun latticeSize(halfWidth: Double, height: Double, spacing: Double): Long {
    val lateral = axisSampleCount(2.0 * halfWidth, spacing)
    val vertical = axisSampleCount(height, spacing)
    return lateral * lateral * vertical
}

private fun axisSampleCount(span: Double, spacing: Double): Long {
    if (span <= 0.0) return 1
    return ceil(span / spacing).toLong() + 1
}
