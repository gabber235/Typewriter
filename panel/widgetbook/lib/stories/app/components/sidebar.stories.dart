import "package:flutter/material.dart";
import "package:typewriter_panel/logic/organization.dart";
import "package:typewriter_panel/widgets/app/components/sidebar.dart";
import "package:typewriter_panel/widgets/app/components/panes.dart";
import "package:typewriter_panel/widgets/generic/components/section.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Default", type: Sidebar)
Widget sidebarUseCase(BuildContext context) {
  return FakeApp(
    overrides: [
      organizationIdProvider.overrideWithValue("1"),
      ...authProviderOverrides(),
      ...appearanceProviderOverrides(),
    ],
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
          child: Sidebar(),
        ),
        Expanded(
          child: Section(
            child: Pane(
              id: "sidebar-preview",
              child: Center(child: Text("Sidebar preview")),
            ),
          ),
        ),
      ],
    ),
  );
}
