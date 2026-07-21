import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/editors.stories.dart";

@widgetbook.UseCase(name: "Default", type: NumberEditor)
Widget numberEditorUseCase(BuildContext context) {
  return EditorStory(
    dataBlueprint: ObjectBlueprint(
      fields: {
        "count": DataBlueprint.integer(),
        "level": DataBlueprint.integer(
          defaultValue: 1,
          modifiers: [const Modifier.min(1), const Modifier.max(100)],
        ),
        "price": DataBlueprint.decimal(
          modifiers: [
            const Modifier.negative(),
            const Modifier.min(-1000.0),
            const Modifier.max(1000.0),
          ],
        ),
      },
    ),
  );
}
