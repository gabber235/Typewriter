import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/widgetbook_utils.dart";

@widgetbook.UseCase(name: "TagsPage", type: TagsPage)
Widget tagsPageUseCase(BuildContext context) {
  final tagsState = context.knobs.displayState(
    label: "Tags State",
    initialOption: DisplayState.fewItems,
  );

  return FakeApp(
    overrides: [
      ...tagsProviderOverrides(state: tagsState),
      ...servicesProviderOverrides(state: DisplayState.manyItems),
      ...realmProviderOverrides(),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.fewItems),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: OrganizationScaffold(child: TagsPage()),
  );
}
