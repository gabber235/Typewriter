import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/editors.stories.dart";

@widgetbook.UseCase(name: "String", type: TypedEditor)
Widget stringEditorUseCase(BuildContext context) {
  return EditorStory(
    rootType: RecordType(
      fields: {"name": TypeField(name: "name", type: StringType())},
    ),
    initialValue: RecordValue({"name": const StringValue("Story name")}),
  );
}
