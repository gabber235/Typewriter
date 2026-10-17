package com.typewritermc.operations

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.GraphPlacementDraftProjection
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import kotlin.math.abs
import kotlin.math.roundToLong

/** Places one group while preserving its geometry and every existing obstacle. */
object GraphGroupPlacement : DestinationPlacementPolicy {
    context(reads: AuthoredReads)
    override fun prepare(request: DestinationPlacementRequest): PlacementPreparation =
        prepare(request.subjects, request.occupants, request.anchor)

    context(reads: AuthoredReads)
    fun prepare(
        subjects: List<ResourceDraft>,
        occupants: List<ResourceDraft>,
        anchor: PlacementAnchor? = null,
    ): PlacementPreparation {
        val drafts =
            subjects.map { subject ->
                requireAuthored(GraphPlacementDraftProjection.read(ValueLocation(subject.id, PLACEMENT_PATH)))
            }
        val group =
            drafts.map {
                GraphPlacement(requireAuthored(it.x), requireAuthored(it.y), requireAuthored(it.width), requireAuthored(it.height))
            }
        val subjectIds = subjects.mapTo(hashSetOf()) { it.id }
        val obstacles =
            occupants.filter { it.id !in subjectIds }.map { subject ->
                val draft = requireAuthored(GraphPlacementDraftProjection.read(ValueLocation(subject.id, PLACEMENT_PATH)))
                GraphPlacement(
                    requireAuthored(draft.x),
                    requireAuthored(draft.y),
                    requireAuthored(draft.width),
                    requireAuthored(draft.height),
                )
            }
        val placed = place(group, obstacles, anchor)
        return PlacementPreparation {
            drafts.zip(placed).forEach { (draft, position) ->
                draft.setX(position.x)
                draft.setY(position.y)
            }
        }
    }

    internal fun place(
        group: List<GraphPlacement>,
        obstacles: List<GraphPlacement>,
        anchor: PlacementAnchor?,
    ): List<GraphPlacement> {
        if (group.isEmpty()) return emptyList()
        val left = group.minOf { it.x.toLong() }
        val top = group.minOf { it.y.toLong() }
        val right = group.maxOf { it.x.toLong() + it.width }
        val bottom = group.maxOf { it.y.toLong() + it.height }
        require(anchor == null || (anchor.x.isFinite() && anchor.y.isFinite())) { "The graph anchor must be finite." }
        val dx = anchor?.let { (it.x - (left + right) / 2.0).roundToLong() } ?: 0L
        val dy = anchor?.let { (it.y - (top + bottom) / 2.0).roundToLong() } ?: 0L

        fun valid(
            x: Long,
            y: Long,
        ): Boolean =
            group.all { rect ->
                val rx = rect.x.toLong() + x
                val ry = rect.y.toLong() + y
                rx in Int.MIN_VALUE.toLong()..Int.MAX_VALUE.toLong() && ry in Int.MIN_VALUE.toLong()..Int.MAX_VALUE.toLong() &&
                    obstacles.none { obstacle ->
                        rx < obstacle.x.toLong() + obstacle.width + 1 && rx + rect.width + 1 > obstacle.x &&
                            ry < obstacle.y.toLong() + obstacle.height + 1 && ry + rect.height + 1 > obstacle.y
                    }
            }

        fun translated(
            x: Long,
            y: Long,
        ) = group.map { it.copy(x = Math.toIntExact(it.x.toLong() + x), y = Math.toIntExact(it.y.toLong() + y)) }
        if (valid(dx, dy)) return translated(dx, dy)
        val escapes =
            listOf(
                obstacles.maxOf { it.x.toLong() + it.width } + 1 - left to dy,
                dx to obstacles.maxOf { it.y.toLong() + it.height } + 1 - top,
                obstacles.minOf { it.x.toLong() } - 1 - right to dy,
                dx to obstacles.minOf { it.y.toLong() } - 1 - bottom,
            ).sortedBy { abs(it.first - dx) + abs(it.second - dy) }
        // Bound nearby search independently of authored coordinate magnitudes.
        for (distance in 1L..64L) {
            for (x in -distance..distance) {
                val y = distance - abs(x)
                if (valid(dx + x, dy + y)) return translated(dx + x, dy + y)
                if (y != 0L && valid(dx + x, dy - y)) return translated(dx + x, dy - y)
            }
        }
        val escape =
            escapes.firstOrNull { valid(it.first, it.second) }
                ?: error("The graph has no representable free placement for this group.")
        return translated(escape.first, escape.second)
    }
}

private val PLACEMENT_PATH = ValuePath(listOf(PathSegment.Field("placement")))
