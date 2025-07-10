import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/field_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/object_editor.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/components/selectable.stories.dart";

extension KnobsBuilderX on KnobsBuilder {
  EditorMode editorMode() {
    return list(
      label: "Editor Type",
      options: EditorMode.values,
      labelBuilder: (option) => option.name.formatted,
      initialOption: EditorMode.interactiveInspector,
    );
  }
}

class EditorStories extends StatelessWidget {
  const EditorStories({
    required this.child,
    this.overrides = const [],
    super.key,
  });

  final Widget child;
  final List<Override> overrides;
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: Consumer(
        builder: (context, ref, child) {
          ref.watch(selectedProvider);
          return Scaffold(
            body: Center(
              child: Section(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: this.child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EditorStory extends StatelessWidget {
  const EditorStory({required this.dataBlueprint, super.key});

  final ObjectBlueprint dataBlueprint;

  @override
  Widget build(BuildContext context) {
    final editorMode = context.knobs.editorMode();
    return EditorStories(
      overrides: [
        selectionProvider.overrideWithValue([
          TestSelectableIdentifier(id: "editor", dataBlueprint: dataBlueprint),
        ]),
      ],
      child: SingleChildScrollView(
        child: ObjectEditorWidget(
          path: "",
          objectBlueprint: dataBlueprint,
          editorMode: editorMode,
          defaultExpanded: true,
        ),
      ),
    );
  }
}

@widgetbook.UseCase(name: "Loading", type: FieldValueEditor)
Widget loadingEditorUseCase(BuildContext context) {
  final editorMode = context.knobs.editorMode();
  return EditorStories(
    overrides: [
      fieldValueProvider.overrideWith((_, _) => SelectedValue.loading()),
    ],
    child: FieldValueEditor(
      path: "",
      dataBlueprint: DataBlueprint.string(),
      editorMode: editorMode,
      builder: (value) => Text(value.toString()),
    ),
  );
}

@widgetbook.UseCase(name: "Conflict", type: FieldValueEditor)
Widget conflictValueEditorUseCase(BuildContext context) {
  final editorMode = context.knobs.editorMode();
  return EditorStories(
    overrides: [
      fieldValueProvider.overrideWith((_, path) => SelectedValue.conflict()),
    ],
    child: FieldValueEditor(
      path: "",
      dataBlueprint: DataBlueprint.string(),
      editorMode: editorMode,
      builder: (value) => Text(value.toString()),
    ),
  );
}

@widgetbook.UseCase(name: "None", type: FieldValueEditor)
Widget noneValueEditorUseCase(BuildContext context) {
  final editorType = context.knobs.editorMode();
  return EditorStories(
    overrides: [
      fieldValueProvider.overrideWith((_, path) => SelectedValue.none()),
    ],
    child: FieldValueEditor(
      path: "",
      dataBlueprint: DataBlueprint.string(),
      editorMode: editorType,
      builder: (value) => Text(value.toString()),
    ),
  );
}

@widgetbook.UseCase(name: "Value", type: FieldValueEditor)
Widget valueEditorUseCase(BuildContext context) {
  final editorType = context.knobs.editorMode();
  return EditorStories(
    overrides: [
      fieldValueProvider.overrideWith(
        (_, path) => SelectedValue.value(path.formatted),
      ),
    ],
    child: FieldValueEditor(
      path: "hey",
      dataBlueprint: DataBlueprint.string(),
      editorMode: editorType,
      builder: (value) => Text(value.toString()),
    ),
  );
}
