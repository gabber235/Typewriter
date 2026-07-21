import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/widgetbook_utils.dart";

@widgetbook.UseCase(name: "Default", type: TagGraph)
Widget tagGraphUseCase(BuildContext context) {
  final tagsState = context.knobs.displayState(
    label: "Tags State",
    initialOption: DisplayState.fewItems,
  );

  return FakeApp(
    overrides: [...tagsProviderOverrides(state: tagsState)],
    child: const TagGraph(),
  );
}

@widgetbook.UseCase(name: "Empty", type: TagGraph)
Widget tagGraphEmptyUseCase(BuildContext context) {
  return FakeApp(
    overrides: [...tagsProviderOverrides(state: DisplayState.noItems)],
    child: const TagGraph(),
  );
}

@widgetbook.UseCase(name: "Loading", type: TagGraph)
Widget tagGraphLoadingUseCase(BuildContext context) {
  return FakeApp(
    overrides: [...tagsProviderOverrides(state: DisplayState.loading)],
    child: const TagGraph(),
  );
}
