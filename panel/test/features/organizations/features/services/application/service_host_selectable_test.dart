import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _updateSubject = "cloud.to.user.user1.organization.org1.services.update";
const _configureSubject =
    "cloud.to.user.user1.organization.org1.topology.configure";
final _organizationId = recordId("organization:org1");

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    "host document is composite and keeps observation fields read only",
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);
      final selectable = harness.selectable;
      final root = selectable.document.confirmedValue as RecordValue;

      expect(root.fields.keys, {"service", "host", "configuration"});
      final service = root.fields["service"]! as RecordValue;
      final lastSeen = service.fields["lastSeen"]! as PolymorphicValue;
      expect(lastSeen.concreteType.id, const TypeId.some());
      expect(
        (lastSeen.value as RecordValue).fields["value"],
        isA<TimestampValue>(),
      );
      final host = root.fields["host"]! as RecordValue;
      expect(host.fields["updatedAt"], isA<TimestampValue>());
      expect(selectable.document.revision, 2);
      expect(selectable.document.commitGroups.values, {
        "service",
        "configuration",
      });
      expect(
        selectable.validate(
          DataPath.root.field("host").field("entrypoint"),
          const StringValue("STANDALONE"),
        ),
        isA<InvalidEditorMutation>(),
      );
    },
  );

  test(
    "service group updates only the service and expands the result",
    () async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);
      skir.UpdateOrganizationServiceRequest? request;
      harness.respond(_updateSubject, (data) {
        request = skir.UpdateOrganizationServiceRequest.serializer.fromBytes(
          data,
        );
        return skir.UpdateOrganizationServiceResponse.serializer.toBytes(
          skir.UpdateOrganizationServiceResponse.wrapSuccess(
            harness.service.copyWith(revision: 2, name: "Renamed").toSkir(),
          ),
        );
      });
      final path = DataPath.root.field("service").field("name");
      final next = path
          .replace(
            harness.selectable.document.confirmedValue,
            const StringValue("Renamed"),
          )
          .valueOrNull!;

      final result = await harness.selectable.commit(
        EditorCommit(
          expectedRevision: 2,
          localRevision: 1,
          rootValue: next,
          changedPaths: {path},
          group: "service",
        ),
      );

      expect(request!.name, "Renamed");
      expect(harness.nats.requests.map((entry) => entry.subject), [
        _updateSubject,
      ]);
      expect(result, isA<MutationSuccess>());
      final value = (result as MutationSuccess).value as RecordValue;
      expect(value.fields.keys, {"service", "host", "configuration"});
      expect(result.revision, 3);
    },
  );

  test("configuration group configures only the host", () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    skir.ConfigureServiceHostRequest? request;
    harness.respond(_configureSubject, (data) {
      request = skir.ConfigureServiceHostRequest.serializer.fromBytes(data);
      return skir.ConfigureServiceHostResponse.serializer.toBytes(
        skir.ConfigureServiceHostResponse.createSuccess(
          host: _hostWithRevision(harness.host, 2),
          realm: harness.realm,
          engine: null,
        ),
      );
    });
    final path = DataPath.root.field("configuration").field("realmEnabled");
    final next = path
        .replace(
          harness.selectable.document.confirmedValue,
          const BooleanValue(true),
        )
        .valueOrNull!;

    final result = await harness.selectable.commit(
      EditorCommit(
        expectedRevision: 2,
        localRevision: 1,
        rootValue: next,
        changedPaths: {path},
        group: "configuration",
      ),
    );

    expect(request!.execution.realm, isNotNull);
    expect(harness.nats.requests.map((entry) => entry.subject), [
      _configureSubject,
    ]);
    expect(result, isA<MutationSuccess>());
    final value = (result as MutationSuccess).value as RecordValue;
    expect(value.fields.keys, {"service", "host", "configuration"});
    expect(result.revision, 3);
  });
}

class _Harness {
  _Harness._({
    required this.nats,
    required this.container,
    required this.service,
    required this.host,
    required this.realm,
    required this.selectable,
    required this.servicesSubscription,
    required this.topologySubscription,
  });

