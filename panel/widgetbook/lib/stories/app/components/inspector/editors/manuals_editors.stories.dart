import "package:flutter/material.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/manuals_editors.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/app/components/inspector/editors/editors.stories.dart";

@widgetbook.UseCase(
  name: "Platform Target (single)",
  type: ManualPlatformTargetEditor,
)
Widget manualPlatformTargetSingleUseCase(BuildContext context) {
  return EditorStory(
    dataBlueprint: ObjectBlueprint(
      fields: {
        "platform_target": DataBlueprint.manualPlatformTarget(
          defaultValue: generateRandomPlatformTarget().toJson(),
          modifiers: [Modifier.readOnly(recursive: true)],
        ),
      },
    ),
  );
}

@widgetbook.UseCase(
  name: "Platform Targets (list)",
  type: ManualPlatformTargetEditor,
)
Widget manualPlatformTargetListUseCase(BuildContext context) {
  return EditorStory(
    dataBlueprint: ObjectBlueprint(
      fields: {
        "platforms": DataBlueprint.list(
          type: DataBlueprint.manualPlatformTarget(),
          internalDefaultValue: List.generate(
            10,
            (_) => generateRandomPlatformTarget().toJson(),
          ),
          modifiers: [Modifier.readOnly(recursive: true), Modifier.expanded()],
        ),
      },
    ),
  );
}

@widgetbook.UseCase(
  name: "Module Reference (single)",
  type: ManualModuleReferenceEditor,
)
Widget manualModuleReferenceSingleUseCase(BuildContext context) {
  return EditorStory(
    dataBlueprint: ObjectBlueprint(
      fields: {
        "module": DataBlueprint.manualModuleReference(
          defaultValue: generateRandomManualModuleRefs().first.toJson(),
          modifiers: [Modifier.readOnly(recursive: true)],
        ),
      },
    ),
  );
}

@widgetbook.UseCase(
  name: "Modules (grouped list)",
  type: ManualModulesListEditor,
)
Widget manualModulesGroupedListUseCase(BuildContext context) {
  return EditorStory(
    dataBlueprint: ObjectBlueprint(
      fields: {
        "modules": DataBlueprint.list(
          type: DataBlueprint.manualModuleReference(),
          internalDefaultValue: generateRandomManualModuleRefs()
              .map((ref) => ref.toJson())
              .toList(),
          modifiers: [Modifier.readOnly(recursive: true), Modifier.expanded()],
        ),
      },
    ),
  );
}
