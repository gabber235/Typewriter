import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _watchSubject = "cloud.to.user.user1.organization.org1.topology.watch";
const _listenSubject = "cloud.from.organization.org1.topology";
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
      supportedEngines: [
        skir.SupportedEngine(engineId: "paper", supportedMajorVersions: [1]),
      ],
      topologyRevision: skir.ReconciledRevision(desired: 1, applied: 1),
      state: skir.HostRuntimeState.defaultInstance,
    );

skir.RealmInstance _realm() => skir.RealmInstance(
  realmId: recordId("realm_instance:realm1"),
  ownerHostId: _host().hostId,
  revision: 1,
  targetEngine: skir.EngineTarget(engineId: "paper", majorVersion: 1),
  manifestRevision: skir.ReconciledRevision(desired: 1, applied: 1),
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
    final nats = MockNatsClient();
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
          nats.publications.isNotEmpty &&
          nats.subscriptionSubjects.contains(_listenSubject),
    );

    expect(nats.publications.single.subject, _watchSubject);
    expect(
      skir.WatchOrganizationTopologyRequest.serializer.fromBytes(
        nats.publications.single.data,
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
        engines: [],
      ),
    );
    expect(listed.hosts, [_host(), _host(id: "host2")]);
    expect(listed.realmOwnedBy(_host().hostId), _realm());

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
      final nats = MockNatsClient();
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
        engine: null,
      );

      await container
          .read(organizationTopologyStreamProvider.notifier)
          .configureHost(host: _host(), execution: execution);

      expect(nats.requests.single.subject, _configureSubject);
      expect(decoded!.hostId, _host().hostId);
      expect(decoded!.expectedRevision, 1);
      expect(decoded!.execution, execution);
    },
  );
}
