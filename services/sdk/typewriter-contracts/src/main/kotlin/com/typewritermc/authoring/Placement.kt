package com.typewritermc.authoring

import com.typewritermc.types.TypewriterType
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Positions an authored resource in its owning editor surface. */
@TypewriterType(id = PLACEMENT_TYPE_ID)
sealed interface Placement

/** Positions a rectangular resource in graph grid units. */
@Serializable
@SerialName("graph")
@TypewriterType(id = GRAPH_PLACEMENT_TYPE_ID)
data class GraphPlacement(
    val x: Int,
    val y: Int,
    val width: Int,
    val height: Int,
) : Placement {
    init {
        require(width > 0) { "Graph placement width must be positive." }
        require(height > 0) { "Graph placement height must be positive." }
    }
}

/** Positions an entry on one timeline track. */
@Serializable
@SerialName("timeline_entry")
@TypewriterType(id = TIMELINE_ENTRY_PLACEMENT_TYPE_ID)
data class TimelineEntryPlacement(
    val trackIndex: Int,
) : Placement {
    init {
        require(trackIndex >= 0) { "Timeline entry track index must not be negative." }
    }
}

/** Positions an entry across an inclusive timeline frame range. */
@Serializable
@SerialName("timeline_segment")
@TypewriterType(id = TIMELINE_SEGMENT_PLACEMENT_TYPE_ID)
data class TimelineSegmentPlacement(
    val startFrame: Int,
    val endFrame: Int,
) : Placement {
    init {
        require(startFrame >= 0) { "Timeline segment start frame must not be negative." }
        require(endFrame >= startFrame) { "Timeline segment end frame must not precede its start frame." }
    }
}

/** Positions an entry at one timeline frame. */
@Serializable
@SerialName("timeline_keyframe")
@TypewriterType(id = TIMELINE_KEYFRAME_PLACEMENT_TYPE_ID)
data class TimelineKeyframePlacement(
    val frame: Int,
) : Placement {
    init {
        require(frame >= 0) { "Timeline keyframe frame must not be negative." }
    }
}

const val PLACEMENT_TYPE_ID = "d134aec7caa54a288ab42275756cfe8d"
const val GRAPH_PLACEMENT_TYPE_ID = "578f0d42bc964b1fab52c8de5e02f9c5"
const val TIMELINE_ENTRY_PLACEMENT_TYPE_ID = "bf3c5268557a4dfba0e7c1f72d3e67bd"
const val TIMELINE_SEGMENT_PLACEMENT_TYPE_ID = "54e38e56871243d2ae747ed6c0083381"
const val TIMELINE_KEYFRAME_PLACEMENT_TYPE_ID = "e0369811aac94bf6a291f65d1c719e1b"
