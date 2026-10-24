package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.sqrt

/**
 * The most boundary samples any shape will emit, however large it is or however high its
 * density is set.
 *
 * Without it the count grows with the square of the region's size: a sphere of radius 2000
 * at the default density asks for 25 million samples, and the boundary displays turn each
 * one into a fake entity or a block packet on the main thread. A region that big is beyond
 * what any display can usefully draw, so past this point the boundary is drawn sparser
 * rather than not at all.
 */
internal const val MAX_BOUNDARY_SAMPLES = 20_000

/**
 * The share of [MAX_BOUNDARY_SAMPLES] a step length is sized for.
 *
 * A sampler emits more than `boundaryArea / step²`: every axis run repeats the far endpoint
 * and every ring has a minimum count of its own, so a step sized for the whole budget
 * overshoots it on ordinary regions. [withinSampleBudget] cuts a contiguous tail rather than
 * thinning the sampling, which deletes whole caps or wall rows, so the step leaves room and
 * the hard cap stays a backstop for the shapes whose count no step can bound.
 */
private const val STEP_BUDGET_SHARE = 0.7

/**
 * Boundary sampling density converted to a step length, floored so extreme densities do
 * not explode the sample count, and floored again so a shape of [boundaryArea] stays
 * within [MAX_BOUNDARY_SAMPLES].
 */
internal fun sampleStep(density: Double, boundaryArea: Double): Double {
    val fromDensity = max(1.0 / sqrt(density.coerceAtLeast(0.001)), 0.5)
    if (boundaryArea <= 0.0) return fromDensity
    return max(fromDensity, sqrt(boundaryArea / (MAX_BOUNDARY_SAMPLES * STEP_BUDGET_SHARE)))
}

/** Sample count for a shape of [boundaryArea], clamped to [MAX_BOUNDARY_SAMPLES]. */
internal fun boundarySampleCount(boundaryArea: Double, density: Double): Int =
    (boundaryArea * density).toInt().coerceIn(8, MAX_BOUNDARY_SAMPLES)

/**
 * Stops a boundary sequence at [MAX_BOUNDARY_SAMPLES].
 *
 * [sampleStep] only picks a step length, and a step length alone does not bound the count
 * for a shape sampled edge by edge or ring by ring: a polygon emits at least one column per
 * edge whatever the step is, so enough vertices breach the budget on their own. The step
 * keeps the boundary evenly sampled and this keeps it finite.
 */
internal fun Sequence<Vector>.withinSampleBudget(): Sequence<Vector> = take(MAX_BOUNDARY_SAMPLES)

/**
 * Evenly divides [from]..[to] into segments no longer than [maxStep], returning the
 * segment boundaries with both endpoints exact. A zero length range yields the single
 * endpoint.
 *
 * Boundary samplers use this instead of accumulating float steps: accumulation drifts, so
 * rows stop short of the far edge and adjacent faces no longer meet on their shared edge,
 * which shows up as smeared or doubled edges in the boundary displays.
 */
internal fun axisSamples(from: Double, to: Double, maxStep: Double): List<Double> {
    require(to >= from) { "Invalid sample range [$from, $to]" }
    require(maxStep > 0.0) { "Sample step must be positive, was $maxStep" }
    val span = to - from
    if (span == 0.0) return listOf(from)
    val segments = max(1, ceil(span / maxStep).toInt())
    return List(segments + 1) { index ->
        if (index == segments) to else from + span * index / segments
    }
}
