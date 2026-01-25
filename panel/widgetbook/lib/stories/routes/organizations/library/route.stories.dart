import "package:flutter/material.dart";
import "package:typewriter_panel/routes/organization/library/route.dart";
import "package:typewriter_panel/routes/organization/route.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/widgetbook_utils.dart";

@widgetbook.UseCase(name: "LibraryPage", type: LibraryPage)
Widget libraryPageUseCase(BuildContext context) {
  final displayState = context.knobs.displayState();

  return FakeApp(
    overrides: [
      ...booksProviderOverrides(state: displayState),
      ...servicesProviderOverrides(state: DisplayState.manyItems),
      ...realmProviderOverrides(),
      ...organizationProviderOverrides(),
      ...organizationsProviderOverrides(state: DisplayState.manyItems),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: OrganizationScaffold(child: LibraryPage()),
  );
}
