import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _watchSubject = "cloud.to.user.user1.organization.org1.topology.watch";
const _listenSubject = "cloud.from.organization.org1.topology.watch";
const _configureSubject =
    "cloud.to.user.user1.organization.org1.topology.configure";
final _organizationId = recordId("organization:org1");

skir.ServiceHost _host({String id = "host1", int revision = 1}) =>
    skir.ServiceHost(
      hostId: recordId("service_host:$id"),
      serviceId: recordId("service:$id"),
      revision: revision,
      entrypoint: "PAPER",
      canHostRealm: true,
      supportedEngines: [skir.SupportedEngine(engineId: "paper")],
      topologyRevision: skir.ReconciledRevision(desired: 1, applied: 1),
      state: skir.HostRuntimeState.defaultInstance,
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
        _host(revision: 2),
      ),
    );
    expect(updated.hosts.first.revision, 2);
    expect(updated.hosts.map((host) => host.hostId.id), ["host1", "host2"]);

    final removed = await emit(
      skir.WatchOrganizationTopologyResponse.wrapResourceRemoved(
        _realm().realmId,
      ),
    );
    expect(removed.realmInstances, isEmpty);
  });

  test(
    "host configuration sends the generated transactional request",
    () async {
      final nats = FakeNatsClient();
      skir.ConfigureServiceHostRequest? decoded;
      nats.registerHandler(_configureSubject, (data) {
        decoded = skir.ConfigureServiceHostRequest.serializer.fromBytes(data);
        return skir.ConfigureServiceHostResponse.serializer.toBytes(
          skir.ConfigureServiceHostResponse.createSuccess(
            host: _host(revision: 2),
            realm: null,
            engine: null,
          ),
        );
      });
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => "user1"),
          organizationIdProvider.overrideWith((ref) => _organizationId),
          natsProvider.overrideWithValue(nats),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(nats.dispose);
      final execution = skir.HostExecutionConfiguration(
        realm: null,
        primaryEngine: null,
      );

      await container
          .read(organizationTopologyStreamProvider.notifier)
          .configureHost(
            host: TopologyHost.fromSkir(_host()),
            execution: execution,
          );

      expect(
        nats.requests
            .singleWhere((request) => request.subject == _configureSubject)
            .subject,
        _configureSubject,
      );
      expect(decoded!.hostId, _host().hostId);
      expect(decoded!.expectedRevision, 1);
      expect(decoded!.execution, execution);
    },
  );
}
