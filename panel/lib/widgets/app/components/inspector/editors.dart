import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/boolean_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/list_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/number_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/object_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/string_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/header.dart";

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
    final actions = ref
        .watch(headerActionsProvider)
        .where((filter) {
          return filter.shouldShow(path, context, dataBlueprint, mode);
        })
        .groupListsBy(
          (filter) => filter.location(path, context, dataBlueprint, mode),
        )
        .map(
          (key, value) => MapEntry(
            key,
            value
                .map(
                  (filter) => filter.build(path, context, dataBlueprint, mode),
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
  tooltip(canEdit: false, hasHeaderActions: false),
  ;

  const EditorMode({this.canEdit = true, this.hasHeaderActions = true});
  final bool canEdit;
  final bool hasHeaderActions;
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
