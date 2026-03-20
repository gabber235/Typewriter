import "dart:math" as math;

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_controller.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_data.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_style.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_viewport.dart";

class TimelineLayoutEngine {
  const TimelineLayoutEngine({required this.style});

  final TimelineStyle style;

  TimelineLayoutResult build({
    required TimelineData data,
    required TimelineViewport viewport,
    TimelinePreview? preview,
  }) {
    final tracks = <TimelineTrackLayout>[];
    var currentTop = style.trackGap;

    for (var index = 0; index < data.tracks.length; index++) {
      final track = data.tracks[index];
      final baseElements = track.elements.sorted();
      final previewElements = _previewElements(baseElements, preview);
      final laneLayout = preview == null
          ? _layoutSiblings(baseElements)
          : _layoutPreviewSiblings(
              baseElements: baseElements,
              previewElements: previewElements,
              activeElementId: preview.id,
            );
      final previewStates = _previewStates(previewElements, preview?.id);
      final placed = <TimelinePlacedElement>[];

      for (final element in _flatten(previewElements)) {
        if (!_isVisible(element, viewport)) continue;

        final laneIndex = laneLayout.laneByElementId[element.id.id] ?? 0;
        final top =
            currentTop +
            style.trackPadding +
            laneIndex * (style.laneHeight + style.laneGap) -
            viewport.verticalOffset;
        placed.add(
          TimelinePlacedElement(
            trackId: track.id,
            element: element,
            laneIndex: laneIndex,
            rect: _elementRect(element: element, viewport: viewport, top: top),
            previewState:
                previewStates[element.id.id] ?? TimelinePreviewState.none,
          ),
        );
      }

      final laneCount = math.max(1, laneLayout.laneCount);
      final height =
          style.trackPadding * 2 +
          laneCount * style.laneHeight +
          (laneCount - 1) * style.laneGap;
      tracks.add(
        TimelineTrackLayout(
          track: track,
          top: currentTop - viewport.verticalOffset,
          contentTop: currentTop,
          height: height,
          laneCount: laneCount,
          elements: placed,
          backgroundColor: index.isEven
              ? style.palette.trackBackground
              : style.palette.trackAltBackground,
        ),
      );
      currentTop += height + style.trackGap;
    }

    final contentWidth = math.max(
      viewport.planeWidth,
      (_maxFrame(data, preview) + style.trailingFrames + 1) *
          viewport.pixelsPerFrame,
    );

    return TimelineLayoutResult(
      tracks: tracks,
      contentHeight: math.max(viewport.planeHeight, currentTop),
      contentWidth: contentWidth,
    );
  }

  List<TimelineElement> _previewElements(
    List<TimelineElement> baseElements,
    TimelinePreview? preview,
  ) {
    return [
      for (final element in baseElements)
        _applyPreview(element: element, preview: preview),
    ];
  }

  TimelineElement _applyPreview({
    required TimelineElement element,
    required TimelinePreview? preview,
    int inheritedFrameDelta = 0,
  }) {
    final shifted = _shiftElement(
      element: element,
      frameDelta: inheritedFrameDelta,
    );
    if (preview == null) return shifted;

    final isActive = shifted.id.id == preview.id;

    if (shifted case TimelineKeyframe()) {
      if (!isActive) return shifted;
      return TimelineKeyframe(
        id: shifted.id,
        frame: preview.startFrame,
        builder: shifted.builder,
        color: shifted.color,
      );
    }

    final segment = shifted as TimelineSegment;
    if (!isActive) {
      return TimelineSegment(
        id: segment.id,
        startFrame: segment.startFrame,
        endFrame: segment.endFrame,
        builder: segment.builder,
        color: segment.color,
        children: [
          for (final child in segment.children)
            _applyPreview(
              element: child,
              preview: preview,
              inheritedFrameDelta: inheritedFrameDelta,
            ),
        ],
      );
    }

    final shiftedStart = segment.startFrame;
    final movedSegment = TimelineSegment(
      id: segment.id,
      startFrame: preview.startFrame,
      endFrame: preview.endFrame,
      builder: segment.builder,
      color: segment.color,
      children: const [],
    );
    final descendantDelta = switch (preview.mode) {
      TimelineInteractionMode.move => preview.startFrame - shiftedStart,
      TimelineInteractionMode.resizeStart => preview.startFrame - shiftedStart,
      TimelineInteractionMode.resizeEnd => 0,
    };

    return TimelineSegment(
      id: movedSegment.id,
      startFrame: movedSegment.startFrame,
      endFrame: movedSegment.endFrame,
      builder: movedSegment.builder,
      color: movedSegment.color,
      children: [
        for (final child in segment.children)
          _applyPreview(
            element: child,
            preview: preview,
            inheritedFrameDelta: inheritedFrameDelta + descendantDelta,
          ),
      ],
    );
  }

