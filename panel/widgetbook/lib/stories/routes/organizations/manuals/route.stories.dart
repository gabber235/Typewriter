import "package:flutter/material.dart";
import "package:typewriter_panel/routes/organization/manuals/route.dart";
import "package:typewriter_panel/routes/organization/route.dart"
    show OrganizationScaffold;

import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

import "package:widgetbook_workspace/widgetbook_utils.dart";

@widgetbook.UseCase(name: "ManualsPage", type: ManualsPage)
Widget manualsPageUseCase(BuildContext context) {
  final displayState = context.knobs.displayState();

  return FakeApp(
    overrides: [
      ...manualModulesInfoProviderOverrides(),
      ...manualsProviderOverrides(state: displayState),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(
        state: DisplayState.manyItems,
      ),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: OrganizationScaffold(child: ManualsPage()),
  );
}
