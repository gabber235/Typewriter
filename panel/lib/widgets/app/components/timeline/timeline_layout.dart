import "package:collection/collection.dart";
import "package:json_annotation/json_annotation.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_controller.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_data.dart";

part "timeline_layout.g.dart";

class TimelineLayoutEngine {
  const TimelineLayoutEngine();

  TimelineLayoutResult build({
    required TimelineData data,
    List<TimelinePreview> previews = const [],
  }) {
    final previewById = {for (final item in previews) item.id: item};

    final tracks = data.tracks
        .map((track) => _buildTrackLayout(track, previewById))
        .toList();

    return TimelineLayoutResult(tracks: tracks);
  }

  TimelineTrackLayout _buildTrackLayout(
    TimelineTrack track,
    Map<TimelineIdentifier, TimelinePreview> previewsById,
  ) {
    final (placements, laneCount) = _layoutBlocks(
      trackId: track.id,
      elements: track.elements,
      previewState: TimelinePreviewState.none,
      previewsById: previewsById,
    );
    return TimelineTrackLayout(
      track: track,
      laneCount: laneCount,
      placements: placements,
    );
  }

  TimelineTrackBlock _buildTrackBlock({
    required TimelineIdentifier trackId,
    required TimelineElement element,
    required TimelinePreviewState previewState,
    required Map<TimelineIdentifier, TimelinePreview> previewsById,
  }) {
    final preview = previewsById[element.id];
    final currentPreviewState = preview != null
        ? TimelinePreviewState.related
        : previewState;

    if (element is TimelineKeyframe) {
      return TimelineTrackBlock(
        trackId: trackId,
        element: element,
        previewState: currentPreviewState,
        height: 1,
        children: const [],
      );
    }
    if (element is! TimelineSegment) {
      throw StateError("Unexpected element type: ${element.runtimeType}");
    }

    if (element.children.isEmpty) {
      return TimelineTrackBlock(
        trackId: trackId,
        element: element,
        previewState: currentPreviewState,
        height: 1,
        children: const [],
      );
    }

    final (reservedPlacements, height) = _layoutBlocks(
      trackId: trackId,
      elements: element.children,
      previewState: preview != null
          ? TimelinePreviewState.related
          : previewState,
      previewsById: previewsById,
    );

    return TimelineTrackBlock(
      trackId: trackId,
      element: element,
      previewState: currentPreviewState,
      height: height,
      children: reservedPlacements,
    );
  }

  (List<TimelineTrackBlockPlacement>, int) _layoutBlocks({
    required TimelineIdentifier trackId,
    required List<TimelineElement> elements,
    required TimelinePreviewState previewState,
    required Map<TimelineIdentifier, TimelinePreview> previewsById,
  }) {
    final childrenBlocks = elements
        .map((child) {
          return _buildTrackBlock(
            trackId: trackId,
            element: child,
            previewState: previewState,
            previewsById: previewsById,
          );
        })
        .sorted((a, b) {
          final durationCompare = b.element.frameDuration.compareTo(
            a.element.frameDuration,
          );
          if (durationCompare != 0) return durationCompare;

          final startCompare = a.element.startFrame.compareTo(
            b.element.startFrame,
          );
          if (startCompare != 0) return startCompare;

          final endCompare = b.element.endFrame.compareTo(a.element.endFrame);
          if (endCompare != 0) return endCompare;

          return a.element.id.id.compareTo(b.element.id.id);
        });

    final placements = _placeBlocks(childrenBlocks);
    final reservedPlacements = _reservePreviewLanes(placements, previewsById);

    final height =
        reservedPlacements
            .map((placement) => placement.lane + placement.height)
            .maxOrNull ??
        0;

    return (reservedPlacements, height + 1);
  }

  List<TimelineTrackBlockPlacement> _placeBlocks(
    List<TimelineTrackBlock> blocks,
  ) {
    final placements = <TimelineTrackBlockPlacement>[];

    final laneOccupancy = _LaneOccupancy();

    for (final block in blocks) {
      final laneIndex = laneOccupancy.claimFirstAvailableBlock(
        startFrame: block.element.startFrame,
        endFrame: block.element.endFrame,
        height: block.height,
      );
      final placement = TimelineTrackBlockPlacement(
        block: block,
        lane: laneIndex,
      );
      placements.add(placement);
    }
    return placements;
  }

