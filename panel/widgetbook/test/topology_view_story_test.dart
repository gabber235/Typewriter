import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/services/presentation/topology_scenarios.dart";

void main() {
  testWidgets("topology story selects a host and exposes its configuration", (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      FakeApp(
        overrides: [...appearanceProviderOverrides()],
        child: SizedBox(
          width: 1180,
          height: 720,
          child: TopologyView(topology: topologyScenario()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("Paper host"));
    await tester.pumpAndSettle();

    expect(find.text("Host execution"), findsOneWidget);
    expect(find.text("Run an execution engine"), findsOneWidget);
    expect(find.byTooltip("Zoom to fit"), findsOneWidget);
  });
}
