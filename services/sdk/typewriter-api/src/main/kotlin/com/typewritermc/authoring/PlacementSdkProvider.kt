package com.typewritermc.authoring

import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.expression.gte
import com.typewritermc.expression.literal
import com.typewritermc.presentation.AppliedPresentation
import com.typewritermc.types.PresentationRole

object PlacementSdkProvider :
    GraphPlacementConfiguration,
    TimelineEntryPlacementConfiguration,
    TimelineSegmentPlacementConfiguration,
    TimelineKeyframePlacementConfiguration,
    GraphPlacementPresentation,
    TimelineEntryPlacementPresentation,
    TimelineSegmentPlacementPresentation,
    TimelineKeyframePlacementPresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)
    override val priority = 0

    override fun GraphPlacementConfigurationScope.configure() {
        width { positive() }
        height { positive() }
    }

    override fun TimelineEntryPlacementConfigurationScope.configure() {
        trackIndex { nonNegative() }
    }

    override fun TimelineSegmentPlacementConfigurationScope.configure() {
        startFrame { nonNegative() }
        endFrame { nonNegative() }
        rule { endFrame gte startFrame }
            .error(
                "Timeline segment end frame must not precede its start frame",
                RelativeFieldPattern(listOf(FieldPatternSegment.Field("endFrame"))),
            )
    }

    override fun TimelineKeyframePlacementConfigurationScope.configure() {
        frame { nonNegative() }
    }

    override fun GraphPlacementPresentationScope.present() {
        x {
            label("X")
            numericInput()
        }
        y {
            label("Y")
            numericInput()
        }
        width {
            label("Width")
            numericInput()
        }
        height {
            label("Height")
            numericInput()
        }
        remainingFields {
            exclude(x)
            exclude(y)
            exclude(width)
            exclude(height)
        }
    }

    override fun TimelineEntryPlacementPresentationScope.present() {
        trackIndex {
            label("Track")
            numericInput()
        }
        remainingFields { exclude(trackIndex) }
    }

    override fun TimelineSegmentPlacementPresentationScope.present() {
        startFrame {
            label("Start frame")
            numericInput()
        }
        endFrame {
            label("End frame")
            numericInput()
        }
        remainingFields {
            exclude(startFrame)
            exclude(endFrame)
        }
    }

    override fun TimelineKeyframePlacementPresentationScope.present() {
        frame {
            label("Frame")
            numericInput()
        }
        remainingFields { exclude(frame) }
    }
}

object PlacementFormSdkProvider : PlacementPresentation {
    override fun PlacementPresentationScope.present() {
        value {
            polymorphicInput {
                form(
                    AppliedPresentation<GraphPlacement>(GraphPlacementDefinition.use, PlacementSdkProvider),
                    literal("Graph"),
                )
                form(
                    AppliedPresentation<TimelineEntryPlacement>(TimelineEntryPlacementDefinition.use, PlacementSdkProvider),
                    literal("Timeline entry"),
                )
                form(
                    AppliedPresentation<TimelineSegmentPlacement>(TimelineSegmentPlacementDefinition.use, PlacementSdkProvider),
                    literal("Timeline segment"),
                )
                form(
                    AppliedPresentation<TimelineKeyframePlacement>(TimelineKeyframePlacementDefinition.use, PlacementSdkProvider),
                    literal("Timeline keyframe"),
                )
            }
        }
    }
}

object TimelineCuePlacementFormSdkProvider : TimelineCuePlacementPresentation {
    override fun TimelineCuePlacementPresentationScope.present() {
        value {
            polymorphicInput {
                form(
                    AppliedPresentation<TimelineSegmentPlacement>(TimelineSegmentPlacementDefinition.use, PlacementSdkProvider),
                    literal("Timeline segment"),
                )
                form(
                    AppliedPresentation<TimelineKeyframePlacement>(TimelineKeyframePlacementDefinition.use, PlacementSdkProvider),
                    literal("Timeline keyframe"),
                )
            }
        }
    }
}
