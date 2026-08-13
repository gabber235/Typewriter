import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/input/input_renderer_scenarios.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

const _path = "[Shared]/Editors/Presentation protocol/Renderers/Input";

@widgetbook.UseCase(name: "Text", type: PresentationRendererStory, path: _path)
Widget textInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[0]);

@widgetbook.UseCase(
  name: "Numeric",
  type: PresentationRendererStory,
  path: _path,
)
Widget numericInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[1]);

@widgetbook.UseCase(
  name: "Toggle",
  type: PresentationRendererStory,
  path: _path,
)
Widget toggleInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[2]);

@widgetbook.UseCase(
  name: "Select",
  type: PresentationRendererStory,
  path: _path,
)
Widget selectInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[3]);

@widgetbook.UseCase(
  name: "Slider",
  type: PresentationRendererStory,
  path: _path,
)
Widget sliderInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[4]);

@widgetbook.UseCase(
  name: "Date and time",
  type: PresentationRendererStory,
  path: _path,
)
Widget dateTimeInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[5]);

@widgetbook.UseCase(
  name: "Duration",
  type: PresentationRendererStory,
  path: _path,
)
Widget durationInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[6]);

@widgetbook.UseCase(name: "Color", type: PresentationRendererStory, path: _path)
Widget colorInputRendererUseCase(BuildContext context) {
  final includeAlpha = context.knobs.boolean(label: "Include alpha");
  final color = context.knobs.color(
    label: "Color",
    initialValue: const Color(0xCC7C4DFF),
  );
  final readOnly = context.knobs.boolean(label: "Read only");
  final enabled = context.knobs.boolean(label: "Enabled", initialValue: true);
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 520,
    min: 280,
    max: 760,
  );
  final sampleLibrary = context.knobs.boolean(label: "Sample library");
  final base = inputRendererScenarios[7];
  final scenario = RendererStoryScenario(
    kind: base.kind,
    name: base.name,
    type: base.type,
    value: color.integerValue,
    definitions: base.definitions,
    presentation: storyNode(
      "colorInput",
      PresentationElement.colorInput(
        control: storyControl("Accent color"),
        includeAlpha: includeAlpha,
      ),
      properties: PresentationProperties(enabledIf: enabled.asBooleanLiteral),
    ),
  );
  return PresentationRendererStory(
    scenario: scenario,
    width: width,
    readOnly: readOnly,
    colorLibraryStorage: sampleLibrary
        ? MemoryColorLibraryStorage(
            '{"recent":["FF7C4DFF","CC00A896","FFFFB000"],'
            '"favorites":["FF7C4DFF","FFEF476F","FF06D6A0",'
            '"FF118AB2","FF073B4C"],"format":"hex"}',
          )
        : null,
  );
}

@widgetbook.UseCase(name: "Icon", type: PresentationRendererStory, path: _path)
Widget iconInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[8]);

@widgetbook.UseCase(name: "Bytes", type: PresentationRendererStory, path: _path)
Widget bytesInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[9]);

@widgetbook.UseCase(name: "Enum", type: PresentationRendererStory, path: _path)
Widget enumInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[10]);

@widgetbook.UseCase(name: "Named", type: PresentationRendererStory, path: _path)
Widget namedInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[11]);

@widgetbook.UseCase(name: "List", type: PresentationRendererStory, path: _path)
Widget listInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[12]);

@widgetbook.UseCase(name: "Map", type: PresentationRendererStory, path: _path)
Widget mapInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[13]);

@widgetbook.UseCase(
  name: "Record",
  type: PresentationRendererStory,
  path: _path,
)
Widget recordInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[14]);

@widgetbook.UseCase(
  name: "Polymorphic",
  type: PresentationRendererStory,
  path: _path,
)
Widget polymorphicInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[15]);