  TimelineElement _shiftElement({
    required TimelineElement element,
    required int frameDelta,
  }) {
    if (frameDelta == 0) return element;

    return switch (element) {
      TimelineKeyframe() => TimelineKeyframe(
        id: element.id,
        frame: element.frame + frameDelta,
        builder: element.builder,
        color: element.color,
      ),
      TimelineSegment() => TimelineSegment(
        id: element.id,
        startFrame: element.startFrame + frameDelta,
        endFrame: element.endFrame + frameDelta,
        builder: element.builder,
        color: element.color,
        children: [
          for (final child in element.children)
            _shiftElement(element: child, frameDelta: frameDelta),
        ],
      ),
    };
  }

  _LaneLayout _layoutSiblings(List<TimelineElement> elements) {
    final sortedElements = elements.sorted();
    final occupancy = _LaneOccupancy();
    final laneByElementId = <String, int>{};

    for (final element in sortedElements) {
      final subtreeLayout = _layoutSubtree(element);
      final laneIndex = occupancy.firstAvailableLane(
        width: subtreeLayout.laneCount,
        startFrame: element.startFrame,
        endFrame: element.endFrame,
      );
      occupancy.reserveBlock(
        laneIndex: laneIndex,
        width: subtreeLayout.laneCount,
        startFrame: element.startFrame,
        endFrame: element.endFrame,
      );

      for (final entry in subtreeLayout.laneByElementId.entries) {
        laneByElementId[entry.key] = laneIndex + entry.value;
      }
    }

    return _LaneLayout(
      laneByElementId: laneByElementId,
      laneCount: math.max(1, occupancy.laneCount),
    );
  }

  _LaneLayout _layoutPreviewSiblings({
    required List<TimelineElement> baseElements,
    required List<TimelineElement> previewElements,
    required String activeElementId,
  }) {
    final activePreviewElement = previewElements.firstWhereOrNull(
      (element) => _containsElement(element, activeElementId),
    );
    if (activePreviewElement == null) {
      return _layoutSiblings(previewElements);
    }

    final baseElementsById = {
      for (final element in baseElements) element.id.id: element,
    };
    final baseLaneLayout = _layoutSiblings(baseElements);
    final occupancy = _LaneOccupancy();
    final laneByElementId = <String, int>{};
    final activeBaseElement = baseElementsById[activePreviewElement.id.id];
    assert(
      activeBaseElement != null,
      "Missing base element ${activePreviewElement.id.id} for preview layout.",
    );
    if (activeBaseElement == null) {
      return _layoutSiblings(previewElements);
    }

    final activeLaneIndex =
        baseLaneLayout.laneByElementId[activePreviewElement.id.id] ?? 0;
    final activeSubtreeLayout = _layoutPreviewSubtree(
      baseElement: activeBaseElement,
      previewElement: activePreviewElement,
      activeElementId: activeElementId,
    );
    occupancy
      ..lockBlock(
        laneIndex: activeLaneIndex,
        width: activeSubtreeLayout.laneCount,
      )
      ..reserveBlock(
        laneIndex: activeLaneIndex,
        width: activeSubtreeLayout.laneCount,
        startFrame: activePreviewElement.startFrame,
        endFrame: activePreviewElement.endFrame,
      );
    for (final entry in activeSubtreeLayout.laneByElementId.entries) {
      laneByElementId[entry.key] = activeLaneIndex + entry.value;
    }

    for (final element in previewElements.sorted()) {
      if (element.id == activePreviewElement.id) continue;

      final baseElement = baseElementsById[element.id.id];
      assert(
        baseElement != null,
        "Missing base element ${element.id.id} for preview layout.",
      );
      if (baseElement == null) continue;

      final subtreeLayout = _layoutPreviewSubtree(
        baseElement: baseElement,
        previewElement: element,
        activeElementId: activeElementId,
      );
      final laneIndex = occupancy.firstAvailableLane(
        width: subtreeLayout.laneCount,
        startFrame: element.startFrame,
        endFrame: element.endFrame,
      );
      occupancy.reserveBlock(
        laneIndex: laneIndex,
        width: subtreeLayout.laneCount,
        startFrame: element.startFrame,
        endFrame: element.endFrame,
      );
      for (final entry in subtreeLayout.laneByElementId.entries) {
        laneByElementId[entry.key] = laneIndex + entry.value;
      }
    }

    return _LaneLayout(
      laneByElementId: laneByElementId,
      laneCount: math.max(1, occupancy.laneCount),
    );
  }

