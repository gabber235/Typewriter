import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:json_annotation/json_annotation.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/application/timeline_controller.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/presentation/timeline_style.dart";
import "package:typewriter_panel/shared/utilities/color_converter.dart";
import "package:typewriter_panel/shared/utilities/rect_converter.dart";

part "timeline_data.g.dart";

class TimelineData {
  TimelineData({required this.tracks}) {
    void collect(TimelineElement element, TimelineIdentifier trackId) {
      elementsById[element.id] = element;
      trackByElementId[element.id] = trackId;
      if (element case TimelineSegment(:final children)) {
        for (final child in children) {
          collect(child, trackId);
        }
      }
    }

    for (final track in tracks) {
      for (final element in track.elements) {
        collect(element, track.id);
      }
    }
  }
  final List<TimelineTrack> tracks;

  final Map<TimelineIdentifier, TimelineElement> elementsById = {};
  final Map<TimelineIdentifier, TimelineIdentifier> trackByElementId = {};

  MoveTimelinePreview? movePreview(TimelineIdentifier id) {
    final element = elementsById[id];
    if (element == null) return null;

    final parentId = element.parentId;
    final parentElement = parentId == null ? null : elementsById[parentId];

    final endConstraint = parentElement != null
        ? FrameConstraint.exact(parentElement.frameDuration)
        : const FrameConstraint.infinite();

    return MoveTimelinePreview(
      id: id,
      startFrame: element.startFrame,
      endFrame: element.endFrame,
      frameRange: FrameRange(FrameConstraint.infinite(), endConstraint),
    );
  }

  ResizeStartTimelinePreview? resizeStartPreview(TimelineIdentifier id) {
    final element = elementsById[id];
    if (element == null) return null;
    if (element is! TimelineSegment) return null;
    final lastChildEndFrame = element.children.map((e) => e.endFrame).maxOrNull;

    final endConstraint = lastChildEndFrame != null
        ? FrameConstraint.exact(
            element.startFrame + element.frameDuration - lastChildEndFrame,
          )
        : FrameConstraint.exact(element.endFrame);
    return ResizeStartTimelinePreview(
      id: element.id,
      startFrame: element.startFrame,
      endFrame: element.endFrame,
      startFrameRange: FrameRange(
        const FrameConstraint.infinite(),
        endConstraint,
      ),
    );
  }

  ResizeEndTimelinePreview? resizeEndPreview(TimelineIdentifier id) {
    final element = elementsById[id];
    if (element == null) return null;
    if (element is! TimelineSegment) return null;

    final parentId = element.parentId;
    final parentElement = parentId == null ? null : elementsById[parentId];

    final lastChildEndFrame = element.children.map((e) => e.endFrame).maxOrNull;

    final startConstraint = lastChildEndFrame != null
        ? FrameConstraint.exact(element.startFrame + lastChildEndFrame)
        : FrameConstraint.exact(element.startFrame);

    final endConstraint = parentElement != null
        ? FrameConstraint.exact(parentElement.frameDuration)
        : const FrameConstraint.infinite();

    return ResizeEndTimelinePreview(
      id: element.id,
      startFrame: element.startFrame,
      endFrame: element.endFrame,
      endFrameRange: FrameRange(startConstraint, endConstraint),
    );
  }
}

class TimelineIdentifier {
  const TimelineIdentifier(this.id);

  final String id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimelineIdentifier && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return id;
  }
}

@JsonSerializable(createFactory: false)
@TimelineIdentifierJsonConverter()
class TimelineTrack {
  TimelineTrack({
    required this.id,
    required this.header,
    required this.elements,
  });

  final TimelineIdentifier id;
  @JsonKey(includeToJson: false)
  final WidgetBuilder header;
  final List<TimelineElement> elements;

  Map<String, dynamic> toJson() => _$TimelineTrackToJson(this);
}

typedef TimelineElementBuilder =
    Widget Function(BuildContext context, TimelineElementBuildData data);

sealed class TimelineElement {
  const TimelineElement({
    required this.id,
    required this.color,
    required this.parentId,
  });
  final TimelineIdentifier id;
  final Color color;

  final TimelineIdentifier? parentId;

  TimelineElementBuilder get builder;

  int get startFrame;
  int get endFrame;

  bool get hasChildren;

  int get frameDuration => endFrame - startFrame;

  bool overlaps(TimelineElement other) {
    return endFrame >= other.startFrame && startFrame <= other.endFrame;
  }

  TimelineElement applyPreview(TimelinePreview? preview);

  Map<String, dynamic> toJson();
}

@JsonSerializable(createFactory: false)
@TimelineIdentifierJsonConverter()
@ColorConverter()
class TimelineSegment extends TimelineElement {
  TimelineSegment({
    required this.startFrame,
    required this.endFrame,
    required this.builder,
    required this.children,
    required super.id,
    required super.color,
    required super.parentId,
  }) : assert(startFrame >= 0),
       assert(endFrame >= 0),
       assert(endFrame >= startFrame),
       assert(
         children.none((element) => element.endFrame > (endFrame - startFrame)),
       );

