part of "topology_provider_test.dart";

void topologyLifecycleTests() {
  test("signed out topology is empty without a subscription", () async {
    final nats = FakeNatsClient();
    final container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => null),
        natsProvider.overrideWith(() => FakeNats(nats)),
      ],
    );
    addTearDown(nats.dispose);
    addTearDown(container.dispose);
    final provider = organizationTopologyControllerProvider(_organizationId);
    container.listen(provider, (_, _) {});

    expect(await container.read(provider.future), OrganizationTopology.empty);
    expect(nats.subscriptionSubjects, isEmpty);
    expect(nats.requests, isEmpty);
  });

  test("a reply from a disposed watch cannot modify its replacement", () async {
    final response = Completer<skir.ConfigureServiceHostResponse>();
    final nats = FakeNatsClient()
      ..registerHandler(
        _watchSubject,
        (_) => skir.WatchOrganizationTopologyResponse.serializer.toBytes(
          skir.WatchOrganizationTopologyResponse.createList(
            hosts: [_host()],
            realms: [],
            engines: [],
          ),
        ),
      )
      ..registerHandler(
        _configureSubject,
        (_) async => skir.ConfigureServiceHostResponse.serializer.toBytes(
          await response.future,
        ),
      );
    final container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => "user1"),
        natsProvider.overrideWith(() => FakeNats(nats)),
      ],
    );
    addTearDown(nats.dispose);
    addTearDown(container.dispose);
    final provider = organizationTopologyControllerProvider(_organizationId);

    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    final command = _configureHost(
      container,
      TopologyHost.fromSkir(_host()),
      skir.HostExecutionConfiguration(realm: null, primaryEngine: null),
    );
    await _waitFor(
      () =>
          nats.requests.any((request) => request.subject == _configureSubject),
    );
    container.invalidate(provider);
    await container.read(provider.future);

    expect(nats.subscriptionSubjects, [_listenSubject]);
    response.complete(
      skir.ConfigureServiceHostResponse.createSuccess(
        host: _host(revision: 2),
        realm: null,
        engine: null,
        removedResources: [],
      ),
    );
    final result = await command;
    await container.pump();
    expect(
      (result as skir.ConfigureServiceHostResponse_successWrapper)
          .value
          .host
          .revision,
      2,
    );
    expect(container.read(provider).requireValue.hosts.single.revision, 2);
  });
}
