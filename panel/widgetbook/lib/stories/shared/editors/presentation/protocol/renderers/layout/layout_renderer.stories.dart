import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/layout/hierarchy_sequence_scenario.dart";
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

@widgetbook.UseCase(name: "Section", type: EditorProtocolRenderer, path: _path)
Widget sectionRendererUseCase(BuildContext context) {
  final scenario = layoutRendererScenarios[5];
  final useDefaultHeaderPadding = context.knobs.boolean(
    label: "Use default header padding",
    initialValue: true,
  );
  final headerHorizontal = context.knobs.double.slider(
    label: "Header horizontal padding",
    initialValue: 8,
    min: 0,
    max: 32,
  );
  final headerVertical = context.knobs.double.slider(
    label: "Header vertical padding",
    initialValue: 4,
    min: 0,
    max: 32,
  );
  final useDefaultContentPadding = context.knobs.boolean(
    label: "Use default content padding",
    initialValue: true,
  );
  final contentHorizontal = context.knobs.double.slider(
    label: "Content horizontal padding",
    initialValue: 8,
    min: 0,
    max: 32,
  );
  final contentVertical = context.knobs.double.slider(
    label: "Content vertical padding",
    initialValue: 4,
    min: 0,
    max: 32,
  );
  final header = scenario.presentation.header!;
  final presentation = scenario.presentation.copyWith(
    header: header.copyWith(
      headerPadding: useDefaultHeaderPadding
          ? null
          : PresentationInsets.symmetric(
              horizontal: headerHorizontal,
              vertical: headerVertical,
            ),
      contentPadding: useDefaultContentPadding
          ? null
          : PresentationInsets.symmetric(
              horizontal: contentHorizontal,
              vertical: contentVertical,
            ),
    ),
  );
  return rendererStory(
    context,
    RendererStoryScenario(
      kind: scenario.kind,
      name: scenario.name,
      type: scenario.type,
      value: scenario.value,
      presentation: presentation,
      definitions: scenario.definitions,
      diagnostics: scenario.diagnostics,
    ),
  );
}

@widgetbook.UseCase(name: "Tabs", type: EditorProtocolRenderer, path: _path)
Widget tabsRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[6]);

@widgetbook.UseCase(name: "Divider", type: EditorProtocolRenderer, path: _path)
Widget dividerRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[7]);

@widgetbook.UseCase(name: "Spacer", type: EditorProtocolRenderer, path: _path)
Widget spacerRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[8]);

@widgetbook.UseCase(
  name: "Container",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget containerRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[9]);

@widgetbook.UseCase(name: "Anchor", type: EditorProtocolRenderer, path: _path)
Widget anchorRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[10]);

@widgetbook.UseCase(
  name: "Connection layer",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget connectionLayerRendererUseCase(BuildContext context) =>
    rendererStory(context, layoutRendererScenarios[11]);

@widgetbook.UseCase(
  name: "Hierarchy sequence",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget hierarchySequenceRendererUseCase(BuildContext context) =>
    rendererStory(context, hierarchySequenceRendererScenario);
