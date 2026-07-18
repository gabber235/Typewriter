import "dart:math";

import "package:flutter/material.dart";

@immutable
class TimelineStyle {
  const TimelineStyle({
    required this.rulerHeight,
    required this.trackPadding,
    required this.laneHeight,
    required this.laneGap,
    required this.headerPadding,
    required this.minHeaderWidth,
    required this.maxHeaderWidth,
    required this.minPixelsPerFrame,
    required this.maxPixelsPerFrame,
    required this.gridMinorMinSpacing,
    required this.gridMajorMinSpacing,
    required this.gridTickSteps,
    required this.trailingFrames,
    required this.minSegmentWidth,
    required this.keyframeWidth,
    required this.keyframeSize,
    required this.edgeHandleWidth,
    required this.palette,
  }) : assert(gridTickSteps.length > 0);

  factory TimelineStyle.fallback(ThemeData theme) {
    final scheme = theme.colorScheme;
    final divider = scheme.outlineVariant;
    return TimelineStyle(
      rulerHeight: 56,
      trackPadding: 10,
      laneHeight: 52,
      laneGap: 8,
      headerPadding: 12,
      minHeaderWidth: 100,
      maxHeaderWidth: 420,
      minPixelsPerFrame: 0.01,
      maxPixelsPerFrame: 56,
      gridMinorMinSpacing: 12,
      gridMajorMinSpacing: 80,
      gridTickSteps: [
        1,
        2,
        5,
        10,
        20,
        40,
        ...List<int>.generate(8, (i) => pow(2, i).toInt() * 100),
      ],
      trailingFrames: 40,
      minSegmentWidth: 24,
      keyframeWidth: 28,
      keyframeSize: 12,
      edgeHandleWidth: 10,
      palette: TimelinePalette(
        headerBackground: scheme.surfaceContainer,
        rulerBackground: scheme.surfaceContainer,
        trackBackground: scheme.surfaceContainerLowest,
        trackAltBackground: scheme.surfaceContainerLow,
        gridMinor: divider.withValues(alpha: 0.45),
        gridMajor: divider.withValues(alpha: 0.9),
        headerDivider: divider,
        textMuted: scheme.onSurfaceVariant,
      ),
    );
  }

  /// The height of the timeline ruler area at the top.
  final double rulerHeight;

  /// The horizontal padding for track content.
  final double trackPadding;

  /// The height of each lane (row) in the timeline.
  final double laneHeight;

  /// The vertical gap between lanes.
  final double laneGap;

  /// The padding inside the header area.
  final double headerPadding;

  /// The minimum width of lane headers.
  final double minHeaderWidth;

  /// The maximum width of lane headers.
  final double maxHeaderWidth;

  /// The minimum number of pixels per frame for zooming out.
  final double minPixelsPerFrame;

  /// The maximum number of pixels per frame for zooming in.
  final double maxPixelsPerFrame;

  /// The minimum pixel spacing target for minor grid lines.
  final double gridMinorMinSpacing;

  /// The minimum pixel spacing target for major grid lines.
  final double gridMajorMinSpacing;

  /// The available frame steps used to choose grid line intervals.
  final List<int> gridTickSteps;

  /// The number of frames to keep rendered after the visible range.
  final int trailingFrames;

  /// The minimum width of a segment before it snaps or displays differently.
  final double minSegmentWidth;

  /// The width of keyframe indicators on the timeline.
  final double keyframeWidth;

  /// The size of individual keyframe hit targets.
  final double keyframeSize;

  /// The width of edge handles for resizing segments.
  final double edgeHandleWidth;

  /// The color palette used for rendering timeline elements.
  final TimelinePalette palette;
}

@immutable
class TimelinePalette {
  const TimelinePalette({
    required this.headerBackground,
    required this.rulerBackground,
    required this.trackBackground,
    required this.trackAltBackground,
    required this.gridMinor,
    required this.gridMajor,
    required this.headerDivider,
    required this.textMuted,
  });

  /// The background color for lane headers.
  final Color headerBackground;

  /// The background color for the ruler area.
  final Color rulerBackground;

  /// The background color for standard tracks.
  final Color trackBackground;

  /// The background color for alternating tracks.
  final Color trackAltBackground;

  /// The color for minor grid lines in the ruler.
  final Color gridMinor;

  /// The color for major grid lines in the ruler.
  final Color gridMajor;

  /// The color for dividers between headers and content.
  final Color headerDivider;

  /// The color for secondary/muted text.
  final Color textMuted;
}
