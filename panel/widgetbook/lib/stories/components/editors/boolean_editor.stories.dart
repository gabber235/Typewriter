import "package:flutter/material.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/boolean_editor.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/components/editors/editors.stories.dart";

@widgetbook.UseCase(name: "Default", type: BooleanEditor)
Widget booleanEditorUseCase(BuildContext context) {
  return EditorStory(
    dataBlueprint: ObjectBlueprint(
      fields: {"enabled": DataBlueprint.boolean()},
    ),
  );
}
