import "package:flutter/material.dart";
import "package:iconify_flutter_plus/icons/mdi.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

const _path = "shared/editors/presentation/protocol/renderers/content";

final contentRendererScenarios = [
  RendererStoryScenario(
    kind: RendererStoryKind.text,
    name: "Text",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "text",
      PresentationElement.text(
        "A concise line of supporting copy.".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.markdown,
    name: "Markdown",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "markdown",
      PresentationElement.markdown(
        "## Quest notes\n\nUse **clear objectives** and concise instructions."
            .asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.icon,
    name: "Icon",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "icon",
      PresentationElement.icon(
        name: svgIconLiteral(Mdi.map_marker_path),
        semanticLabel: "Quest path".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.image,
    name: "Image",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "image",
      PresentationElement.image(
        source: "https://picsum.photos/640/240".asStringLiteral,
        semanticLabel: "Example quest artwork".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.badge,
    name: "Badge",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "badge",
      PresentationElement.badge(
        label: "Experimental".asStringLiteral,
        tone: "warning",
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.progress,
    name: "Progress",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "progress",
      PresentationElement.progress(
        value: floatLiteral(68),
        maximum: floatLiteral(100),
        label: "Quest completion".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.chip,
    name: "Chip",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "chip",
      PresentationElement.chip(
        label: "Adventure".asStringLiteral,
        color: TypedExpression(
          resultType: NamedType(standardTypeRefs.color),
          expression: LiteralExpression(IntegerValue(BigInt.from(0xFF967BFA))),
        ),
      ),
    ),
  ),
];

@widgetbook.UseCase(name: "Text", type: EditorProtocolRenderer, path: _path)
Widget textRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[0]);

@widgetbook.UseCase(name: "Markdown", type: EditorProtocolRenderer, path: _path)
Widget markdownRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[1]);

@widgetbook.UseCase(name: "Icon", type: EditorProtocolRenderer, path: _path)
Widget iconRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[2]);

@widgetbook.UseCase(name: "Image", type: EditorProtocolRenderer, path: _path)
Widget imageRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[3]);

@widgetbook.UseCase(name: "Badge", type: EditorProtocolRenderer, path: _path)
Widget badgeRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[4]);

@widgetbook.UseCase(name: "Progress", type: EditorProtocolRenderer, path: _path)
Widget progressRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[5]);

@widgetbook.UseCase(name: "Chip", type: EditorProtocolRenderer, path: _path)
Widget chipRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[6]);
