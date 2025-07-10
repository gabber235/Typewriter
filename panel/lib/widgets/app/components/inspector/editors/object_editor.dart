import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/field_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/header.dart";

class ObjectEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) => dataBlueprint is ObjectBlueprint;

  @override
  Widget build(String path, DataBlueprint dataBlueprint, EditorMode mode) =>
      ObjectEditorWidget(
        path: path,
        objectBlueprint: dataBlueprint as ObjectBlueprint,
        editorMode: mode,
      );

  @override
  (HeaderActions, Iterable<(String, HeaderContext, DataBlueprint)>)
      headerActions(
    Ref ref,
    String path,
    DataBlueprint dataBlueprint,
    HeaderContext context,
    EditorMode mode,
  ) {
    final objectBlueprint = dataBlueprint as ObjectBlueprint;
    final actions =
        super.headerActions(ref, path, dataBlueprint, context, mode);
    final childContext = context.copyWith(parentBlueprint: dataBlueprint);
    final children = objectBlueprint.fields.entries.map(
      (entry) => (path.join(entry.key), childContext, entry.value),
    );

    return (actions.$1, actions.$2.followedBy(children));
  }
}

class ObjectEditorWidget extends HookConsumerWidget {
  const ObjectEditorWidget({
    required this.path,
    required this.objectBlueprint,
    required this.editorMode,
    this.ignoreFields = const [],
    this.defaultExpanded = false,
    super.key,
  }) : super();
  final String path;
  final ObjectBlueprint objectBlueprint;
  final EditorMode editorMode;
  final List<String> ignoreFields;
  final bool defaultExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FieldHeader(
      path: path,
      canExpand: true,
      defaultExpanded: defaultExpanded,
      editorMode: editorMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          for (final fieldBlueprint in objectBlueprint.fields.entries)
            if (!ignoreFields.contains(fieldBlueprint.key)) ...[
              if (!fieldBlueprint.value.hasCustomLayout)
                FieldHeader(
                  path: path.join(fieldBlueprint.key),
                  editorMode: editorMode,
                  child: buildFieldEditor(fieldBlueprint),
                )
              else
                buildFieldEditor(fieldBlueprint),
            ],
        ],
      ),
    );
  }

  FieldEditor buildFieldEditor(MapEntry<String, DataBlueprint> field) {
    return FieldEditor(
      key: ValueKey(
        path.isNotEmpty ? path.join(field.key) : field.key,
      ),
      path: path.isNotEmpty ? path.join(field.key) : field.key,
      dataBlueprint: field.value,
      editorMode: editorMode,
    );
  }
}
