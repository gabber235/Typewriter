import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_data.dart";

enum TimelineInteractionMode { move, resizeStart, resizeEnd }

class FrameRange {
  const FrameRange(this.startFrame, this.endFrame);

  final FrameConstraint startFrame;
  final FrameConstraint endFrame;
  bool isWithin(int frame) {
    return startFrame <= frame && endFrame >= frame;
  }

  int coerceIn(int frame) {
    return endFrame.coerceAtMost(startFrame.coerceAtLeast(frame));
  }
}

sealed class FrameConstraint {
  const FrameConstraint();

  const factory FrameConstraint.exact(int frame) = ExactFrameConstraint;
  const factory FrameConstraint.infinite() = InfiniteFrameConstraint;

  bool operator <=(int frame);
  bool operator >=(int frame);

  int coerceAtLeast(int frame);
  int coerceAtMost(int frame);
}

class ExactFrameConstraint implements FrameConstraint {
  const ExactFrameConstraint(this.frame);

  final int frame;

  @override
  bool operator <=(int frame) => this.frame <= frame;

  @override
  bool operator >=(int frame) => this.frame >= frame;

  @override
  int coerceAtLeast(int frame) => math.max(this.frame, frame);
  @override
  int coerceAtMost(int frame) => math.min(this.frame, frame);

  @override
  String toString() => "ExactFrameConstraint($frame)";
}

class InfiniteFrameConstraint implements FrameConstraint {
  const InfiniteFrameConstraint();

  @override
  bool operator <=(int frame) => 0 <= frame;

  @override
  bool operator >=(int frame) => true;

  @override
  int coerceAtLeast(int frame) => math.max(0, frame);
  @override
  int coerceAtMost(int frame) => frame;

  @override
  String toString() => "InfiniteFrameConstraint";
}

sealed class TimelinePreview {
  const TimelinePreview({
    required this.id,
    required this.mode,
    required this.originalStartFrame,
    required this.originalEndFrame,
    required this.startFrame,
    required this.endFrame,
  });

  final TimelineIdentifier id;
  final TimelineInteractionMode mode;
  final int originalStartFrame;
  final int originalEndFrame;
  final int startFrame;
  final int endFrame;

  TimelinePreview update(int frameDelta);
}

class MoveTimelinePreview implements TimelinePreview {
  MoveTimelinePreview({
    required this.id,
    required this.startFrame,
    required this.endFrame,
    required this.frameRange,
    int? originalStartFrame,
    int? originalEndFrame,
  }) : originalStartFrame = originalStartFrame ?? startFrame,
       originalEndFrame = originalEndFrame ?? endFrame,
       assert(frameRange.isWithin(startFrame)),
       assert(frameRange.isWithin(endFrame));

  @override
  final TimelineIdentifier id;
  @override
  final int startFrame;
  @override
  final int endFrame;

  @override
  final int originalStartFrame;
  @override
  final int originalEndFrame;

  @override
  TimelineInteractionMode get mode => TimelineInteractionMode.move;

  final FrameRange frameRange;

  @override
  TimelinePreview update(int frameDelta) {
    final duration = originalEndFrame - originalStartFrame;
    var nextStart = frameRange.coerceIn(originalStartFrame + frameDelta);

    if (!frameRange.isWithin(nextStart + duration)) {
      final nextEnd = frameRange.coerceIn(nextStart + duration);
      if (frameRange.isWithin(nextStart - duration)) {
        nextStart = nextEnd - duration;
      } else {
        return this;
      }
    }

    return MoveTimelinePreview(
      id: id,
      startFrame: nextStart,
      endFrame: nextStart + duration,
      originalStartFrame: originalStartFrame,
      originalEndFrame: originalEndFrame,
      frameRange: frameRange,
    );
  }
}

class ResizeStartTimelinePreview implements TimelinePreview {
  ResizeStartTimelinePreview({
    required this.id,
    required this.startFrame,
    required this.endFrame,
    required this.startFrameRange,
    int? originalStartFrame,
  }) : originalStartFrame = originalStartFrame ?? startFrame,
       originalEndFrame = endFrame,
       assert(startFrameRange.isWithin(startFrame));

  @override
  final TimelineIdentifier id;
  @override
  final int startFrame;
  @override
  final int endFrame;

  @override
  final int originalStartFrame;
  @override
  final int originalEndFrame;

  @override
  TimelineInteractionMode get mode => TimelineInteractionMode.resizeStart;

  final FrameRange startFrameRange;

  @override
  TimelinePreview update(int frameDelta) {
    final nextStart = startFrameRange.coerceIn(originalStartFrame + frameDelta);
    return ResizeStartTimelinePreview(
      id: id,
      startFrame: nextStart,
      endFrame: endFrame,
      originalStartFrame: originalStartFrame,
      startFrameRange: startFrameRange,
    );
  }
}

class ResizeEndTimelinePreview implements TimelinePreview {
  ResizeEndTimelinePreview({
    required this.id,
    required this.startFrame,
    required this.endFrame,
    required this.endFrameRange,
    int? originalEndFrame,
  }) : originalStartFrame = startFrame,
       originalEndFrame = originalEndFrame ?? endFrame,
       assert(endFrameRange.isWithin(endFrame));

