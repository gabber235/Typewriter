part of "topology_provider_test.dart";

void topologyStateTests() {
  for (final conflict in [false, true]) {
    for (final eventFirst in [false, true]) {
      test(
        "${conflict ? "conflict" : "success"} and watch converge with eventFirst=$eventFirst",
        () async {
          final response = Completer<skir.ConfigureServiceHostResponse>();
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
              organizationIdProvider.overrideWith((ref) => _organizationId),
              natsProvider.overrideWithValue(nats),
            ],
          );
          addTearDown(nats.dispose);
          addTearDown(container.dispose);

          final provider = organizationTopologyControllerProvider(
            _organizationId,
          );
          container.listen(provider, (_, _) {});
          await container.read(provider.future);

          final change = skir.HostConfigurationChange(
            host: _host(revision: 2),
            realm: null,
            engine: null,
            removedResources: [_realm().realmId],
          );
          void emit(skir.WatchOrganizationTopologyResponse event) {
            nats.emitMessageOnSubject(
              _listenSubject,
              skir.WatchOrganizationTopologyResponse.serializer.toBytes(event),
            );
          }

          final command = container
              .read(provider.notifier)
              .configureHost(
                host: TopologyHost.fromSkir(_host()),
                execution: skir.HostExecutionConfiguration(
                  realm: null,
                  primaryEngine: null,
                ),
              );
          final commandCompleted = conflict
              ? expectLater(command, throwsA(isA<Exception>()))
              : expectLater(
                  command,
                  completion(isA<TopologyConfigurationResult>()),
                );

          await _waitFor(
            () => nats.requests.any(
              (request) => request.subject == _configureSubject,
            ),
          );
          if (eventFirst) {
            emit(
              skir.WatchOrganizationTopologyResponse.wrapConfigurationChanged(
                change,
              ),
            );
            await _waitFor(
              () =>
                  container.read(provider).requireValue.hosts.first.revision ==
                  2,
            );
          }
          response.complete(
            conflict
                ? skir.ConfigureServiceHostResponse.createConflictError(
                    actual: change,
                  )
                : skir.ConfigureServiceHostResponse.wrapSuccess(change),
          );
          await commandCompleted;

          expect(
            container.read(provider).requireValue.hosts.single.revision,
            2,
          );
          expect(container.read(provider).requireValue.realmInstances, isEmpty);

          emit(
            skir.WatchOrganizationTopologyResponse.wrapHostUpdated(
              _host(
                state: skir.HostRuntimeState(
                  status: skir.HostRuntimeStatus.active,
                  message: "fresh",
                  updatedAt: DateTime.utc(2026),
                ),
              ),
            ),
          );
          emit(
            skir.WatchOrganizationTopologyResponse.wrapHostUpdated(
              _host(id: "host2"),
            ),
          );
          emit(
            skir.WatchOrganizationTopologyResponse.wrapHostUpdated(
              _host(id: "host3"),
            ),
          );
          await _waitFor(
            () => container.read(provider).requireValue.hosts.length == 3,
          );
          final observed = container.read(provider).requireValue;

          expect(observed.hosts.first.revision, 2);
          expect(observed.hosts.first.state.message, "fresh");
          expect(observed.realmInstances, isEmpty);
          emit(
            skir.WatchOrganizationTopologyResponse.wrapConfigurationChanged(
              change,
            ),
          );
          emit(
            skir.WatchOrganizationTopologyResponse.wrapResourceRemoved(
              _host(id: "host3").hostId,
            ),
          );
          await _waitFor(
            () => container.read(provider).requireValue.hosts.length == 2,
          );

          expect(
            container.read(provider).requireValue.hosts.first.state.message,
            "fresh",
          );
          expect(container.read(provider).requireValue.hosts.first.revision, 2);
        },
      );
    }
  }

  test(
    "organization owners isolate commands and dispose subscriptions",
    () async {
      final otherId = skir.recordId("organization:org2");
      final nats = FakeNatsClient();
      for (final id in [_organizationId, otherId]) {
        nats.registerHandler(
          "cloud.to.user.user1.organization.${id.id}.topology.watch",
          (_) => skir.WatchOrganizationTopologyResponse.serializer.toBytes(
            skir.WatchOrganizationTopologyResponse.createList(
              hosts: [_host()],
              realms: [],
              engines: [],
            ),
          ),
        );
      }
      nats.registerHandler(
        _configureSubject,
        (_) => skir.ConfigureServiceHostResponse.serializer.toBytes(
          skir.ConfigureServiceHostResponse.createSuccess(
            host: _host(revision: 2),
            realm: null,
            engine: null,
            removedResources: [],
          ),
        ),
      );
      final container = ProviderContainer.test(
        overrides: [
          userIdProvider.overrideWith((ref) async => "user1"),
          natsProvider.overrideWithValue(nats),
        ],
      );
      addTearDown(nats.dispose);

      addTearDown(container.dispose);
      final first = organizationTopologyControllerProvider(_organizationId);
      final second = organizationTopologyControllerProvider(otherId);
      final subscription = container.listen(first, (_, _) {});
      container.listen(second, (_, _) {});
      await Future.wait([
        container.read(first.future),
        container.read(second.future),
      ]);

      await container
          .read(first.notifier)
          .configureHost(
            host: TopologyHost.fromSkir(_host()),
            execution: skir.HostExecutionConfiguration(
              realm: null,
              primaryEngine: null,
            ),
          );
      expect(container.read(first).requireValue.hosts.single.revision, 2);
      expect(container.read(second).requireValue.hosts.single.revision, 1);
      subscription.close();
      container.invalidate(first);
      await container.pump();

      expect(nats.subscriptionSubjects, [
        "cloud.from.organization.org2.topology.watch",
      ]);
    },
  );
  test(
    "host configuration sends the generated transactional request",
    () async {
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
        );
      skir.ConfigureServiceHostRequest? decoded;
      nats.registerHandler(_configureSubject, (data) {
        decoded = skir.ConfigureServiceHostRequest.serializer.fromBytes(data);
        return skir.ConfigureServiceHostResponse.serializer.toBytes(
          skir.ConfigureServiceHostResponse.createSuccess(
            host: _host(revision: 2),
            realm: null,
            engine: null,
            removedResources: [],
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

      container.listen(organizationTopologyStreamProvider, (_, _) {});
      await container.read(organizationTopologyStreamProvider.future);
      final execution = skir.HostExecutionConfiguration(
        realm: null,
        primaryEngine: null,
      );

      await container
          .read(
            organizationTopologyControllerProvider(_organizationId).notifier,
          )
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