  List<TimelineTrackBlockPlacement> _reservePreviewLanes(
    List<TimelineTrackBlockPlacement> placements,
    Map<TimelineIdentifier, TimelinePreview> previewsById,
  ) {
    if (previewsById.isEmpty) return placements;
    final previewPlacements = placements.where((placement) {
      final preview = previewsById[placement.block.element.id];
      return preview != null;
    }).toSet();

    if (previewPlacements.isEmpty) return placements;

    final newPlacements = <TimelineTrackBlockPlacement>[];
    final laneOccupancy = _LaneOccupancy();

    for (final placement in previewPlacements) {
      final preview = previewsById[placement.block.element.id];
      if (preview == null) continue;
      final actualLane = laneOccupancy.tryReserveLane(
        laneIndex: placement.lane,
        startFrame: preview.startFrame,
        endFrame: preview.endFrame,
        height: placement.height,
      );
      newPlacements.add(
        TimelineTrackBlockPlacement(
          block: TimelineTrackBlock(
            trackId: placement.block.trackId,
            element: placement.block.element.applyPreview(preview),
            previewState: placement.block.previewState,
            height: placement.height,
            children: placement.block.children,
          ),
          lane: actualLane,
        ),
      );
    }

    for (final placement in placements) {
      if (previewsById.containsKey(placement.block.element.id)) {
        continue;
      }
      final laneIndex = laneOccupancy.claimFirstAvailableBlock(
        startFrame: placement.element.startFrame,
        endFrame: placement.element.endFrame,
        height: placement.height,
      );
      if (placement.lane == laneIndex) {
        newPlacements.add(placement);
        continue;
      }

      newPlacements.add(
        TimelineTrackBlockPlacement(block: placement.block, lane: laneIndex),
      );
    }

    assert(newPlacements.length == placements.length);

    return newPlacements;
  }
}

class _LaneOccupancy {
  _LaneOccupancy();

  final List<List<_FrameRange>> _rangesByLane = [];

  int get laneCount => _rangesByLane.length;

  int claimFirstAvailableBlock({
    required int startFrame,
    required int endFrame,
    required int height,
  }) {
    final laneIndex = firstAvailableBlock(
      startFrame: startFrame,
      endFrame: endFrame,
      height: height,
    );

    reserveBlock(
      laneIndex: laneIndex,
      startFrame: startFrame,
      endFrame: endFrame,
      height: height,
    );

    return laneIndex;
  }

  int firstAvailableBlock({
    required int startFrame,
    required int endFrame,
    required int height,
  }) {
    var laneIndex = 0;
    outer:
    while (laneIndex < _rangesByLane.length) {
      for (var offset = 0; offset < height; offset++) {
        if (!_canUseLane(
          laneIndex: laneIndex + offset,
          startFrame: startFrame,
          endFrame: endFrame,
        )) {
          laneIndex += offset + 1;
          continue outer;
        }
      }

      return laneIndex;
    }
    return _rangesByLane.length;
  }

  void _ensureLaneRanges(int laneIndex) {
    while (_rangesByLane.length < laneIndex + 1) {
      _rangesByLane.add([]);
    }
  }

  void reserveBlock({
    required int laneIndex,
    required int startFrame,
    required int endFrame,
    required int height,
  }) {
    _ensureLaneRanges(laneIndex + height);

    final range = _FrameRange(startFrame: startFrame, endFrame: endFrame);
    for (var offset = 0; offset < height; offset++) {
      _rangesByLane[laneIndex + offset].add(range);
    }
  }

  int tryReserveLane({
    required int laneIndex,
    required int startFrame,
    required int endFrame,
    required int height,
  }) {
    var canReserveLane = true;
    for (var offset = 0; offset < height; offset++) {
      if (!_canUseLane(
        laneIndex: laneIndex + offset,
        startFrame: startFrame,
        endFrame: endFrame,
      )) {
        canReserveLane = false;
        break;
      }
    }

    if (canReserveLane) {
      reserveBlock(
        laneIndex: laneIndex,
        startFrame: startFrame,
        endFrame: endFrame,
        height: height,
      );
      return laneIndex;
    }

    return firstAvailableBlock(
      startFrame: startFrame,
      endFrame: endFrame,
      height: height,
    );
  }

  bool _canUseLane({
    required int laneIndex,
    required int startFrame,
    required int endFrame,
  }) {
    if (laneIndex >= _rangesByLane.length) return true;
    return _rangesByLane[laneIndex].none(
      (range) => range.overlaps(startFrame: startFrame, endFrame: endFrame),
    );
  }
}

class _FrameRange {
  const _FrameRange({required this.startFrame, required this.endFrame});
  final int startFrame;
  final int endFrame;

  bool overlaps({required int startFrame, required int endFrame}) {
    return this.endFrame >= startFrame && this.startFrame <= endFrame;
  }
}

class TimelineLayoutResult {
  TimelineLayoutResult({required this.tracks}) {
    void collect(TimelineTrackBlockPlacement placement) {
      placementsById[placement.element.id] = placement;
      for (final child in placement.children) {
        collect(child);
      }
    }

    for (final track in tracks) {
      for (final element in track.placements) {
        collect(element);
      }
    }
  }

  final List<TimelineTrackLayout> tracks;

  final Map<TimelineIdentifier, TimelineTrackBlockPlacement> placementsById =
      {};
}

@JsonSerializable(createFactory: false)
class TimelineTrackLayout {
  const TimelineTrackLayout({
    required this.track,
    required this.laneCount,
    required this.placements,
  });

  final TimelineTrack track;
  final int laneCount;
  final List<TimelineTrackBlockPlacement> placements;

  Map<String, dynamic> toJson() => _$TimelineTrackLayoutToJson(this);
}
