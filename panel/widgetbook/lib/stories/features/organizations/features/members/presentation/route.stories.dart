import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/widgetbook_utils.dart";

@widgetbook.UseCase(name: "MemberListPage", type: MemberListPage)
Widget memberListPageUseCase(BuildContext context) {
  final membersState = context.knobs.displayState(
    label: "Members State",
    initialOption: DisplayState.fewItems,
  );
  final joinRequestsState = context.knobs.displayState(
    label: "Join Requests State",
    initialOption: DisplayState.fewItems,
  );

  return FakeApp(
    overrides: [
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.manyItems),
      ...organizationMembersProviderOverrides(state: membersState),
      ...organizationJoinRequestsProviderOverrides(state: joinRequestsState),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: OrganizationScaffold(child: MemberListPage()),
  );
}
