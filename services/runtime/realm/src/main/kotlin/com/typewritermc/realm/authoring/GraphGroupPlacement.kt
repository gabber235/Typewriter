package com.typewritermc.realm.authoring

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.GraphPlacementDefinition
import com.typewritermc.authoring.GraphPlacementDraft
import com.typewritermc.authoring.GraphPlacementDraftProjection
import com.typewritermc.authoring.PlacementAnchor
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.operations.requireAuthored
import com.typewritermc.realm.repository.valueAt
import com.typewritermc.types.ResourceId
import com.typewritermc.types.actualType
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.DataValue
import kotlin.math.abs
import kotlin.math.roundToLong

/**
 * Places one group of graph members while preserving its geometry and every existing obstacle.
 *
 * It computes placements only; callers write them through the returned drafts inside their edit.
 */
internal object GraphGroupPlacement {
    /**
     * Free placements for the graph placements at [subjects], avoiding the placements at [occupants].
     *
     * Occupants that are also subjects are ignored, so a group never collides with its own previous position.
     */
    context(reads: AuthoredReads)
    fun place(
        subjects: List<ValueLocation>,
        occupants: List<ValueLocation>,
        anchor: PlacementAnchor? = null,
    ): List<Pair<GraphPlacementDraft, GraphPlacement>> {
        val drafts = subjects.map { requireAuthored(GraphPlacementDraftProjection.read(it)) }
        val moving = subjects.mapTo(hashSetOf(), ValueLocation::resource)
        val obstacles =
            occupants
                .filter { it.resource !in moving }
                .map { requireAuthored(GraphPlacementDraftProjection.read(it)).current() }
        return drafts.zip(place(drafts.map { it.current() }, obstacles, anchor))
    }

    fun place(
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

context(reads: AuthoredReads)
private fun GraphPlacementDraft.current(): GraphPlacement =
    GraphPlacement(requireAuthored(x), requireAuthored(y), requireAuthored(width), requireAuthored(height))

/** Where this resource keeps its published placement, or null when its type declares no placement field. */
internal fun AuthoringCatalogLease.placementLocation(
    id: ResourceId,
    record: AuthoringRecord,
): ValueLocation? {
    val type = (record.configuration as? TypeSelection.Complete)?.use?.definition ?: return null
    return placementFields[type]?.let { ValueLocation(id, it) }
}

/** Where this resource keeps a graph placement, or null when it has no placement or holds another placement kind. */
internal fun AuthoringCatalogLease.graphPlacementLocation(
    id: ResourceId,
    record: AuthoringRecord,
): ValueLocation? =
    placementLocation(id, record)?.takeIf { location ->
        (record.valueAt(location.path) as? DataValue.NamedWrapper)?.actualType?.definition == GraphPlacementDefinition.id
    }
