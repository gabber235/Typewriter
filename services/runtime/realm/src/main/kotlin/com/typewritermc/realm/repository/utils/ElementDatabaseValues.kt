package com.typewritermc.realm.repository.utils

import com.surrealdb.Value
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.StoredReference
import com.typewritermc.types.TypeExpression
import kotlinx.serialization.json.Json

/**
 * Maps editor placement to the versioned database field layout understood by the element record parser.
 *
 * Frame values and graph geometry are preserved; execution compilation later discards graph layout.
 */
internal fun ElementPlacement.databaseValue(): Map<String, Any> =
    when (this) {
        is ElementPlacement.Graph -> {
            mapOf(
                "kind" to "graph_v1",
                "x" to x,
                "y" to y,
                "width" to width,
                "height" to height,
            )
        }

        is ElementPlacement.TimelineEntry -> {
            mapOf(
                "kind" to "timeline_entry_v1",
                "track_index" to trackIndex,
            )
        }

        is ElementPlacement.TimelineSegment -> {
            mapOf(
                "kind" to "timeline_segment_v1",
                "start_frame" to startFrame,
                "end_frame" to endFrame,
            )
        }

        is ElementPlacement.TimelineKeyframe -> {
            mapOf(
                "kind" to "timeline_keyframe_v1",
                "frame" to frame,
            )
        }
    }

internal fun Value.elementPlacement(): ElementPlacement {
    val placement = getObject()
    return when (val kind = placement.get("kind").getString()) {
        "graph_v1" -> {
            ElementPlacement.Graph(
                x = placement.get("x").getLong().toInt(),
                y = placement.get("y").getLong().toInt(),
                width = placement.get("width").getLong().toInt(),
                height = placement.get("height").getLong().toInt(),
            )
        }

        "timeline_entry_v1" -> {
            ElementPlacement.TimelineEntry(placement.get("track_index").getLong().toInt())
        }

        "timeline_segment_v1" -> {
            ElementPlacement.TimelineSegment(
                startFrame = placement.get("start_frame").getLong().toInt(),
                endFrame = placement.get("end_frame").getLong().toInt(),
            )
        }

        "timeline_keyframe_v1" -> {
            ElementPlacement.TimelineKeyframe(placement.get("frame").getLong().toInt())
        }

        else -> {
            error("Unknown element placement kind '$kind'.")
        }
    }
}

internal fun StoredReference.expectedTypeDatabaseValue(): String = Json.encodeToString(TypeExpression.serializer(), expectedType)
