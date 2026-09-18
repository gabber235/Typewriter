import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

part "topology_state_test_cases.dart";
part "topology_lifecycle_test_cases.dart";

const _watchSubject = "cloud.to.user.user1.organization.org1.topology.watch";
const _listenSubject = "cloud.from.organization.org1.topology.watch";
const _configureSubject =
    "cloud.to.user.user1.organization.org1.topology.configure";
final _organizationId = recordId("organization:org1");

skir.ServiceHost _host({
  String id = "host1",
  int revision = 1,
  skir.HostRuntimeState? state,
}) => skir.ServiceHost(
  hostId: recordId("service_host:$id"),
  serviceId: recordId("service:$id"),
  revision: revision,
  entrypoint: "PAPER",
  canHostRealm: true,
  supportedEngines: [skir.SupportedEngine(engineId: "paper")],
  topologyRevision: skir.ReconciledRevision(desired: 1, applied: 1),
  state: state ?? skir.HostRuntimeState.defaultInstance,
);

skir.RealmInstance _realm() => skir.RealmInstance(
  realmId: recordId("realm_instance:realm1"),
  ownerHost: skir.OwnerHost(id: _host().hostId, name: "host_1"),
  revision: 1,
  targetEngine: skir.EngineTarget(engineId: "paper", versionConstraint: "^1"),
  state: skir.ChildRuntimeState.defaultInstance,
);

skir.EngineInstance _engine() => skir.EngineInstance(
  engineId: recordId("engine_instance:engine1"),
  ownerHost: skir.OwnerHost(
    id: _host(id: "host2").hostId,
    name: "paper_eu",
  ),
  realm: skir.RealmInfo(
    realmId: _realm().realmId,
    ownerHost: _realm().ownerHost,
  ),
  revision: 1,
  target: skir.EngineTarget(engineId: "paper", versionConstraint: "^1"),
  state: skir.ChildRuntimeState.defaultInstance,
);

Future<void> _waitFor(bool Function() condition) async {
  await Future.doWhile(() async {
    if (condition()) return false;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return true;
  }).timeout(const Duration(seconds: 2));
}

void main() {
  topologyStateTests();
  topologyLifecycleTests();
  test("runtime reports cannot publish configuration early or revive removed children", () {
    final initial = OrganizationTopology(
      hosts: [TopologyHost.fromSkir(_host())],
      realmInstances: [TopologyRealm.fromSkir(_realm())],
      engineInstances: [],
    );
    final early = initial.applyHostObservation(
      TopologyHost.fromSkir(
        _host(
          revision: 2,
          state: skir.HostRuntimeState(
            status: skir.HostRuntimeStatus.active,
            message: null,
            updatedAt: DateTime.utc(2026),
          ),
        ),
      ),
    );
    expect(early.hosts.single.revision, 1);
    expect(early.hosts.single.state.status, TopologyHostStatus.active);
    final removed = early.applyConfiguration(
      skir.HostConfigurationChange(
        host: _host(revision: 2),
        realm: null,
        engine: null,
        removedResources: [_realm().realmId],
      ),
    );
    expect(removed.hosts.single.revision, 2);

    expect(removed.hosts.single.state.status, TopologyHostStatus.active);
    expect(
      removed
          .applyRealmObservation(TopologyRealm.fromSkir(_realm()))
          .realmInstances,
      isEmpty,
    );
  });

  test("topology watch reduces lists, updates, and removals", () async {
    final nats = FakeNatsClient()
      ..registerHandler(
        _watchSubject,
        (_) => skir.WatchOrganizationTopologyResponse.serializer.toBytes(
          skir.WatchOrganizationTopologyResponse.createList(
            hosts: [],
            realms: [],
            engines: [],
          ),
        ),
      );
    final container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => "user1"),
        organizationIdProvider.overrideWith((ref) => _organizationId),
        natsProvider.overrideWithValue(nats),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(nats.dispose);
    AsyncValue<OrganizationTopology> value = const AsyncLoading();
    final subscription = container.listen(
      organizationTopologyStreamProvider,
      (previous, next) => value = next,
      fireImmediately: true,
    );

    addTearDown(subscription.close);
    await _waitFor(
      () =>
          nats.requests.isNotEmpty &&
          nats.subscriptionSubjects.contains(_listenSubject),
    );

    expect(nats.requests.single.subject, _watchSubject);
    expect(
      skir.WatchOrganizationTopologyRequest.serializer.fromBytes(
        nats.requests.single.payload,
      ),
      isA<skir.WatchOrganizationTopologyRequest>(),
    );

    Future<OrganizationTopology> emit(
      skir.WatchOrganizationTopologyResponse response,
    ) async {
      final previous = value;
      nats.emitMessageOnSubject(
        _listenSubject,
        skir.WatchOrganizationTopologyResponse.serializer.toBytes(response),
      );
      await _waitFor(() => !identical(previous, value));
      return value.requireValue;
    }

    final listed = await emit(
      skir.WatchOrganizationTopologyResponse.createList(
        hosts: [
          _host(),
          _host(id: "host2"),
        ],
        realms: [_realm()],
        engines: [_engine()],
      ),
    );
    expect(listed.hosts, [
      TopologyHost.fromSkir(_host()),
      TopologyHost.fromSkir(_host(id: "host2")),
    ]);
    expect(
      listed.realmOwnedBy(_host().hostId),
      TopologyRealm.fromSkir(_realm()),
    );
    expect(listed.realmInstances.single.ownerHost.name, "host_1");
    expect(listed.engineInstances.single.ownerHost.name, "paper_eu");
    expect(listed.engineInstances.single.realm.ownerHost.name, "host_1");

    final updated = await emit(
      skir.WatchOrganizationTopologyResponse.wrapHostUpdated(
        _host(
          revision: 2,
          state: skir.HostRuntimeState(
            status: skir.HostRuntimeStatus.active,
            message: null,
            updatedAt: DateTime.utc(2026),
          ),
        ),
      ),
    );
    expect(updated.hosts.first.revision, 1);
    expect(updated.hosts.map((host) => host.hostId.id), ["host1", "host2"]);

    final configured = await emit(
      skir.WatchOrganizationTopologyResponse.createConfigurationChanged(
        host: _host(revision: 3),
        realm: _realm(),
        engine: null,
        removedResources: [_engine().engineId],
      ),
    );
    expect(configured.hosts.first.revision, 3);
    expect(configured.realmInstances.single.realmId, _realm().realmId);
    expect(configured.engineInstances, isEmpty);

    final removed = await emit(
      skir.WatchOrganizationTopologyResponse.wrapResourceRemoved(
        _realm().realmId,
      ),
    );
    expect(removed.realmInstances, isEmpty);
  });

  test(
    "configuration repeats preserve newer runtime and reject older config",
    () {
      final change = skir.HostConfigurationChange(
        host: _host(revision: 3),
        realm: _realm(),
        engine: null,
        removedResources: [],
      );
      final configured = OrganizationTopology.empty.applyConfiguration(change);
      final newerState = configured.hosts.single.state.copyWith(
        status: TopologyHostStatus.failed,
        updatedAt: DateTime.utc(2026),
      );
      final observed = configured.copyWith(
        hosts: [configured.hosts.single.copyWith(state: newerState)],
      );
      expect(observed.applyConfiguration(change), observed);
      final old = skir.HostConfigurationChange(
        host: _host(revision: 2),
        realm: null,
        engine: null,
        removedResources: [_realm().realmId],
      );

      expect(observed.applyConfiguration(old), observed);
    },
  );
}
