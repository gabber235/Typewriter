import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/data_blueprint.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/boolean_editor.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/list_editor.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/number_editor.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/object_editor.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/string_editor.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/header.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

part "editors.g.dart";

@riverpod
List<Editor> editors(Ref ref) => [
  StringEditor(),
  NumberEditor(),
  BooleanEditor(),
  ListEditor(),
  ObjectEditor(),
];

abstract class Editor {
  bool canEdit(DataBlueprint dataBluepring);

  Widget build(String path, DataBlueprint dataBlueprint, EditorMode mode);

  (HeaderActions, Iterable<(String, HeaderContext, DataBlueprint)>)
  headerActions(
    Ref ref,
    String path,
    DataBlueprint dataBlueprint,
    HeaderContext context,
    EditorMode mode,
  ) {
    final resolvedMode = mode.resolve(dataBlueprint);
    final actions = ref
        .watch(headerActionsProvider)
        .where((filter) {
          return filter.shouldShow(path, context, dataBlueprint, resolvedMode);
        })
        .groupListsBy(
          (filter) =>
              filter.location(path, context, dataBlueprint, resolvedMode),
        )
        .map(
          (key, value) => MapEntry(
            key,
            value
                .map(
                  (filter) =>
                      filter.build(path, context, dataBlueprint, resolvedMode),
                )
                .toList(),
          ),
        );

    return (
      HeaderActions(
        leading: actions[HeaderActionLocation.leading] ?? [],
        trailing: actions[HeaderActionLocation.trailing] ?? [],
        actions: actions[HeaderActionLocation.actions] ?? [],
      ),
      [],
    );
  }
}

enum EditorMode {
  interactiveInspector(),
  readOnlyInspector(canEdit: false),
  tooltip(canEdit: false, hasHeaderActions: false);

  const EditorMode({this.canEdit = true, this.hasHeaderActions = true});
  final bool canEdit;
  final bool hasHeaderActions;

  EditorMode resolve(DataBlueprint dataBlueprint) {
    if (dataBlueprint.getModifiers<ReadOnlyModifier>().any(
      (m) => m.recursive,
    )) {
      return readOnlyInspector;
    }
    return this;
  }
}

@riverpod
String pathDisplayName(Ref ref, String path) {
  final parts = path.split(".");
  final name = parts.removeLast();

  if (name == "") return "";
  if (int.tryParse(name) != null) {
    final index = int.parse(name) + 1;
    final parent = parts.removeLast();
    if (parent == "") return "#$index";
    return "${parent.formatted} #$index";
  }

  return name.formatted;
}

extension EditorModeXDataBlueprint on (EditorMode, DataBlueprint) {
  bool get canEdit {
    if (!$1.canEdit) return false;
    if ($2.hasModifier<ReadOnlyModifier>()) return false;
    return true;
  }
}
