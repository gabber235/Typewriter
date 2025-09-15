import "package:flutter/material.dart";
import "package:typewriter_panel/routes/organization/modules/route.dart";
import "package:typewriter_panel/routes/organization/route.dart"
    show OrganizationScaffold;
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/widgetbook_utils.dart";

@widgetbook.UseCase(name: "ModulesPage", type: ModulesPage)
Widget modulesPageUseCase(BuildContext context) {
  final state = context.knobs.displayState();

  return FakeApp(
    overrides: [
      ...modulesProviderOverrides(state: state),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(
        state: DisplayState.manyItems,
      ),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: const OrganizationScaffold(child: ModulesPage()),
  );
}
