package com.typewritermc.authoring

import com.typewritermc.configuration.field
import com.typewritermc.expression.literal
import com.typewritermc.expression.shortcuts.gte
import com.typewritermc.presentation.AppliedPresentation
import com.typewritermc.presentation.NumericInputScope
import com.typewritermc.presentation.PresentationColor
import com.typewritermc.presentation.TextStyle
import com.typewritermc.presentation.literalColor
import com.typewritermc.types.Color
import com.typewritermc.types.use
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.presentation.ControlDensity
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern

private fun NumericInputScope<Int>.coordinateInput(
    axis: String,
    color: PresentationColor,
) {
    prefix {
        text(literal(axis), style = TextStyle(color = color))
    }
    placeholder("00")
    step(1)
    density(ControlDensity.COMPACT)
    selectAllOnFocus(true)
}

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
                RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("endFrame"))),
            )
    }

    override fun TimelineKeyframePlacementConfigurationScope.configure() {
        frame { nonNegative() }
    }

    override fun GraphPlacementPresentationScope.present() {
        row {
            x {
                semanticLabel(literal("X coordinate"))
                numericInput {
                    coordinateInput("X", literalColor(Color.parseRgb(Color.Hex.RED)))
                }
            }
            y {
                semanticLabel(literal("Y coordinate"))
                numericInput {
                    coordinateInput("Y", literalColor(Color.parseRgb(Color.Hex.GREEN)))
                }
            }
        }
        row {
            width {
                numericInput {
                    coordinateInput("W", literalColor(Color.parseRgb(Color.Hex.ORANGE)))
                }
            }
            height {
                numericInput {
                    coordinateInput("H", literalColor(Color.parseRgb(Color.Hex.MEDIUM_PURPLE)))
                }
            }
        }
        remainingFields()
    }

    override fun TimelineEntryPlacementPresentationScope.present() {
        trackIndex {
            label("Track")
            numericInput()
        }
        remainingFields()
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
        remainingFields()
    }

    override fun TimelineKeyframePlacementPresentationScope.present() {
        frame {
            label("Frame")
            numericInput()
        }
        remainingFields()
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
