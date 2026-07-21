import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/widgetbook_utils.dart";

@widgetbook.UseCase(name: "JoinCodesPage", type: JoinCodesPage)
Widget useCase(BuildContext context) {
  final state = context.knobs.displayState(
    label: "Join Codes State",
    initialOption: DisplayState.fewItems,
  );
  return FakeApp(
    overrides: [
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(),
      ...organizationMembersProviderOverrides(),
      ...organizationJoinCodesProviderOverrides(state: state),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: OrganizationScaffold(child: JoinCodesPage()),
  );
}
