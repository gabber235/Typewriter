import "package:flutter/material.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/input/input_renderer_scenarios.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";

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
Widget colorInputRendererUseCase(BuildContext context) =>
    rendererStory(context, inputRendererScenarios[7]);

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
