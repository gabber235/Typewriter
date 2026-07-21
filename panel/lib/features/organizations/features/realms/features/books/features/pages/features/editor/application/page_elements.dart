import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "page_elements.freezed.dart";
part "page_elements.g.dart";

@riverpod
class PageElements extends _$PageElements {
  @override
  Future<List<PageElement>> build(String pageId) async {
    throw UnimplementedError();
  }

  void optimisticMoveAll(List<(String, int, int)> changed) {
    final data = state.requireValue;
    final map = <String, (int, int)>{
      for (final e in changed) e.$1: (e.$2, e.$3),
    };
    final newData = data.map((element) {
      final placement = map[element.id];
      if (placement == null) return element;
      return element.moveTo(placement.$1, placement.$2);
    }).toList();

    state = AsyncValue.data(newData);
  }

  void optimisticResizeAll(List<(String, int, int)> changed) {
    final data = state.requireValue;
    final map = <String, (int, int)>{
      for (final e in changed) e.$1: (e.$2, e.$3),
    };
    final newData = data.map((element) {
      final placement = map[element.id];
      if (placement == null) return element;
      return element.resizeTo(placement.$1, placement.$2);
    }).toList();

    state = AsyncValue.data(newData);
  }

  Future<void> moveAll(List<(String, int, int)> changed) async {
    state.ensureReady();
    optimisticMoveAll(changed);

    throw UnimplementedError();
  }

  Future<void> resizeAll(List<(String, int, int)> changed) async {
    state.ensureReady();
    optimisticResizeAll(changed);

    throw UnimplementedError();
  }

  void optimisticCuesUpdate(List<(String, int, int)> changed) {
    final data = state.requireValue;
    final map = <String, (int, int)>{
      for (final entry in changed) entry.$1: (entry.$2, entry.$3),
    };
    final newData = data.map((element) {
      final frameRange = map[element.id];
      if (frameRange == null) return element;
      return element.updateCueTo(frameRange.$1, frameRange.$2);
    }).toList();

    state = AsyncValue.data(newData);
  }

  Future<void> updateCues(List<(String, int, int)> changed) async {
    state.ensureReady();
    optimisticCuesUpdate(changed);
  }

  Future<void> updateCueFieldValue(
    String cueId,
    String path,
    dynamic value,
  ) async {
    state.ensureReady();
    final data = state.requireValue;
    final newData = data.map((element) {
      if (element.id != cueId) return element;
      return element.updateFieldValue(path, value);
    }).toList();

    state = AsyncValue.data(newData);
  }
}

@Freezed(unionKey: "_kind")
abstract class PageElement with _$PageElement {
  const factory PageElement.entry({required PageEntry entry}) =
      PageElementEntry;

  @Assert("id != \"\"", "ID must not be empty.")
  const factory PageElement.group({
    required String id,
    required String name,
    required EntryPlacement placement,
  }) = PageElementGroup;

  const factory PageElement.cue({required Cue cue}) = PageElementCue;

  factory PageElement.fromJson(Map<String, dynamic> json) =>
      _$PageElementFromJson(json);
}

extension PageElementExtension on PageElement {
  String get id => switch (this) {
    PageElementEntry(:final entry) => entry.id,
    PageElementGroup(:final id) => id,
    PageElementCue(:final cue) => cue.id,
    _ => throw StateError("Unknown page element type"),
  };

  PageElement moveTo(int x, int y) {
    return switch (this) {
      PageElementEntry(:final entry) => PageElement.entry(
        entry: switch (entry) {
          DefinitionPageEntry() => entry.copyWith.definition.placement(
            x: x,
            y: y,
          ),
          NoBlueprintPageEntry() => entry.copyWith.placement(x: x, y: y),
          _ => entry,
        },
      ),
      PageElementGroup(:final id, :final name, :final placement) =>
        PageElement.group(
          id: id,
          name: name,
          placement: placement.copyWith(x: x, y: y),
        ),
      _ => this,
    };
  }

  PageElement resizeTo(int width, int height) {
    return switch (this) {
      PageElementEntry(:final entry) => PageElement.entry(
        entry: switch (entry) {
          DefinitionPageEntry() => entry.copyWith.definition.placement(
            width: width,
            height: height,
          ),
          NoBlueprintPageEntry() => entry.copyWith.placement(
            width: width,
            height: height,
          ),
          _ => entry,
        },
      ),
      PageElementGroup(:final id, :final name, :final placement) =>
        PageElement.group(
          id: id,
          name: name,
          placement: placement.copyWith(width: width, height: height),
        ),
      _ => this,
    };
  }

  PageElement updateCueTo(int startFrame, int endFrame) {
    return switch (this) {
      PageElementCue(:final cue) => PageElement.cue(
        cue: switch (cue) {
          Segment() => cue.copyWith(startFrame: startFrame, endFrame: endFrame),
          Keyframe() => cue.copyWith(frame: startFrame),
          _ => cue,
        },
      ),
      _ => this,
    };
  }

  PageElement updateFieldValue(String path, dynamic value) {
    return switch (this) {
      PageElementEntry(:final entry) => PageElement.entry(
        entry: switch (entry) {
          DefinitionPageEntry() => entry.copyWith.definition(
            data: entry.definition.data.copyWith(path, value),
          ),
          _ => entry,
        },
      ),
      PageElementCue(:final cue) => PageElement.cue(
        cue: switch (cue) {
          Segment() => cue.copyWith(data: cue.data.copyWith(path, value)),
          Keyframe() => cue.copyWith(data: cue.data.copyWith(path, value)),
          _ => cue,
        },
      ),
      _ => this,
    };
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
