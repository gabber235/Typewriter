import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart" hide Title;
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "entries.freezed.dart";
part "entries.g.dart";
part "entry_selection.dart";

/// Loads one entry definition from the realm entry index and coordinates entry
/// edits with the page element owner.
///
/// The index is the current location authority. Mutations recheck that
/// location before submission, so a stale inspector cannot write to a page
/// after the entry has moved or the selected realm has changed.
@riverpod
class Entry extends _$Entry {
  @override
  Future<EntryDefinition?> build(String entryId) async {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null) throw ApiException.noOrganization();
    if (realmId == null) throw ApiException.badRequest("No realm selected");
    final index = ref.watch(realmEntryIndexProvider(organizationId, realmId));
    return switch (index) {
      AsyncData(:final value) => value[entryId]?.definition,
      AsyncError(:final error, :final stackTrace) => Error.throwWithStackTrace(
        error,
        stackTrace,
      ),
      AsyncLoading() => Completer<EntryDefinition?>().future,
    };
  }

  Future<void> updateFieldValue(DataPath path, DataValue value) async {
    state.ensureReady();

    final cached = _cachedEntry;
    if (cached == null) throw ApiException.notFound("Entry");
    await ref.withReadyPageElements(cached.pageId, (elements) {
      _requireCurrentEntry(cached.pageId);
      return elements.updateEntryFieldValue(entryId, path, value);
    });
    state = AsyncData(_cachedEntry?.definition);
  }

  Future<void> moveToPage(String pageId) async {
    state.ensureReady();
    final cached = _cachedEntry;
    if (cached == null) throw ApiException.notFound("Entry");
    if (cached.pageId == pageId) return;
    await ref.withReadyPageElements(cached.pageId, (elements) {
      _requireCurrentEntry(cached.pageId);
      return elements.moveEntriesToPage([entryId], pageId);
    });
  }

  CachedPageEntry? get _cachedEntry {
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (organizationId == null || realmId == null) return null;
    return ref
        .read(realmEntryIndexProvider(organizationId, realmId))
        .value?[entryId];
  }

  CachedPageEntry _requireCurrentEntry(String expectedPageId) {
    final current = _cachedEntry;
    if (current == null) throw ApiException.notFound("Entry");
    if (current.pageId != expectedPageId) {
      throw ApiException.conflict("The entry moved to another page");
    }
    return current;
  }
}

/// Read model consumed by page and graph views for local and related entries.
///
/// A definition owns editable data on the current page. A reference describes
/// a valid entry owned by another page and is not locally editable. A
/// nonexistent value represents a dangling cross page target. A missing
/// element definition preserves placement and links while making catalog loss
/// visible to the UI.
@Freezed(unionKey: "_kind")
abstract class PageEntry with _$PageEntry {
  const factory PageEntry.definition({required EntryDefinition definition}) =
      DefinitionPageEntry;

  @Assert("id != \"\"", "ID must not be empty.")
  @Assert("pageId != \"\"", "Page ID must not be empty.")
  const factory PageEntry.reference({
    required String id,
    required String name,
    required ElementDefinition elementDefinition,
    required String pageId,
    @Default([]) List<EntryMetadata> metadata,
  }) = ReferencePageEntry;

  @Assert("id != \"\"", "ID must not be empty.")
  const factory PageEntry.nonexistent({required String id}) =
      NonexistentPageEntry;

  @Assert("id != \"\"", "ID must not be empty.")
  const factory PageEntry.missingElementDefinition({
    required String id,
    required String name,
    required EntryPlacement placement,
    required List<ElementLink> inwardLinks,
    required List<ElementLink> outwardLinks,
    @Default([]) List<EntryMetadata> metadata,
  }) = MissingElementDefinitionPageEntry;
}

/// The editable local entry projection, including its typed data, placement,
/// catalog definition, and both link directions.
@freezed
abstract class EntryDefinition with _$EntryDefinition {
  @Assert("id != \"\"", "ID must not be empty.")
  const factory EntryDefinition({
    required String id,
    required ElementDefinition elementDefinition,
    required EntryPlacement placement,
    required RecordValue data,
    required List<ElementLink> inwardEdges,
    required List<ElementLink> outwardEdges,
    @Default([]) List<EntryMetadata> metadata,
  }) = _EntryDefinition;

  const EntryDefinition._();

  String get name => data.requiredStringField("name");
}

/// Position and size of an entry in its owning page projection.
///
/// Graph values use x and y coordinates with width and height. Timeline entry
/// values use x as the track index and retain a normalized one by one shape.
@freezed
abstract class EntryPlacement with _$EntryPlacement {
  @Assert("width >= 0", "Width must not be negative.")
  @Assert("height >= 0", "Height must not be negative.")
  const factory EntryPlacement({
    required int x,
    required int y,
    required int width,
    required int height,
    @Default(EntryPlacementKind.graph) EntryPlacementKind kind,
  }) = _EntryPlacement;

  factory EntryPlacement.fromJson(Map<String, dynamic> json) =>
      _$EntryPlacementFromJson(json);
}

/// The page surface whose placement rules apply to an entry.
enum EntryPlacementKind { graph, timelineEntry }

@Freezed(unionKey: "_kind")
abstract class EntryMetadata with _$EntryMetadata {
  @Assert("name != \"\"", "Name must not be empty.")
  const factory EntryMetadata.custom({
    required String name,
    required dynamic data,
  }) = CustomEntryMetadata;

  factory EntryMetadata.fromJson(Map<String, dynamic> json) =>
      _$EntryMetadataFromJson(json);
}

extension PageEntryExtension on PageEntry {
  String get id => switch (this) {
    DefinitionPageEntry(:final definition) => definition.id,
    ReferencePageEntry(:final id) => id,
    NonexistentPageEntry(:final id) => id,
    MissingElementDefinitionPageEntry(:final id) => id,
    _ => throw UnimplementedError(),
  };

  (List<ElementLink> inwardLinks, List<ElementLink> outwardLinks) get links =>
      switch (this) {
        MissingElementDefinitionPageEntry(
          inwardLinks: final inwardLinks,
          outwardLinks: final outwardLinks,
        ) =>
          (inwardLinks, outwardLinks),
        DefinitionPageEntry(definition: final definition) => (
          definition.inwardEdges,
          definition.outwardEdges,
        ),
        _ => (const <ElementLink>[], const <ElementLink>[]),
      };
}

/// Derives geometry used to position and compare entry placements.
extension EntryPlacementExtension on EntryPlacement {
  Offset get center {
    return Offset(x + width / 2, y + height / 2);
  }

  double distanceSquaredTo(EntryPlacement other) {
    return (center - other.center).distanceSquared;
  }
}
