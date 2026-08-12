import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

const _path = "[Shared]/Editors/Presentation protocol/Renderers/Data states";

final dataRendererVariantScenarios = [
  RendererStoryScenario(
    kind: RendererStoryKind.typedField,
    name: "Mismatched typed field",
    type: const StringType(),
    value: const StringValue("Not a boolean"),
    presentation: storyNode(
      "mismatchedTypedField",
      const PresentationElement.typedField(
        binding: rootBinding,
        expectedType: BooleanType(),
      ),
    ),
  ),
];

@widgetbook.UseCase(
  name: "Mismatched typed field",
  type: PresentationRendererStory,
  path: _path,
)
Widget mismatchedTypedFieldUseCase(BuildContext context) =>
    rendererStory(context, dataRendererVariantScenarios[0]);
