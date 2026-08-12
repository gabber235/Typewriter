import "package:flutter/material.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/header_renderer/action_scenarios.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/header_renderer/header_gallery.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/header_renderer/header_scenarios.dart";

@widgetbook.UseCase(name: "Generated composites", type: SemanticHeaderGallery)
Widget generatedCompositeHeadersUseCase(BuildContext context) =>
    _gallery(context, generatedCompositeScenario());

@widgetbook.UseCase(name: "List actions", type: SemanticHeaderGallery)
Widget listHeaderActionsUseCase(BuildContext context) =>
    _gallery(context, listActionsScenario());

@widgetbook.UseCase(name: "Map actions", type: SemanticHeaderGallery)
Widget mapHeaderActionsUseCase(BuildContext context) =>
    _gallery(context, mapActionsScenario());

@widgetbook.UseCase(name: "Merged binding", type: SemanticHeaderGallery)
Widget mergedBindingHeadersUseCase(BuildContext context) =>
    _gallery(context, mergedHeaderScenario());

@widgetbook.UseCase(name: "Action overflow", type: SemanticHeaderGallery)
Widget headerActionOverflowUseCase(BuildContext context) =>
    _gallery(context, actionOverflowScenario(), initialWidth: 380);

@widgetbook.UseCase(name: "Action states", type: SemanticHeaderGallery)
Widget headerActionStatesUseCase(BuildContext context) =>
    _gallery(context, actionStatesScenario(), initialWidth: 520);

Widget _gallery(
  BuildContext context,
  SemanticHeaderScenario scenario, {
  double initialWidth = 560,
}) => SemanticHeaderGallery(
  scenario: scenario,
  width: context.knobs.double.slider(
    label: "Editor width",
    initialValue: initialWidth,
    min: 280,
    max: 760,
  ),
  readOnly: context.knobs.boolean(label: "Read only"),
);
