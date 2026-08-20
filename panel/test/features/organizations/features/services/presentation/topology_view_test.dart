import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("graph host is keyboard selectable and opens its inspector", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpTestApp(
      child: SizedBox(
        width: 1200,
        height: 720,
        child: TopologyView(topology: _topology()),
      ),
    );
    expect(find.byTooltip("Zoom to fit"), findsOneWidget);

    for (var attempt = 0; attempt < 8; attempt++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      if (find.text("Host execution").evaluate().isNotEmpty) break;
    }

    expect(find.text("Host execution"), findsOneWidget);
    expect(find.text("Save configuration"), findsOneWidget);
  });

  testWidgets(
    "narrow topology uses its keyboard accessible list representation",
    (tester) async {
      tester.view.physicalSize = const Size(640, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpTestApp(child: TopologyView(topology: _topology()));

      expect(find.byType(ListTile), findsWidgets);
      expect(find.text("Graph"), findsNothing);
      await tester.tap(find.text("Paper host"));
      await tester.pumpAndSettle();
      expect(find.text("Host execution"), findsOneWidget);
    },
  );
}

OrganizationTopology _topology() {
  final host = skir.ServiceHost(
    hostId: recordId("service_host:paper1"),
    serviceId: recordId("service:paper1"),
    revision: 2,
    entrypoint: skir.HostEntrypoint.paper,
    canHostRealm: true,
    supportedEngines: [
      skir.SupportedEngine(engineId: "paper", supportedMajorVersions: [1]),
    ],
    desiredTopologyRevision: 2,
    appliedTopologyRevision: 2,
    state: skir.HostRuntimeState.defaultInstance,
  );
  final realm = skir.RealmInstance(
    realmId: recordId("realm_instance:realm1"),
    ownerHostId: host.hostId,
    revision: 1,
    targetEngine: skir.EngineTarget(engineId: "paper", majorVersion: 1),
    desiredManifestRevision: 1,
    appliedManifestRevision: 1,
    state: skir.ChildRuntimeState.defaultInstance,
  );
  final engine = skir.EngineInstance(
    engineId: recordId("engine_instance:paper1"),
    ownerHostId: host.hostId,
    realmId: realm.realmId,
    revision: 1,
    target: skir.EngineTarget(engineId: "paper", majorVersion: 1),
    desiredManifestRevision: 1,
    appliedManifestRevision: 1,
    state: skir.ChildRuntimeState.defaultInstance,
  );
  return OrganizationTopology(
    hosts: [host],
    realmInstances: [realm],
    engineInstances: [engine],
  );
}
