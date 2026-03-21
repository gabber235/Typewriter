import "dart:math" as math;

import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";

part "timeline_controller.freezed.dart";

enum TimelineInteractionMode { move, resizeStart, resizeEnd }

typedef TimelinePreviewSeed = ({String id, int startFrame, int endFrame});

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
  String? _activePreviewId;
  final Map<String, TimelinePreview> _previewsById = {};

  double get headerWidth => _headerWidth;
  double get horizontalOffset => _horizontalOffset;
  double get verticalOffset => _verticalOffset;
  double get pixelsPerFrame => _pixelsPerFrame;
  TimelinePreview? get preview {
    final activePreviewId = _activePreviewId;
    if (activePreviewId == null) return null;
    return _previewsById[activePreviewId];
  }

  List<TimelinePreview> get previews => _previewsById.values.toList();

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
    List<TimelinePreviewSeed> additionalPreviews = const [],
  }) {
    final seeds = <TimelinePreviewSeed>[
      (id: id, startFrame: startFrame, endFrame: endFrame),
      ...additionalPreviews,
    ];

    _activePreviewId = id;
    _previewsById
      ..clear()
      ..addEntries(
        seeds
            .where((seed) => seed.id.isNotEmpty)
            .map(
              (seed) => MapEntry(
                seed.id,
                TimelinePreview(
                  id: seed.id,
                  mode: TimelineInteractionMode.move,
                  originalStartFrame: seed.startFrame,
                  originalEndFrame: seed.endFrame,
                  startFrame: seed.startFrame,
                  endFrame: seed.endFrame,
                ),
              ),
            ),
      );
    notifyListeners();
  }

  void startResizeStart({
    required String id,
    required int startFrame,
    required int endFrame,
  }) {
    _activePreviewId = id;
    _previewsById
      ..clear()
      ..[id] = TimelinePreview(
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
    _activePreviewId = id;
    _previewsById
      ..clear()
      ..[id] = TimelinePreview(
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
    final preview = this.preview;
    if (preview == null) return;

    final frameDelta = (deltaPixels / _pixelsPerFrame).round();
    switch (preview.mode) {
      case TimelineInteractionMode.move:
        _previewsById.updateAll((id, movingPreview) {
          final duration =
              movingPreview.originalEndFrame - movingPreview.originalStartFrame;
          final nextStart = math.max(
            0,
            movingPreview.originalStartFrame + frameDelta,
          );
          return movingPreview.copyWith(
            startFrame: nextStart,
            endFrame: nextStart + duration,
          );
        });
      case TimelineInteractionMode.resizeStart:
        final nextStart = math.max(
          0,
          math.min(
            preview.originalEndFrame,
            preview.originalStartFrame + frameDelta,
          ),
        );
        _previewsById[preview.id] = preview.copyWith(startFrame: nextStart);
      case TimelineInteractionMode.resizeEnd:
        final nextEnd = math.max(
          preview.originalStartFrame,
          preview.originalEndFrame + frameDelta,
        );
        _previewsById[preview.id] = preview.copyWith(endFrame: nextEnd);
    }
    notifyListeners();
  }

  TimelinePreview? finishInteraction() {
    final preview = this.preview;
    _activePreviewId = null;
    _previewsById.clear();
    notifyListeners();
    return preview;
  }

  List<TimelinePreview> finishInteractionSession() {
    final sessionPreviews = previews;
    _activePreviewId = null;
    _previewsById.clear();
    notifyListeners();
    return sessionPreviews;
  }

  void cancelInteraction() {
    if (preview == null) return;
    _activePreviewId = null;
    _previewsById.clear();
    notifyListeners();
  }
}
