import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/widgetbook_utils.dart";

@widgetbook.UseCase(name: "RealmSelector", type: RealmSelector)
Widget realmSelectorUseCase(BuildContext context) {
  final displayState = context.knobs.displayState();
  return FakeApp(
    overrides: [
      ...servicesProviderOverrides(state: displayState),
      ...realmProviderOverrides(),
    ],
    child: Center(child: RealmSelector()),
  );
}
