import "package:flutter/material.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/list_editor.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/components/editors/editors.stories.dart";

@widgetbook.UseCase(name: "Default", type: ListEditor)
Widget listEditorUseCase(BuildContext context) {
  return EditorStory(
    dataBlueprint: ObjectBlueprint(
      fields: {
        "items": DataBlueprint.list(
          type: DataBlueprint.string(),
          internalDefaultValue: ["Hey there", "How is it going?"],
        ),
        "numbers": DataBlueprint.list(type: DataBlueprint.integer()),
        "nested": DataBlueprint.list(
          type: ObjectBlueprint(
            fields: {
              "name": DataBlueprint.string(),
              "value": DataBlueprint.integer(),
            },
          ),
          internalDefaultValue: [
            {"name": "Item 1", "value": 1},
            {"name": "Item 2", "value": 2},
          ],
        ),
      },
    ),
  );
}
