import "package:flutter/material.dart";

@immutable
class TimelineStyle {
  const TimelineStyle({
    required this.rulerHeight,
    required this.trackGap,
    required this.trackPadding,
    required this.laneHeight,
    required this.laneGap,
    required this.headerPadding,
    required this.minHeaderWidth,
    required this.maxHeaderWidth,
    required this.minPixelsPerFrame,
    required this.maxPixelsPerFrame,
    required this.overscanFrames,
    required this.trailingFrames,
    required this.minSegmentWidth,
    required this.keyframeWidth,
    required this.keyframeSize,
    required this.edgeHandleWidth,
    required this.palette,
  });

  factory TimelineStyle.fallback(ThemeData theme) {
    final scheme = theme.colorScheme;
    final divider = scheme.outlineVariant;
    return TimelineStyle(
      rulerHeight: 56,
      trackGap: 12,
      trackPadding: 10,
      laneHeight: 52,
      laneGap: 8,
      headerPadding: 12,
      minHeaderWidth: 100,
      maxHeaderWidth: 420,
      minPixelsPerFrame: 6,
      maxPixelsPerFrame: 56,
      overscanFrames: 40,
      trailingFrames: 40,
      minSegmentWidth: 24,
      keyframeWidth: 28,
      keyframeSize: 12,
      edgeHandleWidth: 10,
      palette: TimelinePalette(
        headerBackground: scheme.surfaceContainerHigh,
        rulerBackground: scheme.surfaceContainer,
        trackBackground: scheme.surfaceContainerLowest,
        trackAltBackground: scheme.surfaceContainerLow,
        gridMinor: divider.withValues(alpha: 0.45),
        gridMajor: divider.withValues(alpha: 0.9),
        headerDivider: divider,
        textMuted: scheme.onSurfaceVariant,
        segmentFill: scheme.primaryContainer,
        segmentBorder: scheme.primary,
        previewFill: scheme.primary.withValues(alpha: 0.18),
        previewBorder: scheme.primary,
        keyframeFill: scheme.tertiary,
        keyframeBorder: scheme.onTertiary,
      ),
    );
  }

  final double rulerHeight;
  final double trackGap;
  final double trackPadding;
  final double laneHeight;
  final double laneGap;
  final double headerPadding;
  final double minHeaderWidth;
  final double maxHeaderWidth;
  final double minPixelsPerFrame;
  final double maxPixelsPerFrame;
  final int overscanFrames;
  final int trailingFrames;
  final double minSegmentWidth;
  final double keyframeWidth;
  final double keyframeSize;
  final double edgeHandleWidth;
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
    required this.segmentFill,
    required this.segmentBorder,
    required this.previewFill,
    required this.previewBorder,
    required this.keyframeFill,
    required this.keyframeBorder,
  });

  final Color headerBackground;
  final Color rulerBackground;
  final Color trackBackground;
  final Color trackAltBackground;
  final Color gridMinor;
  final Color gridMajor;
  final Color headerDivider;
  final Color textMuted;
  final Color segmentFill;
  final Color segmentBorder;
  final Color previewFill;
  final Color previewBorder;
  final Color keyframeFill;
  final Color keyframeBorder;
}
