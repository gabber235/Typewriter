import "dart:math" as math;

import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "timeline_controller.freezed.dart";

enum TimelineInteractionMode { move, resizeStart, resizeEnd }

@freezed
abstract class TimelinePreview with _$TimelinePreview {
  const factory TimelinePreview({
    required String id,
    required TimelineInteractionMode mode,
    required int originalStartFrame,
    required int originalEndFrame,
    required int startFrame,
    required int endFrame,
  }) = _TimelinePreview;
}

class TimelineController extends ChangeNotifier {
  double _headerWidth = 280;
  double _horizontalOffset = 0;
  double _verticalOffset = 0;
  double _pixelsPerFrame = 12;
  TimelinePreview? _preview;

  double get headerWidth => _headerWidth;
  double get horizontalOffset => _horizontalOffset;
  double get verticalOffset => _verticalOffset;
  double get pixelsPerFrame => _pixelsPerFrame;
  TimelinePreview? get preview => _preview;

  void setHeaderWidth(double width) {
    if (_headerWidth == width) return;
    _headerWidth = width;
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

  void startMove({
    required String id,
    required int startFrame,
    required int endFrame,
  }) {
    _preview = TimelinePreview(
      id: id,
      mode: TimelineInteractionMode.move,
      originalStartFrame: startFrame,
      originalEndFrame: endFrame,
      startFrame: startFrame,
      endFrame: endFrame,
    );
    notifyListeners();
  }

  void startResizeStart({
    required String id,
    required int startFrame,
    required int endFrame,
  }) {
    _preview = TimelinePreview(
      id: id,
      mode: TimelineInteractionMode.resizeStart,
      originalStartFrame: startFrame,
      originalEndFrame: endFrame,
      startFrame: startFrame,
      endFrame: endFrame,
    );
    notifyListeners();
  }

  void startResizeEnd({
    required String id,
    required int startFrame,
    required int endFrame,
  }) {
    _preview = TimelinePreview(
      id: id,
      mode: TimelineInteractionMode.resizeEnd,
      originalStartFrame: startFrame,
      originalEndFrame: endFrame,
      startFrame: startFrame,
      endFrame: endFrame,
    );
    notifyListeners();
  }

  void updateInteraction(double deltaPixels) {
    final preview = _preview;
    if (preview == null) return;

    final frameDelta = (deltaPixels / _pixelsPerFrame).round();
    switch (preview.mode) {
      case TimelineInteractionMode.move:
        final duration = preview.originalEndFrame - preview.originalStartFrame;
        final nextStart = math.max(0, preview.originalStartFrame + frameDelta);
        _preview = preview.copyWith(
          startFrame: nextStart,
          endFrame: nextStart + duration,
        );
      case TimelineInteractionMode.resizeStart:
        final nextStart = math.max(
          0,
          math.min(
            preview.originalEndFrame,
            preview.originalStartFrame + frameDelta,
          ),
        );
        _preview = preview.copyWith(startFrame: nextStart);
      case TimelineInteractionMode.resizeEnd:
        final nextEnd = math.max(
          preview.originalStartFrame,
          preview.originalEndFrame + frameDelta,
        );
        _preview = preview.copyWith(endFrame: nextEnd);
    }
    notifyListeners();
  }

  TimelinePreview? finishInteraction() {
    final preview = _preview;
    _preview = null;
    notifyListeners();
    return preview;
  }

  void cancelInteraction() {
    if (_preview == null) return;
    _preview = null;
    notifyListeners();
  }
}
