import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:hooks_riverpod/misc.dart" show Override;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

extension KnobsBuilderX on KnobsBuilder {
  EditorMode editorMode() {
    return object.dropdown(
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
    this.source,
    super.key,
  });

  final Widget child;
  final List<Override> overrides;
  final EditorSource Function(Ref ref)? source;
  @override
  Widget build(BuildContext context) {
    return FakeApp(
      overrides: overrides,
      child: Consumer(
        child: child,
        builder: (context, ref, child) {
          return EditorRoot(
            create: (ref) => EditorController(
              source: source?.call(ref) ?? SelectionEditorSource(ref),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Section(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
                ActionRow(),
              ],
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
    source: (_) => _StoryEditorSource((_) => const EditorValue.loading()),
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
    source: (_) => _StoryEditorSource((_) => const EditorValue.conflict()),
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
    source: (_) => _StoryEditorSource((_) => const EditorValue.none()),
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
    source: (_) =>
        _StoryEditorSource((path) => EditorValue.value(path.formatted)),
    child: FieldValueEditor(
      path: "hey",
      dataBlueprint: DataBlueprint.string(),
      editorMode: editorType,
      builder: (value) => Text(value.toString()),
    ),
  );
}

class _StoryEditorSource extends ChangeNotifier implements EditorSource {
  _StoryEditorSource(this.read);

  final EditorValue Function(String path) read;

  @override
  ObjectBlueprint? get blueprint => null;

  @override
  EditorValue value(String path) => read(path);

  @override
  void update(String path, dynamic value) {}
}
