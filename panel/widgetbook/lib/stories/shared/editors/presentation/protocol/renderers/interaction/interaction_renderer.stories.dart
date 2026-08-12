import "package:flutter/material.dart";
import "package:iconify_flutter_plus/icons/mdi.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

const _path = "[Shared]/Editors/Presentation protocol/Renderers/Interaction";

final interactionRendererScenarios = [
  RendererStoryScenario(
    kind: RendererStoryKind.button,
    name: "Button",
    type: const StringType(),
    value: const StringValue("Ready"),
    presentation: storyNode(
      "button",
      PresentationElement.button(
        label: "Mark complete".asStringLiteral,
        action: setRootValue(const StringType(), const StringValue("Complete")),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.iconButton,
    name: "Icon button",
    type: const StringType(),
    value: const StringValue("Visible"),
    presentation: storyNode(
      "iconButton",
      PresentationElement.iconButton(
        icon: svgIconLiteral(Mdi.eye_off_outline),
        semanticLabel: "Hide quest".asStringLiteral,
        action: setRootValue(const StringType(), const StringValue("Hidden")),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.menu,
    name: "Menu",
    type: const StringType(),
    value: const StringValue("Draft"),
    presentation: storyNode(
      "menu",
      PresentationElement.menu(
        label: "Change status".asStringLiteral,
        items: [
          PresentationMenuItem(
            id: "publish",
            label: "Publish".asStringLiteral,
            action: setRootValue(
              const StringType(),
              const StringValue("Published"),
            ),
          ),
          PresentationMenuItem(
            id: "archive",
            label: "Archive".asStringLiteral,
            action: setRootValue(
              const StringType(),
              const StringValue("Archived"),
            ),
          ),
        ],
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.tooltip,
    name: "Tooltip",
    type: const StringType(),
    value: const StringValue("Ready"),
    presentation: storyNode(
      "tooltip",
      PresentationElement.tooltip(
        message: "Reload the current presentation".asStringLiteral,
        child: storyNode(
          "tooltipButton",
          PresentationElement.iconButton(
            icon: svgIconLiteral(Mdi.reload),
            semanticLabel: "Reload".asStringLiteral,
            action: setRootValue(
              const StringType(),
              const StringValue("Reloaded"),
            ),
          ),
        ),
      ),
    ),
  ),
];

@widgetbook.UseCase(
  name: "Button",
  type: PresentationRendererStory,
  path: _path,
)
Widget buttonRendererUseCase(BuildContext context) =>
    rendererStory(context, interactionRendererScenarios[0]);

@widgetbook.UseCase(
  name: "Icon button",
  type: PresentationRendererStory,
  path: _path,
)
Widget iconButtonRendererUseCase(BuildContext context) =>
    rendererStory(context, interactionRendererScenarios[1]);

@widgetbook.UseCase(name: "Menu", type: PresentationRendererStory, path: _path)
Widget menuRendererUseCase(BuildContext context) =>
    rendererStory(context, interactionRendererScenarios[2]);

@widgetbook.UseCase(
  name: "Tooltip",
  type: PresentationRendererStory,
  path: _path,
)
Widget tooltipRendererUseCase(BuildContext context) =>
    rendererStory(context, interactionRendererScenarios[3]);