  @override
  final TimelineIdentifier id;
  @override
  final int startFrame;
  @override
  final int endFrame;

  @override
  final int originalStartFrame;
  @override
  final int originalEndFrame;

  @override
  TimelineInteractionMode get mode => TimelineInteractionMode.resizeEnd;

  final FrameRange endFrameRange;

  @override
  TimelinePreview update(int frameDelta) {
    final nextEnd = math.max(
      startFrame,
      endFrameRange.coerceIn(originalEndFrame + frameDelta),
    );
    return ResizeEndTimelinePreview(
      id: id,
      startFrame: startFrame,
      endFrame: nextEnd,
      originalEndFrame: originalEndFrame,
      endFrameRange: endFrameRange,
    );
  }
}

class TimelineController extends ChangeNotifier {
  TimelineController({double headerWidth = 200, double pixelsPerFrame = 6})
    : _headerWidth = headerWidth,
      _pixelsPerFrame = pixelsPerFrame;

  double _headerWidth;
  double _horizontalOffset = 0;
  double _verticalOffset = 0;
  double _pixelsPerFrame;
  final Map<TimelineIdentifier, TimelinePreview> _previewsById = {};

  double get headerWidth => _headerWidth;
  double get horizontalOffset => _horizontalOffset;
  double get verticalOffset => _verticalOffset;
  double get pixelsPerFrame => _pixelsPerFrame;
  bool get inPreview => _previewsById.isNotEmpty;

  List<TimelinePreview> get previews => _previewsById.values.toList();

  void setHeaderWidth(double width) {
    if (_headerWidth == width) return;
    _headerWidth = width;
    notifyListeners();
  }

  void setPixelsPerFrame(double pixelsPerFrame) {
    if (_pixelsPerFrame == pixelsPerFrame) return;
    _pixelsPerFrame = pixelsPerFrame;
    notifyListeners();
  }

  void panBy({double dx = 0, double dy = 0}) {
    if (dx == 0 && dy == 0) return;
    _horizontalOffset = math.max(0, _horizontalOffset + dx);
    _verticalOffset = math.max(0, _verticalOffset + dy);
    notifyListeners();
  }

  void zoomAt({
    required double localDx,
    required double scaleDelta,
    required double minPixelsPerFrame,
    required double maxPixelsPerFrame,
  }) {
    final oldPixelsPerFrame = _pixelsPerFrame;
    final nextPixelsPerFrame = (_pixelsPerFrame * scaleDelta).clamp(
      minPixelsPerFrame,
      maxPixelsPerFrame,
    );
    if (oldPixelsPerFrame == nextPixelsPerFrame) return;
    final anchorFrame = (_horizontalOffset + localDx) / oldPixelsPerFrame;
    _pixelsPerFrame = nextPixelsPerFrame;
    _horizontalOffset = math.max(0, anchorFrame * _pixelsPerFrame - localDx);
    notifyListeners();
  }

  void startInteractionSession({required List<TimelinePreview> previews}) {
    _previewsById
      ..clear()
      ..addEntries(previews.map((preview) => MapEntry(preview.id, preview)));
    notifyListeners();
  }

  void updateInteraction(double deltaPixels) {
    if (_previewsById.isEmpty) return;

    final frameDelta = (deltaPixels / _pixelsPerFrame).round();
    _previewsById.updateAll(
      (id, seedPreview) => seedPreview.update(frameDelta),
    );
    notifyListeners();
  }

  List<TimelinePreview> finishInteractionSession() {
    if (_previewsById.isEmpty) return const [];
    final sessionPreviews = previews;
    _previewsById.clear();
    notifyListeners();
    return sessionPreviews;
  }

  void cancelInteraction() {
    if (_previewsById.isEmpty) return;
    _previewsById.clear();
    notifyListeners();
  }
}

TimelineController useTimelineController({
  double headerWidth = 200,
  double pixelsPerFrame = 6,
  List<Object?>? keys,
}) {
  return use(_TimelineControllerHook(headerWidth, pixelsPerFrame, keys: keys));
}

class _TimelineControllerHook extends Hook<TimelineController> {
  const _TimelineControllerHook(
    this.headerWidth,
    this.pixelsPerFrame, {
    super.keys,
  });

  final double headerWidth;
  final double pixelsPerFrame;

  @override
  _TimelineControllerHookState createState() => _TimelineControllerHookState();
}

class _TimelineControllerHookState
    extends HookState<TimelineController, _TimelineControllerHook> {
  late TimelineController controller;

  @override
  void initHook() {
    super.initHook();
    controller = TimelineController(
      headerWidth: hook.headerWidth,
      pixelsPerFrame: hook.pixelsPerFrame,
    );
    controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    setState(() {});
  }

  @override
  void didUpdateHook(_TimelineControllerHook oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.headerWidth != oldHook.headerWidth) {
      controller.setHeaderWidth(hook.headerWidth);
    }
    if (hook.pixelsPerFrame != oldHook.pixelsPerFrame) {
      controller.setPixelsPerFrame(hook.pixelsPerFrame);
    }
  }

  @override
  TimelineController build(BuildContext context) => controller;

  @override
  void dispose() {
    controller
      ..removeListener(_onUpdate)
      ..dispose();
  }

  @override
  String debugLabel = "TimelineController";

  @override
  bool get debugSkipValue => true;
}
