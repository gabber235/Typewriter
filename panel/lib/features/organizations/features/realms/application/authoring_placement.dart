import "package:typewriter_panel/typewriter_panel.dart";

final elementValuePath = DataPath.root;
final elementPlacementPath = DataPath.root.field("placement");

final placementRootTypeRef = ResolvedTypeRef(
  id: TypeId.declared("d134aec7caa54a288ab42275756cfe8d"),
  revision: 1,
);
final graphPlacementTypeRef = ResolvedTypeRef(
  id: TypeId.declared("578f0d42bc964b1fab52c8de5e02f9c5"),
  revision: 1,
);
final timelineEntryPlacementTypeRef = ResolvedTypeRef(
  id: TypeId.declared("bf3c5268557a4dfba0e7c1f72d3e67bd"),
  revision: 1,
);
final timelineSegmentPlacementTypeRef = ResolvedTypeRef(
  id: TypeId.declared("54e38e56871243d2ae747ed6c0083381"),
  revision: 1,
);
final timelineKeyframePlacementTypeRef = ResolvedTypeRef(
  id: TypeId.declared("e0369811aac94bf6a291f65d1c719e1b"),
  revision: 1,
);

const placementTypeRefs = PlacementTypeReferences();

final class PlacementTypeReferences {
  const PlacementTypeReferences();

  ResolvedTypeRef get root => placementRootTypeRef;
  ResolvedTypeRef get graph => graphPlacementTypeRef;
  ResolvedTypeRef get timelineEntry => timelineEntryPlacementTypeRef;
  ResolvedTypeRef get timelineSegment => timelineSegmentPlacementTypeRef;
  ResolvedTypeRef get timelineKeyframe => timelineKeyframePlacementTypeRef;
}

sealed class Placement {
  const Placement();

  ResolvedTypeRef get concreteType;
}

final class GraphPlacement extends Placement {
  const GraphPlacement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  @override
  ResolvedTypeRef get concreteType => graphPlacementTypeRef;

  GraphPlacement copyWith({int? x, int? y, int? width, int? height}) =>
      GraphPlacement(
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  @override
  bool operator ==(Object other) =>
      other is GraphPlacement &&
      x == other.x &&
      y == other.y &&
      width == other.width &&
      height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);
}

final class TimelineEntryPlacement extends Placement {
  const TimelineEntryPlacement({required this.trackIndex});

  final int trackIndex;

  @override
  ResolvedTypeRef get concreteType => timelineEntryPlacementTypeRef;

  @override
  bool operator ==(Object other) =>
      other is TimelineEntryPlacement && trackIndex == other.trackIndex;

  @override
  int get hashCode => trackIndex.hashCode;
}

final class TimelineSegmentPlacement extends Placement {
  const TimelineSegmentPlacement({
    required this.startFrame,
    required this.endFrame,
  });

  final int startFrame;
  final int endFrame;

  @override
  ResolvedTypeRef get concreteType => timelineSegmentPlacementTypeRef;

  @override
  bool operator ==(Object other) =>
      other is TimelineSegmentPlacement &&
      startFrame == other.startFrame &&
      endFrame == other.endFrame;

  @override
  int get hashCode => Object.hash(startFrame, endFrame);
}

final class TimelineKeyframePlacement extends Placement {
  const TimelineKeyframePlacement({required this.frame});

  final int frame;

  @override
  ResolvedTypeRef get concreteType => timelineKeyframePlacementTypeRef;

  @override
  bool operator ==(Object other) =>
      other is TimelineKeyframePlacement && frame == other.frame;

  @override
  int get hashCode => frame.hashCode;
}

Placement decodePlacement(DataValue value) {
  if (value is! PolymorphicValue || value.value is! RecordValue) {
    throw ArgumentError("Placement must be polymorphic record data");
  }
  final fields = (value.value as RecordValue).fields;
  int number(String key) => (fields[key]! as IntegerValue).value.toInt();
  return switch (value.concreteType) {
    final type when type == placementTypeRefs.graph => GraphPlacement(
      x: number("x"),
      y: number("y"),
      width: number("width"),
      height: number("height"),
    ),
    final type when type == placementTypeRefs.timelineEntry =>
      TimelineEntryPlacement(trackIndex: number("trackIndex")),
    final type when type == placementTypeRefs.timelineSegment =>
      TimelineSegmentPlacement(
        startFrame: number("startFrame"),
        endFrame: number("endFrame"),
      ),
    final type when type == placementTypeRefs.timelineKeyframe =>
      TimelineKeyframePlacement(frame: number("frame")),
    _ => throw ArgumentError(
      "Unknown placement concrete type ${value.concreteType}",
    ),
  };
}

TypedValueEnvelope encodePlacement(
  ResolvedTypeRef rootType,
  Placement placement,
) => TypedValueEnvelope(
  rootType: rootType,
  rootValue: placementValue(placement),
);

PolymorphicValue placementValue(Placement placement) {
  switch (placement) {
    case GraphPlacement(:final width, :final height)
        when width <= 0 || height <= 0:
      throw ArgumentError("Graph placement dimensions must be positive");
    case TimelineEntryPlacement(:final trackIndex) when trackIndex < 0:
      throw ArgumentError("Timeline track index must not be negative");
    case TimelineSegmentPlacement(:final startFrame, :final endFrame)
        when startFrame < 0 || endFrame < startFrame:
      throw ArgumentError("Timeline segment frames are invalid");
    case TimelineKeyframePlacement(:final frame) when frame < 0:
      throw ArgumentError("Timeline keyframe must not be negative");
    default:
  }
  return PolymorphicValue(
    concreteType: placement.concreteType,
    value: RecordValue(switch (placement) {
      GraphPlacement(:final x, :final y, :final width, :final height) => {
        "x": x.asValue,
        "y": y.asValue,
        "width": width.asValue,
        "height": height.asValue,
      },
      TimelineSegmentPlacement(:final startFrame, :final endFrame) => {
        "startFrame": startFrame.asValue,
        "endFrame": endFrame.asValue,
      },
      TimelineKeyframePlacement(:final frame) => {"frame": frame.asValue},
      TimelineEntryPlacement(:final trackIndex) => {
        "trackIndex": trackIndex.asValue,
      },
    }),
  );
}