  _LaneLayout _layoutSubtree(TimelineElement element) {
    if (element is TimelineKeyframe) {
      return _LaneLayout(laneByElementId: {element.id.id: 0}, laneCount: 1);
    }

    final segment = element as TimelineSegment;
    if (segment.children.isEmpty) {
      return _LaneLayout(laneByElementId: {segment.id.id: 0}, laneCount: 1);
    }

    final childLayout = _layoutSiblings(segment.children);
    final laneByElementId = <String, int>{segment.id.id: 0};
    for (final entry in childLayout.laneByElementId.entries) {
      laneByElementId[entry.key] = entry.value + 1;
    }

    return _LaneLayout(
      laneByElementId: laneByElementId,
      laneCount: math.max(1, childLayout.laneCount + 1),
    );
  }

  _LaneLayout _layoutPreviewSubtree({
    required TimelineElement baseElement,
    required TimelineElement previewElement,
    required String activeElementId,
  }) {
    if (!_containsElement(previewElement, activeElementId)) {
      return _layoutSubtree(previewElement);
    }

    if (previewElement is TimelineKeyframe) {
      return _LaneLayout(
        laneByElementId: {previewElement.id.id: 0},
        laneCount: 1,
      );
    }

    final previewSegment = previewElement as TimelineSegment;
    final baseSegment = baseElement as TimelineSegment;
    if (previewSegment.children.isEmpty) {
      return _LaneLayout(
        laneByElementId: {previewSegment.id.id: 0},
        laneCount: 1,
      );
    }

    final childLayout = _layoutPreviewSiblings(
      baseElements: baseSegment.children,
      previewElements: previewSegment.children,
      activeElementId: activeElementId,
    );
    final laneByElementId = <String, int>{previewSegment.id.id: 0};
    for (final entry in childLayout.laneByElementId.entries) {
      laneByElementId[entry.key] = entry.value + 1;
    }

    return _LaneLayout(
      laneByElementId: laneByElementId,
      laneCount: math.max(1, childLayout.laneCount + 1),
    );
  }

  Map<String, TimelinePreviewState> _previewStates(
    List<TimelineElement> previewElements,
    String? activeElementId,
  ) {
    if (activeElementId == null) return const {};

    final states = <String, TimelinePreviewState>{};
    final active = _findElement(previewElements, activeElementId);
    if (active == null) return states;

    for (final element in _flatten([active])) {
      states[element.id.id] = TimelinePreviewState.related;
    }
    states[activeElementId] = TimelinePreviewState.active;
    return states;
  }

  bool _containsElement(TimelineElement element, String elementId) {
    if (element.id.id == elementId) return true;
    if (element is! TimelineSegment) return false;
    for (final child in element.children) {
      if (_containsElement(child, elementId)) return true;
    }
    return false;
  }

  TimelineElement? _findElement(
    List<TimelineElement> elements,
    String elementId,
  ) {
    for (final element in elements) {
      if (element.id.id == elementId) return element;
      if (element case TimelineSegment(:final children)) {
        final found = _findElement(children, elementId);
        if (found != null) return found;
      }
    }
    return null;
  }

  Iterable<TimelineElement> _flatten(List<TimelineElement> elements) sync* {
    for (final element in elements) {
      yield element;
      if (element case TimelineSegment(:final children)) {
        yield* _flatten(children);
      }
    }
  }

  bool _isVisible(TimelineElement element, TimelineViewport viewport) {
    final startFrame = element.startFrame;
    final endFrame = element.endFrame;
    return endFrame >= viewport.visibleStartFrame &&
        startFrame <= viewport.visibleEndFrame;
  }

