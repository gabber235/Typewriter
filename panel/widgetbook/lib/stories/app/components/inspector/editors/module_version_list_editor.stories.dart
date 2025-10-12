import "package:flutter/material.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/module_version_editors.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

import "package:widgetbook_workspace/stories/app/components/inspector/editors/editors.stories.dart";

@widgetbook.UseCase(name: "Default", type: ModuleVersionListEditor)
Widget moduleVersionListEditorUseCase(BuildContext context) {
  final versions = context.knobs.int.input(
    label: "Versions",
    initialValue: 10,
    description: "The number of versions generated",
  );
  final data = generateSequentialModuleVersions(versions);

  return EditorStory(
    dataBlueprint: ObjectBlueprint(
      fields: {
        "moduleVersions": DataBlueprint.list(
          type: DataBlueprint.moduleVersion(),
          internalDefaultValue: data,
          modifiers: [Modifier.readOnly(recursive: false), Modifier.expanded()],
        ),
      },
    ),
  );
}
