package com.typewritermc.extensions.conformance

import com.typewritermc.authoring.TimelineKeyframePlacement
import com.typewritermc.authoring.TimelineSegmentPlacement
import com.typewritermc.elements.Keyframe
import com.typewritermc.elements.Segment
import com.typewritermc.types.OwnsResource
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.ToMany
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterRelation
import com.typewritermc.types.TypewriterType

@TypewriterRelation(
    id = "019d3a87003070008000000000000030",
    onSourceDelete = RelationDeletePolicy.CASCADE,
    onTargetDelete = RelationDeletePolicy.CLEAR,
)
sealed interface SyntheticEntryCues : OwnsResource<SyntheticEntry, SyntheticSegment>

@TypewriterRelation(
    id = "019d3a87003170008000000000000031",
    onSourceDelete = RelationDeletePolicy.CASCADE,
    onTargetDelete = RelationDeletePolicy.CLEAR,
)
sealed interface SyntheticSegmentKeyframes : OwnsResource<SyntheticSegment, SyntheticKeyframe>

@TypewriterType(id = "019d3a87003270008000000000000032")
@TypewriterDisplay(
    name = "Synthetic Segment",
    description = "Conformance cue with typed children",
    icon = "material-symbols:timeline",
    color = "#607D8B",
)
data class SyntheticSegment(
    override val placement: TimelineSegmentPlacement,
    val keyframes: ToMany<SyntheticSegmentKeyframes, SyntheticKeyframe> = ToMany.empty(),
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
