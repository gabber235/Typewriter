import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/field_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/header.dart";

class BooleanEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint.matches(DataBlueprint.boolean());

  @override
  Widget build(String path, DataBlueprint dataBlueprint, EditorMode mode) {
    if (mode.hasHeaderActions) {
      return SizedBox();
    } else {
      return BooleanEditorWidget(
        path: path,
        primitiveBlueprint: dataBlueprint as PrimitiveBlueprint,
        editorMode: mode,
      );
    }
  }
}

class BooleanHeaderAction extends HeaderAction {
  @override
  bool shouldShow(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode editorMode,
  ) =>
      dataBlueprint.matches(DataBlueprint.boolean());
  @override
  HeaderActionLocation location(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode editorMode,
  ) =>
      HeaderActionLocation.trailing;
  @override
  Widget build(
    String path,
    HeaderContext context,
    DataBlueprint dataBlueprint,
    EditorMode editorMode,
  ) =>
      BooleanEditorWidget(
        path: path,
        primitiveBlueprint: dataBlueprint as PrimitiveBlueprint,
        editorMode: editorMode,
      );
}

class BooleanEditorWidget extends HookConsumerWidget {
  const BooleanEditorWidget({
    required this.path,
    required this.primitiveBlueprint,
    required this.editorMode,
    super.key,
  });

  final String path;
  final PrimitiveBlueprint primitiveBlueprint;
  final EditorMode editorMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FieldValueEditor(
      path: path,
      dataBlueprint: primitiveBlueprint,
      editorMode: editorMode,
      builder: (value) {
        return Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (value) {
                if (!editorMode.canEdit) return;
                ref
                    .read(selectedProvider.notifier)
                    .updateFieldValue(path, value ?? false);
              },
            ),
            if (value)
              const Text("True", style: TextStyle(color: Colors.greenAccent))
            else
              const Text("False", style: TextStyle(color: Colors.grey)),
          ],
        );
      },
    );
  }
}
