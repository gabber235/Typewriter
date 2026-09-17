import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Paths in the editor document that map to the wire element operation.
///
/// The typed value is encoded relative to this wrapper. Placement is encoded as
/// a separate protocol variant because it belongs to the page editor rather
/// than to the element's declared content type.
final elementValuePath = DataPath.root.field("value");
final elementPlacementPath = DataPath.root.field("placement");

/// Converts a wire placement variant to the editor's uniform record shape.
///
/// Each variant exposes only its meaningful integer fields. Unknown protocol
/// variants fail loudly because silently inventing placement would move an
/// element to an incorrect editor location.
RecordValue elementPlacementValue(skir.ElementPlacement placement) =>
    RecordValue({
      for (final entry in switch (placement) {
        skir.ElementPlacement_graphWrapper(:final value) => {
          "x": value.x,
          "y": value.y,
          "width": value.width,
          "height": value.height,
        },
        skir.ElementPlacement_timelineSegmentWrapper(:final value) => {
          "start": value.startFrame,
          "end": value.endFrame,
        },
        skir.ElementPlacement_timelineKeyframeWrapper(:final value) => {
          "frame": value.frame,
        },
        skir.ElementPlacement_timelineEntryWrapper(:final value) => {
          "track": value.trackIndex,
        },
        skir.ElementPlacement_unknown() => throw ArgumentError(
          "Unknown element placement",
        ),
      }.entries)
        entry.key: entry.value.asValue,
    });

/// Builds the editor type matching [elementPlacementValue].
RecordType elementPlacementType(skir.ElementPlacement placement) => RecordType(
  fields: {
    for (final key in elementPlacementValue(placement).fields.keys)
      key: TypeField(
        name: key,
        type: const IntegerType(width: IntegerWidth.signed32),
      ),
  },
);

/// Validates and converts an editor placement record to the wire variant.
///
/// Dimensions must be positive, timeline ranges must be ordered and
/// nonnegative, and frames must be nonnegative. Invalid shapes are rejected
/// before a mutation reaches the transport boundary.
skir.ElementPlacement encodeElementPlacement(DataValue value) {
  if (value is! RecordValue) {
    throw ArgumentError("Element placement must be a record");
  }
  int number(String key) => (value.fields[key]! as IntegerValue).value.toInt();
  if (value.fields.containsKey("x") &&
      number("width") > 0 &&
      number("height") > 0) {
    return skir.ElementPlacement.createGraph(
      x: number("x"),
      y: number("y"),
      width: number("width"),
      height: number("height"),
    );
  }
  if (value.fields.containsKey("start") &&
      number("start") >= 0 &&
      number("end") >= number("start")) {
    return skir.ElementPlacement.createTimelineSegment(
      startFrame: number("start"),
      endFrame: number("end"),
    );
  }
  if (value.fields.containsKey("frame") && number("frame") >= 0) {
    return skir.ElementPlacement.createTimelineKeyframe(frame: number("frame"));
  }
  if (value.fields.containsKey("track")) {
    return skir.ElementPlacement.createTimelineEntry(
      trackIndex: number("track"),
    );
  }
  throw ArgumentError("Invalid element placement");
}
