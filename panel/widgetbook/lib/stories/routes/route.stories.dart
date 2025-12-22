import "package:flutter/material.dart";
import "package:typewriter_panel/routes/route.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "IndexPage", type: IndexPage)
Widget indexPageWithOrgsUseCase(BuildContext context) {
  final orgsState = context.knobs.object.dropdown<DisplayState>(
    label: "Organizations State",
    options: DisplayState.values,
    initialOption: DisplayState.fewItems,
    labelBuilder: (state) => state.name,
  );
  final joinRequestsState = context.knobs.object.dropdown<DisplayState>(
    label: "Join Requests State",
    options: DisplayState.values,
    initialOption: DisplayState.noItems,
    labelBuilder: (state) => state.name,
  );

  return FakeApp(
    overrides: [
      ...organizationsProviderOverrides(state: orgsState),
      ...userJoinRequestsProviderOverrides(state: joinRequestsState),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: IndexPage(),
  );
}
