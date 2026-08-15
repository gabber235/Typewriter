import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

const _path =
    "shared/editors/presentation/protocol/renderers/interaction_states";

final interactionRendererVariantScenarios = [
  RendererStoryScenario(
    kind: RendererStoryKind.button,
    name: "Disabled button",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "disabledButton",
      const PresentationElement.button(
        label: TypedExpression(
          resultType: StringType(),
          expression: LiteralExpression(StringValue("Unavailable action")),
        ),
        action: RealmEditorAction(ReloadRealmAction()),
      ),
      properties: PresentationProperties(
        enabledIf: literal(const BooleanType(), const BooleanValue(false)),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.button,
    name: "Unavailable realm action",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "unavailableRealmAction",
      PresentationElement.button(
        label: "Invoke unavailable action".asStringLiteral,
        action: const RealmEditorAction(ReloadRealmAction()),
      ),
    ),
  ),
];

@widgetbook.UseCase(
  name: "Disabled button",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget disabledButtonUseCase(BuildContext context) =>
    rendererStory(context, interactionRendererVariantScenarios[0]);

@widgetbook.UseCase(
  name: "Unavailable realm action",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget unavailableRealmActionUseCase(BuildContext context) =>
    rendererStory(context, interactionRendererVariantScenarios[1]);
