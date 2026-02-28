import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart" hide Title;
import "package:flutter_hooks/flutter_hooks.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/graph/graph_identifier.dart";
import "package:typewriter_panel/logic/pages/page_type_extensions.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/color_converter.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_drag.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/generic/components/identifier.dart";
import "package:typewriter_panel/widgets/generic/components/title.dart";

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
    required EntryBlueprint blueprint,
    required String pageId,
    @Default([]) List<EntryMetadata> metadata,
  }) = ReferencePageEntry;

  const factory PageEntry.nonexistent({required String id}) =
      NonexistentPageEntry;

  const factory PageEntry.noBlueprint({
    required String id,
    required String name,
    required EntryPlacement placement,
    required List<EntryEdge> inwardEdges,
    required List<EntryEdge> outwardEdges,
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
    required EntryBlueprint blueprint,
    required EntryPlacement placement,
    required DynamicData data,
    required List<EntryEdge> inwardEdges,
    required List<EntryEdge> outwardEdges,
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

@freezed
abstract class EntryBlueprint with _$EntryBlueprint {
  const factory EntryBlueprint({
    required String id,
    required String name,
    required String description,
    required String extension,
    required ObjectBlueprint dataBlueprint,
    @ColorConverter() @Default(Colors.grey) Color color,
    @Default("fa-solid:question-circle") String icon,
    @Default(<String>[]) List<String> tags,
    @Default(null) List<DataBlueprint>? genericConstraints,
    @Default(null) DataBlueprint? variableDataBlueprint,
    @Default([]) List<ContextKey> contextKeys,
    @Default([]) List<EntryModifier> modifiers,
  }) = _EntryBlueprint;

  factory EntryBlueprint.fromJson(Map<String, dynamic> json) =>
      _$EntryBlueprintFromJson(json);
}

@freezed
abstract class ContextKey with _$ContextKey {
  const factory ContextKey({
    required String name,
    required String klassName,
    required DataBlueprint blueprint,
  }) = _ContextKey;

  factory ContextKey.fromJson(Map<String, dynamic> json) =>
      _$ContextKeyFromJson(json);
}

@Freezed(unionKey: "kind")
abstract class EntryModifier with _$EntryModifier {
  const factory EntryModifier() = _EmptyModifier;

  const factory EntryModifier.deprecated({@Default("") String reason}) =
      DeprecatedModifier;

  factory EntryModifier.fromJson(Map<String, dynamic> json) =>
      _$EntryModifierFromJson(json);
}

@freezed
abstract class EntryEdge with _$EntryEdge {
  const factory EntryEdge({
    required String id,
    required String otherId,
    required String path,
  }) = _EntryEdge;

  factory EntryEdge.fromJson(Map<String, dynamic> json) =>
      _$EntryEdgeFromJson(json);
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
}

extension EntryBlueprintExt on EntryBlueprint {
  bool get isGeneric => genericConstraints != null;

  bool allowsGeneric(DataBlueprint? genericBlueprint) {
    final blueprints = genericConstraints;
    if (blueprints == null) return true;
    if (genericBlueprint == null) return false;
    if (blueprints.isEmpty) return true;
    for (final blueprint in blueprints) {
      if (blueprint.matches(genericBlueprint)) return true;
    }
    return blueprints.any((e) => e.matches(genericBlueprint));
  }

  Map<String, List<M>> fieldsWithModifier<M extends Modifier>() =>
      _fieldsWithModifier<M>("", dataBlueprint);

  Map<String, List<M>> _fieldsWithModifier<M extends Modifier>(
    String path,
    DataBlueprint blueprint,
  ) {
    final fields = <String, List<M>>{
      if (blueprint.hasModifier<M>())
        path: blueprint.getModifiers<M>().toList(),
    };

    if (blueprint is ObjectBlueprint) {
      for (final field in blueprint.fields.entries) {
        fields.addAll(_fieldsWithModifier(path.join(field.key), field.value));
      }
    } else if (blueprint is ListBlueprint) {
      fields.addAll(_fieldsWithModifier(path.join("*"), blueprint.type));
    } else if (blueprint is MapBlueprint) {
      fields
        ..addAll(_fieldsWithModifier(path, blueprint.key))
        ..addAll(_fieldsWithModifier(path.join("*"), blueprint.value));
    }

    return fields;
  }

  DataBlueprint? getField(String path) {
    final parts = path.split(".");
    DataBlueprint? info = dataBlueprint;
    for (final part in parts) {
      if (info is ObjectBlueprint) {
        info = info.fields[part];
      } else if (info is ListBlueprint) {
        info = info.type;
      } else if (info is MapBlueprint) {
        info = info.value;
      }
    }
    return info;
  }

  PageType get pageType {
    final pageType = PageType.values.firstWhereOrNull(
      (type) => tags.contains(type.tag),
    );
    if (pageType == null) {
      // TODO: Properly show this toast to a user.
      throw Exception(
        "No page type found for blueprint $name, make sure it has one of the following tags: ${PageType.values.map((type) => type.tag).join(", ")}",
      );
    }
    return pageType;
  }
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