  @override
  final int startFrame;
  @override
  final int endFrame;
  @override
  @JsonKey(includeToJson: false)
  final TimelineElementBuilder builder;
  final List<TimelineElement> children;

  @override
  bool get hasChildren => children.isNotEmpty;

  @override
  TimelineElement applyPreview(TimelinePreview? preview) {
    if (preview == null) return this;
    return TimelineSegment(
      id: id,
      parentId: parentId,
      startFrame: preview.startFrame,
      endFrame: preview.endFrame,
      builder: builder,
      children: children,
      color: color,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$TimelineSegmentToJson(this);
}

@JsonSerializable(createFactory: false)
@TimelineIdentifierJsonConverter()
@ColorConverter()
class TimelineKeyframe extends TimelineElement {
  const TimelineKeyframe({
    required this.frame,
    required this.builder,
    required super.id,
    required super.color,
    required super.parentId,
  }) : assert(frame >= 0);

  final int frame;
  @override
  @JsonKey(includeToJson: false)
  final TimelineElementBuilder builder;

  @override
  @JsonKey(includeToJson: false)
  int get startFrame => frame;
  @override
  @JsonKey(includeToJson: false)
  int get endFrame => frame;

  @override
  bool get hasChildren => false;

  @override
  TimelineElement applyPreview(TimelinePreview? preview) {
    if (preview == null) return this;
    return TimelineKeyframe(
      id: id,
      parentId: parentId,
      frame: preview.startFrame,
      builder: builder,
      color: color,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$TimelineKeyframeToJson(this);
}

@JsonSerializable(createFactory: false)
@TimelineIdentifierJsonConverter()
class TimelineTrackBlock {
  const TimelineTrackBlock({
    required this.trackId,
    required this.element,
    required this.previewState,
    required this.height,
    required this.children,
  });
  final TimelineIdentifier trackId;
  final TimelineElement element;
  final TimelinePreviewState previewState;
  final int height;
  final List<TimelineTrackBlockPlacement> children;

  Map<String, dynamic> toJson() => _$TimelineTrackBlockToJson(this);
}

@JsonSerializable(createFactory: false)
class TimelineTrackBlockPlacement {
  const TimelineTrackBlockPlacement({required this.block, required this.lane});
  final TimelineTrackBlock block;
  final int lane;
  @JsonKey(includeToJson: false)
  TimelineIdentifier get trackId => block.trackId;
  @JsonKey(includeToJson: false)
  TimelineElement get element => block.element;
  @JsonKey(includeToJson: false)
  TimelinePreviewState get previewState => block.previewState;
  @JsonKey(includeToJson: false)
  int get height => block.height;
  @JsonKey(includeToJson: false)
  List<TimelineTrackBlockPlacement> get children => block.children;

  Map<String, dynamic> toJson() => _$TimelineTrackBlockPlacementToJson(this);
}

@JsonSerializable(createFactory: false)
@TimelineIdentifierJsonConverter()
@RectConverter()
class TimelinePlacedElement {
  const TimelinePlacedElement({
    required this.trackId,
    required this.element,
    required this.laneIndex,
    required this.rect,
    required this.previewState,
    this.childrenRect,
  });

  final TimelineIdentifier trackId;
  final TimelineElement element;
  final int laneIndex;
  final Rect rect;
  final Rect? childrenRect;
  final TimelinePreviewState previewState;

  @JsonKey(includeToJson: false)
  bool get isPreview => previewState != TimelinePreviewState.none;
  @JsonKey(includeToJson: false)
  bool get isPrimaryPreview => previewState == TimelinePreviewState.active;
  @JsonKey(includeToJson: false)
  bool get isRelatedPreview => previewState == TimelinePreviewState.related;

  Map<String, dynamic> toJson() => _$TimelinePlacedElementToJson(this);
}

enum TimelinePreviewState { none, active, related }

class TimelineElementBuildData {
  const TimelineElementBuildData({
    required this.placed,
    required this.style,
    required this.controller,
    required this.onCommitPreview,
    required this.resolveMovePreviews,
    required this.resolveResizePreviews,
  });

  final TimelinePlacedElement placed;
  final TimelineStyle style;
  final TimelineController controller;
  final Future<void> Function(List<TimelinePreview> previews) onCommitPreview;
  final List<MoveTimelinePreview> Function(TimelineIdentifier id)
  resolveMovePreviews;
  final List<TimelinePreview> Function(
    TimelineIdentifier id,
    TimelineInteractionMode mode,
  )
  resolveResizePreviews;

  TimelineElement get element => placed.element;
  bool get isPreview => placed.isPreview;
  bool get isPrimaryPreview => placed.isPrimaryPreview;
  bool get isRelatedPreview => placed.isRelatedPreview;
}

class TimelineIdentifierJsonConverter
    extends JsonConverter<TimelineIdentifier, String> {
  const TimelineIdentifierJsonConverter();
  @override
  TimelineIdentifier fromJson(String json) {
    return TimelineIdentifier(json);
  }

  @override
  String toJson(TimelineIdentifier object) {
    return object.id;
  }
}
