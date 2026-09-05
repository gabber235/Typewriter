part of "page_elements.dart";

final class CachedPageEntry {
  const CachedPageEntry({required this.pageId, required this.definition});

  final String pageId;
  final EntryDefinition definition;
}

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

@Freezed(unionKey: "_kind")
abstract class PageElement with _$PageElement {
  const factory PageElement.entry({required PageEntry entry}) =
      PageElementEntry;

  const factory PageElement.cue({required Cue cue}) = PageElementCue;
}

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
}

extension on RecordValue {
  RecordValue updatedAt(DataPath path, DataValue value) {
    final updated = path.replace(this, value).valueOrNull;
    return updated is RecordValue ? updated : this;
  }
}

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
