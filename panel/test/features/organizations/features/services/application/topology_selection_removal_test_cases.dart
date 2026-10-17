part of "service_host_selectable_test.dart";

void _testTopologySelectionRemoval() {
  for (final kind in ["host", "realm", "engine"]) {
    testWidgets("removed selected $kind recovers the inspector", (
      tester,
    ) async {
      late _Harness harness;
      await tester.runAsync(() async {
        harness = await _Harness.create();
        final container = harness.container;
        addTearDown(harness.dispose);
        final engineId = skir.recordId("engine_instance:paper");
        final topology =
            (container.read(
              organizationTopologyControllerProvider(_organizationId).notifier,
            ) as _SeededTopology)..replace(
              OrganizationTopology(
                hosts: [TopologyHost.fromSkir(harness.host)],
                realmInstances: [TopologyRealm.fromSkir(harness.realm)],
                engineInstances: [
                  TopologyEngine.fromSkir(
                    skir.EngineInstance(
                      engineId: engineId,
                      ownerHost: harness.realm.ownerHost,
                      realm: skir.RealmInfo(
                        realmId: harness.realm.realmId,
                        ownerHost: harness.realm.ownerHost,
                      ),
                      revision: 1,
                      target: harness.realm.targetEngine,
                      state: skir.ChildRuntimeState.defaultInstance,
                    ),
                  ),
                ],
              ),
            );
        await container.pump();

        await container.read(organizationTopologyProvider.future);
        final identifier = switch (kind) {
          "host" => ServiceHostIdentifier(harness.host.hostId),
          "realm" => RealmInstanceIdentifier(harness.realm.realmId),
          _ => EngineInstanceIdentifier(engineId),
        };
        container.read(selectionProvider.notifier).selectAll([identifier]);
        final session = container.listen(inspectionSessionProvider, (_, _) {});
        addTearDown(session.close);
        final inspected = await waitForProvider(
          container,
          inspectedSelectionProvider,
          (value) => value.hasValue && value.requireValue.length == 1,
          description: "inspected topology selection",
        );
        expect(inspected.requireValue, hasLength(1));

        final missing = Completer<AsyncValue<List<InspectableSelectable>>>();
        final errors = container.listen(inspectedSelectionProvider, (_, value) {
          if (value.hasError && !missing.isCompleted) missing.complete(value);
        });
        addTearDown(errors.close);
        topology.replace(OrganizationTopology.empty);
        final removed = await missing.future.timeout(
          const Duration(seconds: 2),
        );
        expect(
          removed.asError?.error,
          isA<SelectableNotFoundException>().having(
            (error) => error.id,
            "identifier",
            identifier,
          ),
        );

        expect(
          removed.asError?.stackTrace.toString(),
          contains("topology_selection.dart"),
        );
      });
      await tester.pump();
      expect(harness.container.read(selectionProvider), isEmpty);
      expect(
        harness.container.read(inspectedSelectionProvider).requireValue,
        isEmpty,
      );
      await tester.pump(Duration.zero);

      expect(tester.takeException(), isNull);
    });
  }
}
