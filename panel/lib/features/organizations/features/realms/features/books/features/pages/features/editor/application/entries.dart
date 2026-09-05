import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart" hide Title;
import "package:flutter_hooks/flutter_hooks.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "entries.freezed.dart";
part "entries.g.dart";

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

/// Top-level union used by pages/graph/views to render entries.
/// - definition: an entry fully defined on the current page
/// - reference: a reference to an entry defined on a different page
/// - nonexistent: a dangling reference (entry no longer exists)
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

@freezed
abstract class EntryDefinition with _$EntryDefinition {
  @Assert("id != \"\"", "ID must not be empty.")
  const factory EntryDefinition({
    required String id,
    required String name,
    required ElementDefinition elementDefinition,
    required EntryPlacement placement,
    required RecordValue data,
    required List<ElementLink> inwardEdges,
    required List<ElementLink> outwardEdges,
    @Default(0) int authoringSequence,
    @Default([]) List<EntryMetadata> metadata,
  }) = _EntryDefinition;
}

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
    return asyncEntry.when(
      data: (value) {
        if (value == null) {
          throw SelectableNotFoundException(this);
        }
        final catalogState = ref.watch(
          realmEditorCatalogForTypeProvider(value.elementDefinition.rootType),
        );
        return catalogState.resolveElement(
          value.elementDefinition,
          (catalog, presentations) => EntrySelection(
            ref: ref,
            id: this,
            definition: value,
            typeCatalog: catalog,
            presentations: presentations,
          ),
        );
      },
      error: AsyncValue.error,
      loading: AsyncValue.loading,
    );
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

class EntrySelection extends InspectableSelectable<EntryIdentifier> {
  const EntrySelection({
    required this.ref,
    required this.id,
    required this.definition,
    required this.typeCatalog,
    required this.presentations,
  });

  @override
  final EntryIdentifier id;
  final Ref ref;
  final EntryDefinition definition;

  @override
  final TypeCatalog typeCatalog;
  final List<PresentationDefinition> presentations;

  @override
  String get name => definition.name;

  @override
  EditorDocument get document => EditorDocument(
    rootType: NamedType(definition.elementDefinition.rootType),
    typeCatalog: typeCatalog,
    presentations: presentations,
    confirmedValue: definition.data,
    revision: definition.authoringSequence,
  );

  @override
  List<SelectionCapability> get capabilities => [];

  @override
  Widget? buildInspectorHeader() {
    return EntryHeader(
      id: id.id,
      name: name,
      color: definition.elementDefinition.color,
    );
  }

  @override
  Future<TypedMutationResult> commit(EditorCommit commit) async {
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    final cached = organizationId == null || realmId == null
        ? null
        : ref
              .read(realmEntryIndexProvider(organizationId, realmId))
              .value?[id.id];
    if (cached == null) {
      return TypedMutationResult.unavailable([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "The entry is not in a loaded page document",
        ),
      ]);
    }
    return ref.withReadyPageElements(cached.pageId, (elements) {
      final activeOrganizationId = ref.read(organizationIdProvider);
      final activeRealmId = ref.read(realmIdProvider);
      final current = activeOrganizationId == null || activeRealmId == null
          ? null
          : ref
                .read(
                  realmEntryIndexProvider(activeOrganizationId, activeRealmId),
                )
                .value?[id.id];
      if (current == null) throw ApiException.notFound("Entry");
      if (current.pageId != cached.pageId) {
        throw ApiException.conflict("The entry moved to another page");
      }
      return elements.commitElementValue(id.id, commit);
    });
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
