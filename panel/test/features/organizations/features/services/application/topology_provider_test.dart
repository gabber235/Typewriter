import "package:flutter_test/flutter_test.dart";
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
final _organizationId = skir.recordId("organization:org1");

skir.ServiceHost _host({
  String id = "host1",
  int revision = 1,
  skir.HostRuntimeState? state,
}) => skir.ServiceHost(
  hostId: skir.recordId("service_host:$id"),
  serviceId: skir.recordId("service:$id"),
  revision: revision,
  entrypoint: "PAPER",
  canHostRealm: true,
  supportedEngines: [skir.SupportedEngine(engineId: "paper")],
  topologyRevision: skir.ReconciledRevision(desired: 1, applied: 1),
  state: state ?? skir.HostRuntimeState.defaultInstance,
);

skir.RealmInstance _realm({skir.ChildRuntimeState? state}) =>
    skir.RealmInstance(
      realmId: skir.recordId("realm_instance:realm1"),
      ownerHost: skir.OwnerHost(id: _host().hostId, name: "host_1"),
      revision: 1,
      targetEngine: skir.EngineTarget(
        engineId: "paper",
        versionConstraint: "^1",
      ),
      state: state ?? skir.ChildRuntimeState.defaultInstance,
    );

skir.EngineInstance _engine() => skir.EngineInstance(
  engineId: skir.recordId("engine_instance:engine1"),
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

Future<skir.ConfigureServiceHostResponse> _configureHost(
  ProviderContainer container,
  TopologyHost host,
  skir.HostExecutionConfiguration execution,
) {
  final repository = container
      .read(resourceRepositoriesProvider)
      .services(_organizationId);
  return container
      .read(localWorkControllerProvider)
      .execute(repository.configure(host.hostId, host.revision, execution));
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
      skir.OrganizationTopologyChanged event,
    ) async {
      final previous = value;
      nats.emitMessageOnSubject(
        _listenSubject,
        skir.OrganizationTopologyChanged.serializer.toBytes(event),
      );
      await _waitFor(() => !identical(previous, value));
      return value.requireValue;
    }

    final listed = await emit(
      skir.OrganizationTopologyChanged.wrapReplace(
        skir.OrganizationTopologySnapshot(
          hosts: [
            _host(),
            _host(id: "host2"),
          ],
          realms: [_realm()],
          engines: [_engine()],
        ),
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
      skir.OrganizationTopologyChanged.wrapObservationsReported(
        skir.HostExecutionObservation(
          host: _host(
            revision: 2,
            state: skir.HostRuntimeState(
              status: skir.HostRuntimeStatus.active,
              message: null,
              updatedAt: DateTime.utc(2026),
            ),
          ),
          realm: null,
          engine: null,
        ),
      ),
    );
    expect(updated.hosts.first.revision, 1);
    expect(updated.hosts.map((host) => host.hostId.id), ["host1", "host2"]);

    final configured = await emit(
      skir.OrganizationTopologyChanged.createConfigurationChanged(
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
      skir.OrganizationTopologyChanged.wrapReplace(
        skir.OrganizationTopologySnapshot(
          hosts: [
            _host(revision: 3),
            _host(id: "host2"),
          ],
          realms: [],
          engines: [],
        ),
      ),
    );
    expect(removed.realmInstances, isEmpty);
  });

  test("delayed reconnect snapshot preserves accepted configuration with incoming membership", () async {
    final nats = FakeNatsClient()
      ..registerHandler(
        _watchSubject,
        (_) => skir.WatchOrganizationTopologyResponse.serializer.toBytes(
          skir.WatchOrganizationTopologyResponse.createList(
            hosts: [_host()],
            realms: [_realm()],
            engines: [_engine()],
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
    final subscription = container.listen(
      organizationTopologyStreamProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    OrganizationTopology? current() =>
        container.read(organizationTopologyStreamProvider).value;
    await _waitFor(() => current()?.hosts.length == 1);
    final reply = Completer<Uint8List>();
    nats
      ..registerHandler(_watchSubject, (_) => reply.future)
      ..setConnectionState(const NatsConnecting())
      ..setConnectionState(const NatsConnected());
    await _waitFor(() => nats.requests.length == 2);
    final baselineHost = _host(revision: 3);
    final configuredHost = skir.ServiceHost(
      hostId: baselineHost.hostId,
      serviceId: baselineHost.serviceId,
      revision: baselineHost.revision,
      canHostRealm: baselineHost.canHostRealm,
      supportedEngines: baselineHost.supportedEngines,
      entrypoint: "CONFIRMED",
      topologyRevision: skir.ReconciledRevision(desired: 3, applied: 2),
      state: skir.HostRuntimeState(
        status: skir.HostRuntimeStatus.reconciling,
        message: null,
        updatedAt: DateTime.utc(2026),
      ),
    );
    container
        .read(resourceRepositoriesProvider)
        .services(_organizationId)
        .acceptConfiguration(
          skir.HostConfigurationChange(
            host: configuredHost,
            realm: _realm(),
            engine: null,
            removedResources: [_engine().engineId],
          ),
        );
    await _waitFor(() => current()?.hosts.single.revision == 3);
    reply.complete(
      skir.WatchOrganizationTopologyResponse.serializer.toBytes(
        skir.WatchOrganizationTopologyResponse.createList(
          hosts: [_host()],
          realms: [],
          engines: [],
        ),
      ),
    );
    await _waitFor(() => current()?.realmInstances.isEmpty == true);
    expect(current()!.hosts.single.revision, 3);
    expect(current()!.hosts.single.entrypoint, "CONFIRMED");
    expect(
      current()!.hosts.single.topologyRevision,
      const TopologyRevision(desired: 3, applied: 2),
    );
    expect(
      current()!.hosts.single.state.status,
      TopologyHostStatus.reconciling,
    );
    expect(current()!.engineInstances, isEmpty);
    nats.emitMessageOnSubject(
      _listenSubject,
      skir.OrganizationTopologyChanged.serializer.toBytes(
        skir.OrganizationTopologyChanged.wrapObservationsReported(
          skir.HostExecutionObservation(
            host: _host(
              state: skir.HostRuntimeState(
                status: skir.HostRuntimeStatus.active,
                message: null,
                updatedAt: DateTime.utc(2027),
              ),
            ),
            realm: null,
            engine: null,
          ),
        ),
      ),
    );
    await _waitFor(
      () => current()?.hosts.single.state.status == TopologyHostStatus.active,
    );
    expect(current()!.hosts.single.revision, 3);
    expect(current()!.hosts.single.entrypoint, "CONFIRMED");
  });

  test("replacement keeps surviving child progress and forgets removed child history", () {
    final incoming = OrganizationTopology(
      hosts: [TopologyHost.fromSkir(_host())],
      realmInstances: [TopologyRealm.fromSkir(_realm())],
      engineInstances: [TopologyEngine.fromSkir(_engine())],
    );
    final latest = incoming.copyWith(
      realmInstances: [
        incoming.realmInstances.single.copyWith(
          revision: 4,
          targetEngine: const TopologyEngineTarget(
            engineId: "paper",
            versionConstraint: "^2",
          ),
          state: incoming.realmInstances.single.state.copyWith(
            status: TopologyRuntimeStatus.active,
            updatedAt: DateTime.utc(2027),
          ),
        ),
      ],
      engineInstances: [
        incoming.engineInstances.single.copyWith(
          revision: 5,
          target: const TopologyEngineTarget(
            engineId: "paper",
            versionConstraint: "^3",
          ),
          state: incoming.engineInstances.single.state.copyWith(
            status: TopologyRuntimeStatus.failed,
            updatedAt: DateTime.utc(2027),
          ),
        ),
      ],
    );
    final merged = incoming.reconcileSnapshot(latest);
    expect(merged.realmInstances, latest.realmInstances);
    expect(merged.engineInstances, latest.engineInstances);
    final removed = OrganizationTopology.empty.reconcileSnapshot(merged);
    expect(removed.realmInstances, isEmpty);
    expect(removed.engineInstances, isEmpty);
    expect(incoming.reconcileSnapshot(removed), incoming);
  });

  test(
    "manual refresh replaces the subscription and reloads the snapshot",
    () async {
      var status = skir.ChildRuntimeStatus.failed;
      final nats = FakeNatsClient()
        ..registerHandler(
          _watchSubject,
          (_) => skir.WatchOrganizationTopologyResponse.serializer.toBytes(
            skir.WatchOrganizationTopologyResponse.createList(
              hosts: [_host()],
              realms: [
                _realm(
                  state: skir.ChildRuntimeState(
                    status: status,
                    activeArtifactVersion: null,
                    message: null,
                    updatedAt: DateTime.utc(2026),
                  ),
                ),
              ],
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
      final values = <OrganizationTopology>[];
      final listener = container.listen(organizationTopologyStreamProvider, (
        _,
        next,
      ) {
        if (next case AsyncData(:final value)) values.add(value);
      }, fireImmediately: true);
      addTearDown(listener.close);
      await _waitFor(
        () =>
            values.lastOrNull?.realmInstances.single.state.status ==
            TopologyRuntimeStatus.failed,
      );

      status = skir.ChildRuntimeStatus.active;
      container
          .read(
            organizationTopologyControllerProvider(_organizationId).notifier,
          )
          .refresh();
      await _waitFor(
        () =>
            values.lastOrNull?.realmInstances.single.state.status ==
            TopologyRuntimeStatus.active,
      );

      expect(
        nats.requests.where((request) => request.subject == _watchSubject),
        hasLength(2),
      );
      expect(nats.subscriptionSubjects, [_listenSubject]);
    },
  );

  test("service recovery reloads the topology snapshot", () async {
    var connections = {_host().serviceId: false};
    final nats = FakeNatsClient()
      ..registerHandler(
        _watchSubject,
        (_) => skir.WatchOrganizationTopologyResponse.serializer.toBytes(
          skir.WatchOrganizationTopologyResponse.createList(
            hosts: [_host()],
            realms: [_realm()],
            engines: [],
          ),
        ),
      );
    final container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => "user1"),
        organizationIdProvider.overrideWith((ref) => _organizationId),
        natsProvider.overrideWithValue(nats),
        serviceConnectionsProvider.overrideWith((ref) => connections),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(nats.dispose);
    final topology = container.listen(
      organizationTopologyStreamProvider,
      (_, _) {},
    );
    final recovery = container.listen(realmTopologyRecoveryProvider, (_, _) {});
    addTearDown(topology.close);
    addTearDown(recovery.close);
    await _waitFor(
      () =>
          nats.requests
              .where((request) => request.subject == _watchSubject)
              .length ==
          1,
    );

    connections = {_host().serviceId: true};
    container.invalidate(serviceConnectionsProvider);
    await _waitFor(
      () =>
          nats.requests
              .where((request) => request.subject == _watchSubject)
              .length ==
          2,
    );

    expect(nats.subscriptionSubjects, [_listenSubject]);
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
