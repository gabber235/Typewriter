import "package:flutter/foundation.dart";
import "package:flutter/material.dart" hide Title;
import "package:flutter_hooks/flutter_hooks.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/element_blueprint.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/page_elements.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/selectable.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/data_blueprint.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/dynamic_data.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/selection.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_identifier.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/presentation/graph_drag.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/operations.dart";
import "package:typewriter_panel/shared/ui/components/identifier.dart";
import "package:typewriter_panel/shared/ui/components/title.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";

part "entries.freezed.dart";
part "entries.g.dart";

@riverpod
class Entry extends _$Entry {
  @override
  Future<EntryDefinition?> build(String entryId) async {
    // TODO: Fetch entry from the backend
    throw UnimplementedError();
  }

  Future<void> updateFieldValue(String path, dynamic value) async {
    state.ensureReady();

    // TODO: Implement optimistic updates

    // TODO: Make backend call to update field value for this entry
    throw UnimplementedError();
  }

  Future<void> moveToPage(String pageId) async {
    state.ensureReady();

    // TODO: Implement optimistic updates

    // TODO: Make backend call to move this entry to a different page
    throw UnimplementedError();
  }
}

/// Top-level union used by pages/graph/views to render entries.
/// - definition: an entry fully defined on the current page
/// - reference: a reference to an entry defined on a different page
/// - nonexistent: a dangling reference (entry no longer exists)
/// - noBlueprint: an entry without a blueprint (blueprint removed/missing)
@Freezed(unionKey: "_kind")
abstract class PageEntry with _$PageEntry {
  const factory PageEntry.definition({required EntryDefinition definition}) =
      DefinitionPageEntry;

  const factory PageEntry.reference({
    required String id,
    required String name,
    required ElementBlueprint blueprint,
    required String pageId,
    @Default([]) List<EntryMetadata> metadata,
  }) = ReferencePageEntry;

  const factory PageEntry.nonexistent({required String id}) =
      NonexistentPageEntry;

  const factory PageEntry.noBlueprint({
    required String id,
    required String name,
    required EntryPlacement placement,
    required List<ElementLink> inwardLinks,
    required List<ElementLink> outwardLinks,
    @Default([]) List<EntryMetadata> metadata,
  }) = NoBlueprintPageEntry;

  factory PageEntry.fromJson(Map<String, dynamic> json) =>
      _$PageEntryFromJson(json);
}

@freezed
abstract class EntryDefinition with _$EntryDefinition {
  const factory EntryDefinition({
    required String id,
    required String name,
    required ElementBlueprint blueprint,
    required EntryPlacement placement,
    required DynamicData data,
    required List<ElementLink> inwardEdges,
    required List<ElementLink> outwardEdges,
    @Default([]) List<EntryMetadata> metadata,
  }) = _EntryDefinition;

  factory EntryDefinition.fromJson(Map<String, dynamic> json) =>
      _$EntryDefinitionFromJson(json);
}

@freezed
abstract class EntryPlacement with _$EntryPlacement {
  const factory EntryPlacement({
    required int x,
    required int y,
    required int width,
    required int height,
  }) = _EntryPlacement;

  factory EntryPlacement.fromJson(Map<String, dynamic> json) =>
      _$EntryPlacementFromJson(json);
}

@Freezed(unionKey: "_kind")
abstract class EntryMetadata with _$EntryMetadata {
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
    NoBlueprintPageEntry(:final id) => id,
    _ => throw UnimplementedError(),
  };

  (List<ElementLink> inwardLinks, List<ElementLink> outwardLinks) get links =>
      switch (this) {
        NoBlueprintPageEntry(
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

extension EntryPlacementExtension on EntryPlacement {
  Offset get center {
    return Offset(x + width / 2, y + height / 2);
  }

  double distanceSquaredTo(EntryPlacement other) {
    return (center - other.center).distanceSquared;
  }
}

class EntryIdentifier extends SelectableIdentifier
    implements GraphDragData, GraphIdentifier {
  const EntryIdentifier(this.id);

  @override
  final String id;

  @override
  AsyncValue<Selectable<EntryIdentifier>> create(Ref ref) {
    final asyncEntry = ref.watch(entryProvider(id));
    return asyncEntry.whenData((value) {
      if (value == null) {
        throw SelectableNotFoundException(this);
      }
      return EntrySelection(ref: ref, id: this, definition: value);
    });
  }

  @override
  GraphIdentifier get graphId => this;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EntryIdentifier && other.id == id);

  @override
  String toString() => "EntryIdentifier($id)";
}

class EntrySelection extends Selectable<EntryIdentifier> {
  const EntrySelection({
    required this.ref,
    required this.id,
    required this.definition,
  });

  @override
  final EntryIdentifier id;
  final Ref ref;
  final EntryDefinition definition;

  @override
  String get name => definition.name;

  @override
  ObjectBlueprint get objectBlueprint => definition.blueprint.dataBlueprint;

  @override
  List<SelectableOperation> get operations => [];

  @override
  Widget? header() {
    return EntryHeader(
      id: id.id,
      name: name,
      color: definition.blueprint.color,
    );
  }

  @override
  dynamic fieldValue(String path) => definition.data.get(path);

  @override
  void setFieldValue(String path, dynamic value) {
    ref.read(entryProvider(id.id).notifier).updateFieldValue(path, value);
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EntrySelection && other.id == id);

  @override
  String toString() => "EntrySelection($id)";
}

/// Header for a entry displaying title and identifier.
class EntryHeader extends HookWidget {
  const EntryHeader({
    required this.id,
    required this.name,
    required this.color,
    super.key,
  });

  final String id;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Title(title: name, color: color),
        const SizedBox(height: 8),
        Identifier(id: id),
      ],
    );
  }
}
