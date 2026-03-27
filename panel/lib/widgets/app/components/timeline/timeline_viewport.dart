import "dart:math" as math;

import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";

@immutable
class TimelineViewport {
  const TimelineViewport({
    required this.headerWidth,
    required this.planeWidth,
    required this.planeHeight,
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.pixelsPerFrame,
    this.overscanFrames = 40,
  });

  final double headerWidth;
  final double planeWidth;
  final double planeHeight;
  final double horizontalOffset;
  final double verticalOffset;
  final double pixelsPerFrame;
  final int overscanFrames;

  int get visibleStartFrame {
    final frame = (horizontalOffset / pixelsPerFrame).floor() - overscanFrames;
    return math.max(0, frame);
  }

  int get visibleEndFrame {
    final frame = ((horizontalOffset + planeWidth) / pixelsPerFrame).ceil();
    return math.max(visibleStartFrame, frame + overscanFrames);
  }

  int get visibleFrameCount {
    return visibleEndFrame - visibleStartFrame;
  }

  double frameToPixel(int frame) {
    return frame * pixelsPerFrame;
  }

  double frameCenterToPixel(int frame) {
    return frameToPixel(frame) + pixelsPerFrame / 2;
  }

  int pixelToFrame(double pixel) {
    return ((horizontalOffset + pixel) / pixelsPerFrame).round();
  }

  Rect get visibleBounds {
    return Rect.fromLTWH(
      horizontalOffset,
      verticalOffset,
      planeWidth,
      planeHeight,
    );
  }

  TimelineViewport copyWith({
    double? headerWidth,
    double? planeWidth,
    double? planeHeight,
    double? horizontalOffset,
    double? verticalOffset,
    double? pixelsPerFrame,
    int? overscanFrames,
  }) {
    return TimelineViewport(
      headerWidth: headerWidth ?? this.headerWidth,
      planeWidth: planeWidth ?? this.planeWidth,
      planeHeight: planeHeight ?? this.planeHeight,
      horizontalOffset: horizontalOffset ?? this.horizontalOffset,
      verticalOffset: verticalOffset ?? this.verticalOffset,
      pixelsPerFrame: pixelsPerFrame ?? this.pixelsPerFrame,
      overscanFrames: overscanFrames ?? this.overscanFrames,
    );
  }
}
