import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final elementValuePath = editorRootPath;
final elementPlacementPath = editorRootPath.field("placement");

final placementRootTypeRef = skir.TypeDefinitionId(
  typeId: skir.TypeId.createDeclared(value: "d134aec7caa54a288ab42275756cfe8d"),
  revision: 1,
);
final graphPlacementTypeRef = skir.TypeDefinitionId(
  typeId: skir.TypeId.createDeclared(value: "578f0d42bc964b1fab52c8de5e02f9c5"),
  revision: 1,
);
final timelineEntryPlacementTypeRef = skir.TypeDefinitionId(
  typeId: skir.TypeId.createDeclared(value: "bf3c5268557a4dfba0e7c1f72d3e67bd"),
  revision: 1,
);
final timelineSegmentPlacementTypeRef = skir.TypeDefinitionId(
  typeId: skir.TypeId.createDeclared(value: "54e38e56871243d2ae747ed6c0083381"),
  revision: 1,
);
final timelineKeyframePlacementTypeRef = skir.TypeDefinitionId(
  typeId: skir.TypeId.createDeclared(value: "e0369811aac94bf6a291f65d1c719e1b"),
  revision: 1,
);

const placementTypeRefs = PlacementTypeReferences();

final class PlacementTypeReferences {
  const PlacementTypeReferences();

  skir.TypeDefinitionId get root => placementRootTypeRef;
  skir.TypeDefinitionId get graph => graphPlacementTypeRef;
  skir.TypeDefinitionId get timelineEntry => timelineEntryPlacementTypeRef;
  skir.TypeDefinitionId get timelineSegment => timelineSegmentPlacementTypeRef;
  skir.TypeDefinitionId get timelineKeyframe =>
      timelineKeyframePlacementTypeRef;
}

sealed class Placement {
  const Placement();

  skir.TypeDefinitionId get concreteType;
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
  skir.TypeDefinitionId get concreteType => graphPlacementTypeRef;

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
  skir.TypeDefinitionId get concreteType => timelineEntryPlacementTypeRef;

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
  skir.TypeDefinitionId get concreteType => timelineSegmentPlacementTypeRef;

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
  skir.TypeDefinitionId get concreteType => timelineKeyframePlacementTypeRef;

  @override
  bool operator ==(Object other) =>
      other is TimelineKeyframePlacement && frame == other.frame;

  @override
  int get hashCode => frame.hashCode;
}

Placement decodePlacement(skir.DataValue value) {
  final named = value is skir.DataValue_namedWrapper ? value.value : null;
  final fields = named?.payload.authoredRecord?.fields;
  if (named == null || fields == null) {
    throw ArgumentError("Placement must be polymorphic record data");
  }
  int number(String key) => fields
      .singleWhere((field) => field.name == key)
      .value
      .authoredInteger!
      .toInt();
  return switch (named.actualType.definition) {
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
      "Unknown placement concrete type ${named.actualType.definition}",
    ),
  };
}

skir.DataValue placementValue(Placement placement) {
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
  final fields = switch (placement) {
    GraphPlacement(:final x, :final y, :final width, :final height) => {
      "x": x,
      "y": y,
      "width": width,
      "height": height,
    },
    TimelineSegmentPlacement(:final startFrame, :final endFrame) => {
      "startFrame": startFrame,
      "endFrame": endFrame,
    },
    TimelineKeyframePlacement(:final frame) => {"frame": frame},
    TimelineEntryPlacement(:final trackIndex) => {"trackIndex": trackIndex},
  };
  return skir.DataValue.createNamed(
    actualType: skir.NamedTypeUse(
      definition: placement.concreteType,
      arguments: const [],
    ),
    payload: skir.DataValue.createRecord(
      fields: fields.entries.map(
        (field) => skir.FieldValue(
          name: field.key,
          value: skir.DataValue.wrapInteger(field.value.toString()),
        ),
      ),
    ),
  );
}
