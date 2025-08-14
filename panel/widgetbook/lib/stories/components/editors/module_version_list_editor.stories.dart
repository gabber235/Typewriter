import "package:flutter/material.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/module_version_editors.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/logic/modules.mock.dart";
import "package:widgetbook_workspace/stories/components/editors/editors.stories.dart";

@widgetbook.UseCase(name: "Default", type: ModuleVersionListEditor)
Widget moduleVersionListEditorUseCase(BuildContext context) {
  final versions = context.knobs.int.input(
    label: "Versions",
    initialValue: 10,
    description: "The number of versions generated",
  );
  final data =
      generateSequentialVersions(
        versions,
      ).map((version) => version.toJson()).toList();

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
