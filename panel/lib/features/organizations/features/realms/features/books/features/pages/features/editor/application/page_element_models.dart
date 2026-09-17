part of "page_elements.dart";

/// Entry definition indexed by its owning page for mutation routing.
final class CachedPageEntry {
  const CachedPageEntry({required this.pageId, required this.definition});

  final String pageId;
  final EntryDefinition definition;
}

/// Compilation state and diagnostics exposed for one page document.
///
/// A blocked document may still have [activeManifestId], which identifies the
/// last valid version the engine can run while authoring remains repairable.
final class PageDocumentHealth {
  const PageDocumentHealth({
    required this.diagnostics,
    required this.compileBlocked,
    required this.activeManifestId,
  });

  final List<String> diagnostics;
  final bool compileBlocked;
  final String? activeManifestId;
}

/// A decoded page document element, either an entry or a timeline cue.
///
/// This is a presentation ready projection, not the persistence authority.
/// Its value and placement can be overlaid by a local draft and later encoded
/// back into the wire document by the mutation pipeline.
@Freezed(unionKey: "_kind")
abstract class PageElement with _$PageElement {
  const factory PageElement.entry({required PageEntry entry}) =
      PageElementEntry;

  const factory PageElement.cue({required Cue cue}) = PageElementCue;
}

/// Provides stable identity and placement operations across entry and cue variants.
extension PageElementId on PageElement {
  String get id => switch (this) {
    PageElementEntry(:final entry) => entry.id,
    PageElementCue(:final cue) => cue.id,
    _ => throw StateError("Unknown page element type"),
  };

  PageElement moveTo(int x, int y) => switch (this) {
    PageElementEntry(:final entry) => PageElement.entry(
      entry: switch (entry) {
        DefinitionPageEntry() => entry.copyWith.definition.placement(
          x: x,
          y: y,
        ),
        MissingElementDefinitionPageEntry() => entry.copyWith.placement(
          x: x,
          y: y,
        ),
        _ => entry,
      },
    ),
    _ => this,
  };

  PageElement resizeTo(int width, int height) => switch (this) {
    PageElementEntry(:final entry) => PageElement.entry(
      entry: switch (entry) {
        DefinitionPageEntry() => entry.copyWith.definition.placement(
          width: width,
          height: height,
        ),
        MissingElementDefinitionPageEntry() => entry.copyWith.placement(
          width: width,
          height: height,
        ),
        _ => entry,
      },
    ),
    _ => this,
  };

  PageElement updateCueTo(int startFrame, int endFrame) => switch (this) {
    PageElementCue(:final cue) => PageElement.cue(
      cue: switch (cue) {
        Segment() => cue.copyWith(startFrame: startFrame, endFrame: endFrame),
        Keyframe() => cue.copyWith(frame: startFrame),
        _ => cue,
      },
    ),
    _ => this,
  };

  PageElement updateFieldValue(DataPath path, DataValue value) =>
      switch (this) {
        PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
          PageElement.entry(
            entry: PageEntry.definition(
              definition: definition.copyWith(
                data: definition.data.updatedAt(path, value),
              ),
            ),
          ),
        PageElementCue(:final cue) => PageElement.cue(
          cue: switch (cue) {
            Segment() => cue.copyWith(data: cue.data.updatedAt(path, value)),
            Keyframe() => cue.copyWith(data: cue.data.updatedAt(path, value)),
            _ => cue,
          },
        ),
        _ => this,
      };

  RecordValue? get editorValue => switch (this) {
    PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
      RecordValue({
        "value": definition.data,
        "placement": elementPlacementValue(switch (definition.placement.kind) {
          EntryPlacementKind.graph => skir.ElementPlacement.createGraph(
            x: definition.placement.x,
            y: definition.placement.y,
            width: definition.placement.width,
            height: definition.placement.height,
          ),
          EntryPlacementKind.timelineEntry =>
            skir.ElementPlacement.createTimelineEntry(
              trackIndex: definition.placement.x,
            ),
        }),
      }),
    PageElementCue(:final cue) when cue is Segment => RecordValue({
      "value": cue.data,
      "placement": elementPlacementValue(
        skir.ElementPlacement.createTimelineSegment(
          startFrame: cue.startFrame,
          endFrame: cue.endFrame,
        ),
      ),
    }),
    PageElementCue(:final cue) when cue is Keyframe => RecordValue({
      "value": cue.data,
      "placement": elementPlacementValue(
        skir.ElementPlacement.createTimelineKeyframe(frame: cue.frame),
      ),
    }),
    _ => null,
  };

  PageElement projected(LocalEditorValue? local) {
    final canonical = editorValue;
    if (local == null || canonical == null) return this;
    final root = local.projectOnto(canonical);
    if (root is! RecordValue) return this;
    final data = root.fields["value"];
    final placement = root.fields["placement"];
    if (data is! RecordValue || placement == null) return this;
    final withData = switch (this) {
      PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
        PageElement.entry(
          entry: PageEntry.definition(
            definition: definition.copyWith(data: data),
          ),
        ),
      PageElementCue(:final cue) => PageElement.cue(
        cue: switch (cue) {
          Segment() => cue.copyWith(data: data),
          Keyframe() => cue.copyWith(data: data),
          _ => cue,
        },
      ),
      _ => this,
    };
    try {
      return switch (encodeElementPlacement(placement)) {
        skir.ElementPlacement_graphWrapper(:final value) =>
          withData.moveTo(value.x, value.y).resizeTo(value.width, value.height),
        skir.ElementPlacement_timelineEntryWrapper(:final value) =>
          withData.moveTo(value.trackIndex, 0),
        skir.ElementPlacement_timelineSegmentWrapper(:final value) =>
          withData.updateCueTo(value.startFrame, value.endFrame),
        skir.ElementPlacement_timelineKeyframeWrapper(:final value) =>
          withData.updateCueTo(value.frame, value.frame),
        _ => withData,
      };
    } on ArgumentError {
      return this;
    }
  }
}

extension on RecordValue {
  RecordValue updatedAt(DataPath path, DataValue value) {
    final updated = path.replace(this, value).valueOrNull;
    return updated is RecordValue ? updated : this;
  }
}

/// A directional link between element identifiers at a typed data path.
///
/// The decoder derives incoming and outgoing links from the document reference
/// list. Keeping the link direction in the projection lets graph consumers
/// render edges without reading the wire document directly.
@freezed
abstract class ElementLink with _$ElementLink {
  @Assert("linkId != \"\"", "Link ID must not be empty.")
  @Assert("otherId != \"\"", "Other ID must not be empty.")
  const factory ElementLink({
    required String linkId,
    required String otherId,
    required String path,
  }) = _ElementLink;

  factory ElementLink.fromJson(Map<String, dynamic> json) =>
      _$ElementLinkFromJson(json);
}
