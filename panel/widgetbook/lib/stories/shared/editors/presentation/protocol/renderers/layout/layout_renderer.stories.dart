import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/layout/layout_renderer_scenarios.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";

const _path = "shared/editors/presentation/protocol/renderers/layout";

@widgetbook.UseCase(name: "Column", type: EditorProtocolRenderer, path: _path)
Widget columnRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[0]);

@widgetbook.UseCase(name: "Row", type: EditorProtocolRenderer, path: _path)
Widget rowRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[1]);

@widgetbook.UseCase(name: "Wrap", type: EditorProtocolRenderer, path: _path)
Widget wrapRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[2]);

@widgetbook.UseCase(name: "Stack", type: EditorProtocolRenderer, path: _path)
Widget stackRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[3]);

@widgetbook.UseCase(name: "Grid", type: EditorProtocolRenderer, path: _path)
Widget gridRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[4]);

@widgetbook.UseCase(name: "Card", type: EditorProtocolRenderer, path: _path)
Widget cardRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[5]);

@widgetbook.UseCase(name: "Section", type: EditorProtocolRenderer, path: _path)
Widget sectionRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[6]);

@widgetbook.UseCase(
  name: "Collapsible",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget collapsibleRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[7]);

@widgetbook.UseCase(name: "Tabs", type: EditorProtocolRenderer, path: _path)
Widget tabsRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[8]);

@widgetbook.UseCase(name: "Divider", type: EditorProtocolRenderer, path: _path)
Widget dividerRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[9]);

@widgetbook.UseCase(name: "Spacer", type: EditorProtocolRenderer, path: _path)
Widget spacerRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[10]);