  static Future<_Harness> create() async {
    final nats = FakeNatsClient();
    final service = Service(
      serviceId: recordId("service:paper"),
      revision: 1,
      name: "Paper",
      role: HostServiceRole(version: "1.0.0"),
      createdAt: DateTime.utc(2026, 8, 21),
      state: ServiceState(
        status: ServiceStateStatus.online,
        lastSeen: DateTime.now(),
      ),
    );
    final host = skir.ServiceHost(
      hostId: recordId("service_host:paper"),
      serviceId: service.serviceId,
      revision: 1,
      entrypoint: "PAPER",
      canHostRealm: true,
      supportedEngines: [skir.SupportedEngine(engineId: "paper")],
      topologyRevision: skir.ReconciledRevision(desired: 1, applied: 1),
      state: skir.HostRuntimeState(
        status: skir.HostRuntimeStatus.active,
        message: null,
        updatedAt: DateTime.utc(2026, 8, 21),
      ),
    );
    final realm = skir.RealmInstance(
      realmId: recordId("realm_instance:paper"),
      ownerHost: skir.OwnerHost(id: host.hostId, name: service.name),
      revision: 1,
      targetEngine: skir.EngineTarget(
        engineId: "paper",
        versionConstraint: "^1",
      ),
      state: skir.ChildRuntimeState.defaultInstance,
    );
    final topology = OrganizationTopology(
      hosts: [TopologyHost.fromSkir(host)],
      realmInstances: [],
      engineInstances: [],
    );
    final container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => "user1"),
        organizationIdProvider.overrideWith((ref) => _organizationId),
        natsProvider.overrideWithValue(nats),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
        servicesProvider.overrideWith(() => _SeededServices([service])),
        organizationTopologyStreamProvider.overrideWith(
          () => _SeededTopology(topology),
        ),
      ],
    );
    final servicesSubscription = container.listen(
      servicesProvider,
      (previous, next) {},
    );
    final topologySubscription = container.listen(
      organizationTopologyStreamProvider,
      (previous, next) {},
    );
    await container.read(servicesProvider.future);
    await container.read(organizationTopologyStreamProvider.future);
    container
        .read(selectionProvider.notifier)
        .select(ServiceHostIdentifier(host.hostId));
    final selectable =
        container.read(selectedProvider).requireValue.single
            as InspectableSelectable;
    return _Harness._(
      nats: nats,
      container: container,
      service: service,
      host: host,
      realm: realm,
      selectable: selectable,
      servicesSubscription: servicesSubscription,
      topologySubscription: topologySubscription,
    );
  }

  final FakeNatsClient nats;
  final ProviderContainer container;
  final Service service;
  final skir.ServiceHost host;
  final skir.RealmInstance realm;
  final InspectableSelectable selectable;
  final ProviderSubscription<AsyncValue<List<Service>>> servicesSubscription;
  final ProviderSubscription<AsyncValue<OrganizationTopology>>
  topologySubscription;

  void respond(String subject, Uint8List Function(Uint8List) handler) {
    nats.registerHandler(subject, handler);
  }

  void dispose() {
    servicesSubscription.close();
    topologySubscription.close();
    container.dispose();
    nats.dispose();
  }
}

class _SeededServices extends Services {
  _SeededServices(this.services);

  final List<Service> services;

  @override
  Stream<List<Service>> build() => Stream.value(services);
}

class _SeededTopology extends OrganizationTopologyStream {
  _SeededTopology(this.topology);

  final OrganizationTopology topology;

  @override
  Stream<OrganizationTopology> build() => Stream.value(topology);
}

skir.ServiceHost _hostWithRevision(skir.ServiceHost host, int revision) =>
    skir.ServiceHost(
      hostId: host.hostId,
      serviceId: host.serviceId,
      revision: revision,
      entrypoint: host.entrypoint,
      canHostRealm: host.canHostRealm,
      supportedEngines: host.supportedEngines,
      topologyRevision: host.topologyRevision,
      state: host.state,
    );
