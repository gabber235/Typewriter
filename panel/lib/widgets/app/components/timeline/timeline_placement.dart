import "dart:math" as math;

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_data.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_layout.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_style.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_viewport.dart";

class TimelinePlacementEngine {
  const TimelinePlacementEngine();

  TimelinePlacementResult build({
    required TimelineLayoutResult layout,
    required TimelineViewport viewport,
    required TimelineStyle style,
  }) {
    final tracks = _buildTrackGeometry(layout, style);
    final maxFrame = _maxEndFrame(layout);
    final contentWidth =
        (maxFrame + style.trailingFrames + 1) * viewport.pixelsPerFrame;
    final contentHeight = tracks.lastOrNull?.bottom ?? 0;

    final visibleElements = <TimelinePlacedElement>[];
    final visibleBounds = viewport.visibleBounds;

    for (var index = 0; index < layout.tracks.length; index++) {
      final trackLayout = layout.tracks[index];
      final trackGeometry = tracks[index];
      if (!trackGeometry.isVisible(viewport)) {
        continue;
      }
      for (final placement in trackLayout.placements) {
        _collectVisibleElements(
          placement: placement,
          visibleElements: visibleElements,
          viewport: viewport,
          style: style,
          visibleBounds: visibleBounds,
          trackGeometry: trackGeometry,
        );
      }
    }

    return TimelinePlacementResult(
      tracks: tracks,
      visibleElements: visibleElements,
      contentWidth: contentWidth,
      contentHeight: contentHeight,
    );
  }

  List<TimelineTrackGeometry> _buildTrackGeometry(
    TimelineLayoutResult layout,
    TimelineStyle style,
  ) {
    var nextTop = 0.0;
    final tracks = <TimelineTrackGeometry>[];
    for (var index = 0; index < layout.tracks.length; index++) {
      final trackLayout = layout.tracks[index];
      assert(trackLayout.laneCount >= 0);
      final laneCount = math.max(1, trackLayout.laneCount);
      final laneAreaHeight = _laneHeight(style: style, laneCount: laneCount);
      final trackHeight = style.trackPadding * 2 + laneAreaHeight;

      tracks.add(
        TimelineTrackGeometry(
          track: trackLayout.track,
          top: nextTop,
          height: trackHeight,
          backgroundColor: index.isEven
              ? style.palette.trackBackground
              : style.palette.trackAltBackground,
        ),
      );

      nextTop += trackHeight;
    }
    return tracks;
  }

  void _collectVisibleElements({
    required TimelineTrackBlockPlacement placement,
    required List<TimelinePlacedElement> visibleElements,
    required TimelineViewport viewport,
    required TimelineStyle style,
    required Rect visibleBounds,
    required TimelineTrackGeometry trackGeometry,
    int laneOffset = 0,
    int frameOffset = 0,
  }) {
    final laneIndex = laneOffset + placement.lane;
    assert(laneIndex >= 0);
    assert(placement.height > 0);

    if (!_isFrameVisible(placement.element, frameOffset, viewport)) {
      return;
    }

    final rect = _rectForPlacement(
      placement: placement,
      laneIndex: laneIndex,
      frameOffset: frameOffset,
      trackTop: trackGeometry.top,
      viewport: viewport,
      style: style,
    );

    final childrenRect = _rectForChildren(
      placement: placement,
      parentRect: rect,
      style: style,
    );

    if (rect.overlaps(visibleBounds) ||
        (childrenRect?.overlaps(visibleBounds) ?? false)) {
      visibleElements.add(
        TimelinePlacedElement(
          trackId: placement.trackId,
          element: placement.element,
          laneIndex: laneIndex,
          rect: rect,
          childrenRect: childrenRect,
          previewState: placement.previewState,
        ),
      );
    }

    for (final child in placement.children) {
      _collectVisibleElements(
        placement: child,
        visibleElements: visibleElements,
        viewport: viewport,
        style: style,
        visibleBounds: visibleBounds,
        trackGeometry: trackGeometry,
        laneOffset: laneIndex + 1,
        frameOffset: frameOffset + placement.element.startFrame,
      );
    }
  }

  Rect _rectForPlacement({
    required TimelineTrackBlockPlacement placement,
    required int laneIndex,
    required int frameOffset,
    required double trackTop,
    required TimelineViewport viewport,
    required TimelineStyle style,
  }) {
    final element = placement.element;
    final y =
        trackTop +
        style.trackPadding +
        laneIndex * (style.laneHeight + style.laneGap);

    final height = _laneHeight(style: style, laneCount: 1);

    if (element is TimelineKeyframe) {
      final x =
          viewport.frameCenterToPixel(frameOffset + element.frame) -
          style.keyframeWidth / 2;
      return Rect.fromLTWH(x, y, style.keyframeWidth, height);
    }

    final startX = viewport.frameToPixel(frameOffset + element.startFrame);
    final endX = viewport.frameToPixel(frameOffset + element.endFrame + 1);
    final width = math.max(style.minSegmentWidth, endX - startX);

    return Rect.fromLTWH(startX, y, width, height);
  }

  Rect? _rectForChildren({
    required TimelineTrackBlockPlacement placement,
    required Rect parentRect,
    required TimelineStyle style,
  }) {
    if (placement.children.isEmpty) return null;

    assert(placement.height > 1);
    final laneHeight =
        _laneHeight(style: style, laneCount: placement.height) +
        style.laneGap / 2;
    final parentHeight = parentRect.height;
    return Rect.fromLTWH(
      parentRect.left,
      parentRect.top + parentHeight / 2,
      parentRect.width,
      laneHeight - parentHeight / 2,
    );
  }

  bool _isFrameVisible(
    TimelineElement element,
    int frameOffset,
    TimelineViewport viewport,
  ) {
    if (viewport.visibleStartFrame > frameOffset + element.endFrame) {
      return false;
    }
    if (viewport.visibleEndFrame < frameOffset + element.startFrame) {
      return false;
    }
    return true;
  }

  int _maxEndFrame(TimelineLayoutResult layout) {
    return layout.tracks.map(_maxEndFrameInTrack).maxOrNull ?? 0;
  }

  int _maxEndFrameInTrack(TimelineTrackLayout track) {
    return track.placements
            .map((placement) => placement.element.endFrame)
            .maxOrNull ??
        0;
  }

  double _laneHeight({required TimelineStyle style, required int laneCount}) {
    final safeLaneCount = math.max(0, laneCount);
    final gaps = math.max(0, safeLaneCount - 1);
    return safeLaneCount * style.laneHeight + gaps * style.laneGap;
  }
}

class TimelinePlacementResult {
  const TimelinePlacementResult({
    required this.tracks,
    required this.visibleElements,
    required this.contentWidth,
    required this.contentHeight,
  });

  final List<TimelineTrackGeometry> tracks;
  final List<TimelinePlacedElement> visibleElements;
  final double contentWidth;
  final double contentHeight;
}

class TimelineTrackGeometry {
  const TimelineTrackGeometry({
    required this.track,
    required this.top,
    required this.height,
    required this.backgroundColor,
  });

  final TimelineTrack track;
  final double top;
  final double height;
  final Color backgroundColor;

  double get bottom => top + height;

  bool isVisible(TimelineViewport viewport) {
    final trackTop = top;
    final trackBottom = bottom;
    if (trackTop > viewport.verticalOffset + viewport.planeHeight) return false;
    if (trackBottom < viewport.verticalOffset) return false;
    return true;
  }
}
