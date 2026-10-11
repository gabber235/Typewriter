package com.typewritermc.extensions.conformance

import com.typewritermc.authoring.TimelineKeyframePlacement
import com.typewritermc.authoring.TimelineSegmentPlacement
import com.typewritermc.elements.Keyframe
import com.typewritermc.elements.Segment
import com.typewritermc.types.DeletionPolicy
import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.Owning
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType

@ReferenceContract(SYNTHETIC_ENTRY_CUES_RELATION_ID)
interface SyntheticEntryCuesContract : Owning {
    @DeletionPolicy(RelationDeletePolicy.CASCADE)
    interface Entry : One<ConformanceEntry>

    @DeletionPolicy(RelationDeletePolicy.CLEAR)
    interface Cue : Many<Segment>
}

@ReferenceContract(SYNTHETIC_SEGMENT_KEYFRAMES_RELATION_ID)
interface SyntheticSegmentKeyframesContract : Owning {
    @DeletionPolicy(RelationDeletePolicy.CASCADE)
    interface Segment : One<com.typewritermc.elements.Segment>

    @DeletionPolicy(RelationDeletePolicy.CLEAR)
    interface Keyframe : Many<com.typewritermc.elements.Keyframe>
}

@TypewriterType(id = "019d3a87003270008000000000000032")
@TypewriterDisplay(
    name = "Synthetic Segment",
    description = "Conformance cue with typed children",
    icon = "material-symbols:timeline",
    color = "#607D8B",
)
data class SyntheticSegment(
    override val placement: TimelineSegmentPlacement,
    val keyframes: List<Ref<SyntheticSegmentKeyframes.Segment, SyntheticKeyframe>> = emptyList(),
) : Segment

@TypewriterType(id = "019d3a87003370008000000000000033")
@TypewriterDisplay(
    name = "Synthetic Keyframe",
    description = "Conformance nested cue",
    icon = "material-symbols:radio-button-checked",
    color = "#607D8B",
)
data class SyntheticKeyframe(
    override val placement: TimelineKeyframePlacement,
) : Keyframe

const val SYNTHETIC_ENTRY_CUES_RELATION_ID = "019d3a87003070008000000000000030"
const val SYNTHETIC_SEGMENT_KEYFRAMES_RELATION_ID = "019d3a87003170008000000000000031"
