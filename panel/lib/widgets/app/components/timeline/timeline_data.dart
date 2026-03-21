import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_controller.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_style.dart";

class TimelineData {
  const TimelineData({required this.tracks});
  final List<TimelineTrack> tracks;
}

class TimelineIdentifier {
  const TimelineIdentifier(this.id);

  final String id;

  @override
  String toString() => id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelineIdentifier && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

class TimelineTrack {
  TimelineTrack({
    required this.id,
    required this.header,
    required this.elements,
  });

  final TimelineIdentifier id;
  final WidgetBuilder header;
  final List<TimelineElement> elements;
}

typedef TimelineElementBuilder =
    Widget Function(BuildContext context, TimelineElementBuildData data);

sealed class TimelineElement implements Comparable<TimelineElement> {
  const TimelineElement({required this.id, required this.color});
  final TimelineIdentifier id;
  final Color color;

  TimelineElementBuilder get builder;

  int get startFrame;
  int get endFrame;

  @override
  int compareTo(TimelineElement other) {
    final frameCompare = startFrame.compareTo(other.startFrame);
    if (frameCompare != 0) return frameCompare;

    final endCompare = other.endFrame.compareTo(endFrame);
    if (endCompare != 0) return endCompare;

    return switch ((this, other)) {
      (TimelineSegment(), TimelineKeyframe()) => -1,
      (TimelineKeyframe(), TimelineSegment()) => 1,
      _ => id.id.compareTo(other.id.id),
    };
  }
}

class TimelineSegment extends TimelineElement {
  TimelineSegment({
    required this.startFrame,
    required this.endFrame,
    required this.builder,
    required this.children,
    required super.id,
    required super.color,
  }) : assert(startFrame >= 0),
       assert(endFrame >= 0),
       assert(endFrame >= startFrame),
       assert(children.none((element) => element.startFrame < startFrame)),
       assert(children.none((element) => element.endFrame > endFrame));

  @override
  final int startFrame;
  @override
  final int endFrame;
  @override
  final TimelineElementBuilder builder;
  final List<TimelineElement> children;
}

class TimelineKeyframe extends TimelineElement {
  const TimelineKeyframe({
    required this.frame,
    required this.builder,
    required super.id,
    required super.color,
  }) : assert(frame >= 0);

  final int frame;
  @override
  final TimelineElementBuilder builder;

  @override
  int get startFrame => frame;
  @override
  int get endFrame => frame;
}

class TimelinePlacedElement {
  const TimelinePlacedElement({
    required this.trackId,
    required this.element,
    required this.laneIndex,
    required this.rect,
    required this.previewState,
  });

  final TimelineIdentifier trackId;
  final TimelineElement element;
  final int laneIndex;
  final Rect rect;
  final TimelinePreviewState previewState;

  bool get isPreview => previewState != TimelinePreviewState.none;

  bool get isPrimaryPreview => previewState == TimelinePreviewState.active;

  bool get isRelatedPreview => previewState == TimelinePreviewState.related;
}

enum TimelinePreviewState { none, active, related }

class TimelineElementBuildData {
  const TimelineElementBuildData({
    required this.placed,
    required this.style,
    required this.controller,
    required this.onCommitPreview,
    required this.resolveMovePreviews,
  });

  final TimelinePlacedElement placed;
  final TimelineStyle style;
  final TimelineController controller;
  final Future<void> Function(List<TimelinePreview> previews) onCommitPreview;
  final List<TimelinePreviewSeed> Function(TimelineIdentifier id)
  resolveMovePreviews;

  TimelineElement get element => placed.element;
  bool get isPreview => placed.isPreview;
  bool get isPrimaryPreview => placed.isPrimaryPreview;
  bool get isRelatedPreview => placed.isRelatedPreview;
}
