import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/typed_editor/typed_editor.stories.dart";

@widgetbook.UseCase(name: "Boolean", type: TypedEditor)
Widget booleanEditorUseCase(BuildContext context) {
  return EditorStory(
    rootType: RecordType(
      fields: {"enabled": TypeField(name: "enabled", type: BooleanType())},
    ),
    initialValue: RecordValue({"enabled": const BooleanValue(true)}),
  );
}
