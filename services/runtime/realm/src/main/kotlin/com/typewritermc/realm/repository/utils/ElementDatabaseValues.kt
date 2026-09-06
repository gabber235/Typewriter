package com.typewritermc.realm.repository.utils

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

internal fun StoredReference.expectedTypeDatabaseValue(): String = Json.encodeToString(TypeExpression.serializer(), expectedType)