  Rect _elementRect({
    required TimelineElement element,
    required TimelineViewport viewport,
    required double top,
  }) {
    return switch (element) {
      TimelineSegment(startFrame: final startFrame, endFrame: final endFrame) =>
        Rect.fromLTWH(
          viewport.frameToPixel(startFrame),
          top,
          math.max(
            style.minSegmentWidth,
            viewport.frameToPixel(endFrame + 1) -
                viewport.frameToPixel(startFrame),
          ),
          style.laneHeight,
        ),
      TimelineKeyframe(frame: final frame) => Rect.fromCenter(
        center: Offset(
          viewport.frameCenterToPixel(frame),
          top + style.laneHeight / 2,
        ),
        width: style.keyframeWidth,
        height: style.laneHeight,
      ),
    };
  }

  int _maxFrame(TimelineData data, TimelinePreview? preview) {
    var maxFrame = 200;
    for (final track in data.tracks) {
      final previewElements = _previewElements(track.elements, preview);
      for (final element in _flatten(previewElements)) {
        maxFrame = math.max(maxFrame, element.endFrame);
      }
    }
    return maxFrame;
  }
}

class TimelineLayoutResult {
  const TimelineLayoutResult({
    required this.tracks,
    required this.contentHeight,
    required this.contentWidth,
  });

  final List<TimelineTrackLayout> tracks;
  final double contentHeight;
  final double contentWidth;

  Iterable<TimelinePlacedElement> get visibleElements sync* {
    for (final track in tracks) {
      yield* track.elements;
    }
  }
}

class TimelineTrackLayout {
  const TimelineTrackLayout({
    required this.track,
    required this.top,
    required this.contentTop,
    required this.height,
    required this.laneCount,
    required this.elements,
    required this.backgroundColor,
  });

  final TimelineTrack track;
  final double top;
  final double contentTop;
  final double height;
  final int laneCount;
  final List<TimelinePlacedElement> elements;
  final Color backgroundColor;
}

class _LaneOccupancy {
  final List<List<_FrameRange>> _rangesByLane = [];
  final Set<int> _lockedLanes = {};

  int get laneCount => _rangesByLane.length;

  int firstAvailableLane({
    required int width,
    required int startFrame,
    required int endFrame,
  }) {
    for (var laneIndex = 0; laneIndex <= _rangesByLane.length; laneIndex++) {
      if (_canUseLaneBlock(
        laneIndex: laneIndex,
        width: width,
        startFrame: startFrame,
        endFrame: endFrame,
      )) {
        return laneIndex;
      }
    }

    return _rangesByLane.length;
  }

  void reserveBlock({
    required int laneIndex,
    required int width,
    required int startFrame,
    required int endFrame,
  }) {
    while (_rangesByLane.length < laneIndex + width) {
      _rangesByLane.add([]);
    }

    for (var offset = 0; offset < width; offset++) {
      _rangesByLane[laneIndex + offset].add(
        _FrameRange(startFrame: startFrame, endFrame: endFrame),
      );
    }
  }

  void lockBlock({required int laneIndex, required int width}) {
    while (_rangesByLane.length < laneIndex + width) {
      _rangesByLane.add([]);
    }

    for (var offset = 0; offset < width; offset++) {
      _lockedLanes.add(laneIndex + offset);
    }
  }

  bool _canUseLaneBlock({
    required int laneIndex,
    required int width,
    required int startFrame,
    required int endFrame,
  }) {
    for (var offset = 0; offset < width; offset++) {
      final probeIndex = laneIndex + offset;
      if (_lockedLanes.contains(probeIndex)) return false;
      if (probeIndex >= _rangesByLane.length) continue;

      final overlapsExisting = _rangesByLane[probeIndex].any(
        (range) => range.overlaps(startFrame: startFrame, endFrame: endFrame),
      );
      if (overlapsExisting) {
        return false;
      }
    }
    return true;
  }
}

class _LaneLayout {
  const _LaneLayout({required this.laneByElementId, required this.laneCount});

  final Map<String, int> laneByElementId;
  final int laneCount;
}

class _FrameRange {
  const _FrameRange({required this.startFrame, required this.endFrame});

  final int startFrame;
  final int endFrame;

  bool overlaps({required int startFrame, required int endFrame}) {
    return this.endFrame >= startFrame && this.startFrame <= endFrame;
  }
}
