import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/widgetbook_utils.dart";

@widgetbook.UseCase(name: "ServicesPage", type: ServicesPage)
Widget servicesPageUseCase(BuildContext context) {
  final servicesState = context.knobs.displayState(
    label: "Services State",
    initialOption: DisplayState.fewItems,
  );

  return FakeApp(
    overrides: [
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.fewItems),
      ...servicesProviderOverrides(state: servicesState),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: OrganizationScaffold(child: ServicesPage()),
  );
}
