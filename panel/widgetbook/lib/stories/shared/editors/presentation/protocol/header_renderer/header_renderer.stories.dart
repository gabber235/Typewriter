import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/header_renderer/action_scenarios.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/header_renderer/header_gallery.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/header_renderer/header_scenarios.dart";

const _path = "shared/editors/presentation/protocol/header_renderer";

@widgetbook.UseCase(
  name: "Generated composites",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget generatedCompositeHeadersUseCase(BuildContext context) =>
    _gallery(context, generatedCompositeScenario());

@widgetbook.UseCase(
  name: "List actions",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget listHeaderActionsUseCase(BuildContext context) =>
    _gallery(context, listActionsScenario());

@widgetbook.UseCase(
  name: "Map actions",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget mapHeaderActionsUseCase(BuildContext context) =>
    _gallery(context, mapActionsScenario());

@widgetbook.UseCase(
  name: "Merged binding",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget mergedBindingHeadersUseCase(BuildContext context) =>
    _gallery(context, mergedHeaderScenario());

@widgetbook.UseCase(
  name: "Action overflow",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget headerActionOverflowUseCase(BuildContext context) =>
    _gallery(context, actionOverflowScenario(), initialWidth: 380);

@widgetbook.UseCase(
  name: "Action states",
  type: EditorProtocolRenderer,
  path: _path,
)
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
