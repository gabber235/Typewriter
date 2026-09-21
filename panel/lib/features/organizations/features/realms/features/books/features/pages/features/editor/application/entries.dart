import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart" hide Title;
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart" show WidgetRef;
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
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
    required TypedPresentationSubject subject,
    required ElementDefinition elementDefinition,
    required String pageId,
    @Default([]) List<ElementLink> inwardLinks,
    @Default([]) List<ElementLink> outwardLinks,
    @Default([]) List<EntryMetadata> metadata,
  }) = ReferencePageEntry;

  @Assert("id != \"\"", "ID must not be empty.")
  const factory PageEntry.nonexistent({required String id}) =
      NonexistentPageEntry;

  /// A foreign graph resource whose identity exists but cannot be rendered.
  ///
  /// Remote ownership remains explicit so graph placement and occurrence
  /// edges behave exactly like a resolved reference while diagnostics stay
  /// visible.
  @Assert("id != \"\"", "ID must not be empty.")
  const factory PageEntry.unavailableReference({
    required String id,
    required String name,
    @Default([]) List<ElementLink> inwardLinks,
    @Default([]) List<ElementLink> outwardLinks,
    @Default([]) List<EntryMetadata> metadata,
  }) = UnavailableReferencePageEntry;

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

/// Derives field updates that make this entry reference a dropped resource.
///
/// This entry is the source and mutation owner. [target] is the resource it
/// will reference. An empty map means the resource cannot be dropped on this
/// entry's behalf.
extension EntryDefinitionReferenceDrop on EntryDefinition {
  Map<DataPath, DataValue> referenceDropValues(
    ReferenceResourceDragData target,
    TypeRegistry registry,
  ) {
    final resolved = registry
        .resolveExact(elementDefinition.rootType)
        .valueOrNull;
    if (resolved == null) return const {};

    final values = <DataPath, DataValue>{};
    for (final location in resolved.representation.queryReferences()) {
      if (!target.isAcceptedBy(location.target, registry)) continue;
      for (final path in data.expandTypeQueryPath(location.path)) {
        final current = path.read(data).valueOrNull;
        final selected = ReferenceValue(target.referenceId);
        final next = location.collection
            ? _toggleReference(current, selected)
            : location.optional
            ? _someReference(location.type, selected)
            : selected;
        final expected = resolved.representation
            .resolvePath(path, registry: registry)
            .valueOrNull;
        if (expected != null &&
            next.validateAgainst(expected, registry: registry).isEmpty) {
          values[path] = next;
        }
      }
    }
    return Map.unmodifiable(values);
  }
}

ListValue _toggleReference(DataValue? current, ReferenceValue selected) {
  final values = current is ListValue ? [...current.values] : <DataValue>[];
  final index = values.indexOf(selected);
  if (index < 0) {
    values.add(selected);
  } else {
    values.removeAt(index);
  }
  return ListValue(values);
}

PolymorphicValue _someReference(ReferenceType type, ReferenceValue selected) =>
    PolymorphicValue(
      concreteType: standardTypeRefs.someOf(type),
      value: RecordValue({"value": selected}),
    );

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
    UnavailableReferencePageEntry(:final id) => id,
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
        ReferencePageEntry(
          inwardLinks: final inwardLinks,
          outwardLinks: final outwardLinks,
        ) =>
          (inwardLinks, outwardLinks),
        UnavailableReferencePageEntry(
          inwardLinks: final inwardLinks,
          outwardLinks: final outwardLinks,
        ) =>
          (inwardLinks, outwardLinks),
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
