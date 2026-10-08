part of "service_host_selectable_test.dart";

class _Harness {
  _Harness._({
    required this.nats,
    required this.container,
    required this.service,
    required this.host,
    required this.secondHost,
    required this.realm,
    required this.selectable,
    required this.servicesSubscription,
    required this.topologySubscription,
  });

  static Future<_Harness> create({
    skir.RecordId Function()? organization,
    List<String> supportedEngineIds = const ["paper"],
    List<skir.RealmInstance> realms = const [],
    bool includeSecondHost = false,
  }) async {
    final nats = FakeNatsClient();
    final service = Service(
      serviceId: skir.recordId("service:paper"),
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
      hostId: skir.recordId("service_host:paper"),
      serviceId: service.serviceId,
      revision: 1,
      entrypoint: "PAPER",
      canHostRealm: true,
      supportedEngines: [
        for (final id in supportedEngineIds) skir.SupportedEngine(engineId: id),
      ],
      topologyRevision: skir.ReconciledRevision(desired: 1, applied: 1),
      state: skir.HostRuntimeState(
        status: skir.HostRuntimeStatus.active,
        message: null,
        updatedAt: DateTime.utc(2026, 8, 21),
      ),
    );
    final secondHost = includeSecondHost
        ? skir.ServiceHost(
            hostId: skir.recordId("service_host:paper_backup"),
            serviceId: service.serviceId,
            revision: 1,
            entrypoint: "PAPER_BACKUP",
            canHostRealm: true,
            supportedEngines: [
              for (final id in supportedEngineIds)
                skir.SupportedEngine(engineId: id),
            ],
            topologyRevision: skir.ReconciledRevision(desired: 1, applied: 1),
            state: skir.HostRuntimeState(
              status: skir.HostRuntimeStatus.active,
              message: null,
              updatedAt: DateTime.utc(2026, 8, 21),
            ),
          )
        : null;

    final realm = skir.RealmInstance(
      realmId: skir.recordId("realm_instance:paper"),
      ownerHost: skir.OwnerHost(id: host.hostId, name: service.name),
      revision: 1,
      targetEngine: skir.EngineTarget(
        engineId: "paper",
        versionConstraint: "^1",
      ),
      state: skir.ChildRuntimeState.defaultInstance,
    );

    final topology = OrganizationTopology(
      hosts: [
        TopologyHost.fromSkir(host),
        if (secondHost != null) TopologyHost.fromSkir(secondHost),
      ],
      realmInstances: realms.map(TopologyRealm.fromSkir).toList(),
      engineInstances: [],
    );

    nats
      ..registerHandler(
        "cloud.to.user.user1.organization.${_organizationId.id}.topology.watch",
        (_) => skir.WatchOrganizationTopologyResponse.serializer.toBytes(
          skir.WatchOrganizationTopologyResponse.createList(
            hosts: [host, ?secondHost],
            realms: realms,
            engines: [],
          ),
        ),
      )
      ..registerHandler(
        "cloud.to.user.user1.organization.${_organizationId.id}.services.watch",
        (_) => skir.WatchOrganizationServicesResponse.serializer.toBytes(
          skir.WatchOrganizationServicesResponse.wrapList([service.toSkir()]),
        ),
      );
    final container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => "user1"),
        organizationIdProvider.overrideWith(
          (ref) => organization?.call() ?? _organizationId,
        ),
        natsProvider.overrideWith(() => _ReplaceableNats(nats)),
        panelTelemetryProvider.overrideWithValue(
          const AsyncData(NoopPanelTelemetry()),
        ),
        canonicalOrganizationServicesProvider(_organizationId)
            .overrideWith(() => _SeededServices([service])),
        organizationTopologyControllerProvider(_organizationId)
            .overrideWith(() => _SeededTopology(topology)),
      ],
    );

    await container.read(userIdProvider.future);
    final servicesSubscription = container.listen(
      canonicalServicesProvider,
      (previous, next) {},
    );
    final topologySubscription = container.listen(
      organizationTopologyStreamProvider,
      (previous, next) {},
    );
    await container.read(canonicalServicesProvider.future);
    await container.read(organizationTopologyStreamProvider.future);
    container
        .read(selectionProvider.notifier)
        .select(ServiceHostIdentifier(host.hostId));
    final selected = await waitForProvider(
      container,
      selectedProvider,
      (value) => value.hasValue && value.requireValue.isNotEmpty,
      description: "service host selection",
    );
    final selectable = selected.requireValue.single as InspectableSelectable;

    return _Harness._(
      nats: nats,
      container: container,
      service: service,
      host: host,
      secondHost: secondHost,
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
  final skir.ServiceHost? secondHost;
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

InspectionContent _buildInspection(
  _Harness harness,
  EditorOwnerRegistry owners,
) {
  final content = harness.selectable.buildInspection(owners);
  addTearDown(() {
    content.host?.dispose();
    for (final host in content.additionalHosts) {
      host.dispose();
    }
  });
  return content;
}

EditorSource _identitySource(EditorOwnerRegistry owners) => owners
    .workspace
    .resources
    .values
    .singleWhere(
      (resource) =>
          resource.source.commitPolicy == EditorCommitPolicy.autosaveChanges,
    )
    .source;

EditorSource _configurationSource(EditorOwnerRegistry owners) => owners
    .workspace
    .resources
    .values
    .singleWhere(
      (resource) =>
          resource.source.commitPolicy == EditorCommitPolicy.applyResource,
    )
    .source;

class _ReplaceableNats extends Nats {
  _ReplaceableNats(this.client);
  final NatsClient client;

  @override
  NatsClient build() => client;
  NatsClient get connection => state;
  set connection(NatsClient next) => state = next;
}

class _SeededServices extends CanonicalOrganizationServices {
  _SeededServices(this.services);

  final List<Service> services;

  @override
  Stream<List<Service>> build(skir.RecordId organizationId) =>
      Stream.value(services);
}

class _SeededTopology extends OrganizationTopologyController {
  _SeededTopology(this.topology);

  final OrganizationTopology topology;

  void replace(OrganizationTopology value) => state = AsyncData(value);

  @override
  Stream<OrganizationTopology> build(skir.RecordId organizationId) =>
      Stream.value(topology);
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
