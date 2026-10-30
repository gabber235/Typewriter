import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _watchSubject = "cloud.to.user.ada.organization.acme.topology.watch";
const _configureSubject =
    "cloud.to.user.ada.organization.acme.topology.configure";
const _listenSubject = "cloud.from.organization.acme.topology.watch";
final _organization = acme.organizationId;
final _topology = organizationTopologyControllerProvider(_organization);

final _appliedOnce = skir.ReconciledRevision(desired: 1, applied: 1);

final _host = paperHost(
  "host1",
  engines: ["paper"],
  reconciled: _appliedOnce,
  state: skir.HostRuntimeState.defaultInstance,
);

final _realm = realmInstance(
  "realm1",
  host: "host1",
  hostName: "host_1",
  version: "^1",
);

final _engine = engineInstance(
  "engine1",
  realm: _realm,
  host: "host2",
  hostName: "paper_eu",
);

void main() {
  group("topology reductions", () {
    test("runtime reports cannot publish configuration early or revive "
        "removed children", () {
      final initial = skir.OrganizationTopologySnapshot(
        hosts: [_host],
        realms: [_realm],
        engines: [],
      );
      final early = initial.applyHostObservation(
        paperHost(
          "host1",
          revision: 2,
          engines: ["paper"],
          reconciled: _appliedOnce,
          state: hostRuntimeState(),
        ),
      );
      expect(early.hosts.single.revision, 1);
      expect(early.hosts.single.state.status, skir.HostRuntimeStatus.active);

      final removed = early.applyConfiguration(
        skir.HostConfigurationChange(
          host: paperHost(
            "host1",
            revision: 2,
            engines: ["paper"],
            reconciled: _appliedOnce,
            state: skir.HostRuntimeState.defaultInstance,
          ),
          realm: null,
          engine: null,
          removedResources: [_realm.realmId],
        ),
      );
      expect(removed.hosts.single.revision, 2);
      expect(removed.hosts.single.state.status, skir.HostRuntimeStatus.active);
      expect(
        removed.applyRealmObservation(_realm.realmId, _realm.state).realms,
        isEmpty,
      );
    });

    test("a runtime observation updates host state without changing its "
        "configuration", () {
      final configured = skir.OrganizationTopologySnapshot(
        hosts: [
          paperHost(
            "host1",
            revision: 2,
            engines: ["paper"],
            reconciled: _appliedOnce,
            state: skir.HostRuntimeState.defaultInstance,
          ),
        ],
        realms: [],
        engines: [],
      );

      final observed =
          skir.OrganizationTopologyChanged.wrapObservationsReported(
            skir.HostExecutionObservation(
              host: paperHost(
                "host1",
                engines: ["paper"],
                reconciled: _appliedOnce,
                state: hostRuntimeState(message: "fresh"),
              ),
              realm: null,
              engine: null,
            ),
          ).applyTo(configured);

      expect(observed.hosts.single.revision, 2);
      expect(observed.hosts.single.state.message, "fresh");
    });

    test("an advertised host joins the topology", () {
      final advertised =
          skir.OrganizationTopologyChanged.wrapHostAdvertised(
            paperHost(
              "host2",
              engines: ["paper"],
              reconciled: _appliedOnce,
              state: skir.HostRuntimeState.defaultInstance,
            ),
          ).applyTo(
            skir.OrganizationTopologySnapshot(
              hosts: [_host],
              realms: [],
              engines: [],
            ),
          );

      expect(advertised.hosts.map((host) => host.hostId.id), [
        "host1",
        "host2",
      ]);
    });

    test("a replacement keeps the newer configuration and observation of a "
        "surviving host and drops absent hosts", () {
      final current = skir.OrganizationTopologySnapshot(
        hosts: [
          paperHost(
            "host1",
            revision: 2,
            engines: ["paper"],
            reconciled: _appliedOnce,
            state: hostRuntimeState(message: "fresh"),
          ),
          paperHost(
            "host3",
            engines: ["paper"],
            reconciled: _appliedOnce,
            state: skir.HostRuntimeState.defaultInstance,
          ),
        ],
        realms: [],
        engines: [],
      );

      final replaced = skir.OrganizationTopologyChanged.wrapReplace(
        skir.OrganizationTopologySnapshot(
          hosts: [
            _host,
            paperHost(
              "host2",
              engines: ["paper"],
              reconciled: _appliedOnce,
              state: skir.HostRuntimeState.defaultInstance,
            ),
          ],
          realms: [],
          engines: [],
        ),
      ).applyTo(current);

      expect(replaced.hosts.map((host) => host.hostId.id), ["host1", "host2"]);
      expect(replaced.hosts.first.revision, 2);
      expect(replaced.hosts.first.state.message, "fresh");
    });

    test("replacement keeps surviving child progress and forgets removed "
        "child history", () {
      final incoming = skir.OrganizationTopologySnapshot(
        hosts: [_host],
        realms: [_realm],
        engines: [_engine],
      );
      final latest =
          (incoming.toMutable()
                ..realms = [
                  (incoming.realms.single.toMutable()
                        ..revision = 4
                        ..targetEngine = skir.EngineTarget(
                          engineId: "paper",
                          versionConstraint: "^2",
                        )
                        ..state =
                            (incoming.realms.single.state.toMutable()
                                  ..status = skir.ChildRuntimeStatus.active
                                  ..updatedAt = DateTime.utc(2027))
                                .toFrozen())
                      .toFrozen(),
                ]
                ..engines = [
                  (incoming.engines.single.toMutable()
                        ..revision = 5
                        ..target = skir.EngineTarget(
                          engineId: "paper",
                          versionConstraint: "^3",
                        )
                        ..state =
                            (incoming.engines.single.state.toMutable()
                                  ..status = skir.ChildRuntimeStatus.failed
                                  ..updatedAt = DateTime.utc(2027))
                                .toFrozen())
                      .toFrozen(),
                ])
              .toFrozen();

      final merged = incoming.reconcileSnapshot(latest);
      expect(merged.realms, latest.realms);
      expect(merged.engines, latest.engines);
      final removed = skir.OrganizationTopologySnapshot.defaultInstance
          .reconcileSnapshot(merged);
      expect(removed.realms, isEmpty);
      expect(removed.engines, isEmpty);
      expect(incoming.reconcileSnapshot(removed), incoming);
    });

    test("configuration repeats preserve newer runtime and reject older "
        "config", () {
      final change = skir.HostConfigurationChange(
        host: paperHost(
          "host1",
          revision: 3,
          engines: ["paper"],
          reconciled: _appliedOnce,
          state: skir.HostRuntimeState.defaultInstance,
        ),
        realm: _realm,
        engine: null,
        removedResources: [],
      );
      final configured = skir.OrganizationTopologySnapshot.defaultInstance
          .applyConfiguration(change);
      final observed =
          (configured.toMutable()
                ..hosts = [
                  (configured.hosts.single.toMutable()
                        ..state =
                            (configured.hosts.single.state.toMutable()
                                  ..status = skir.HostRuntimeStatus.failed
                                  ..updatedAt = DateTime.utc(2026))
                                .toFrozen())
                      .toFrozen(),
                ])
              .toFrozen();
      expect(observed.applyConfiguration(change), observed);

      final older = skir.HostConfigurationChange(
        host: paperHost(
          "host1",
          revision: 2,
          engines: ["paper"],
          reconciled: _appliedOnce,
          state: skir.HostRuntimeState.defaultInstance,
        ),
        realm: null,
        engine: null,
        removedResources: [_realm.realmId],
      );
      expect(observed.applyConfiguration(older), observed);
    });
  });

  group("topology watch", () {
    test(
      "signed out, the topology is empty and nothing is requested",
      () async {
        final world = testWorld([
          servicesBackend(
            topology: skir.OrganizationTopologySnapshot(
              hosts: [_host],
              realms: [],
              engines: [],
            ),
          ),
        ]);
        world.container.listen(_topology, (_, _) {});

        expect(
          await world.container.read(_topology.future),
          skir.OrganizationTopologySnapshot.defaultInstance,
        );
        expect(world.nats.connected, isFalse);
      },
    );

    test("watch events list, update and remove topology resources", () async {
      final world = testWorld([
        signedIn(ada, organization: acme),
        servicesBackend(
          topology: skir.OrganizationTopologySnapshot(
            hosts: [],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      await world.initialized();
      world.container.listen(_topology, (_, _) {});
      await world.container.read(_topology.future);

      Future<skir.OrganizationTopologySnapshot> announce(
        skir.OrganizationTopologyChanged change,
        bool Function(skir.OrganizationTopologySnapshot) reached,
      ) async {
        world.nats.announceTopology(_organization, change);
        return (await world.container.eventually(
          _topology,
          (value) => value.hasValue && reached(value.requireValue),
          description: "the announced topology",
        )).requireValue;
      }

      final listed = await announce(
        skir.OrganizationTopologyChanged.wrapReplace(
          skir.OrganizationTopologySnapshot(
            hosts: [
              _host,
              paperHost(
                "host2",
                engines: ["paper"],
                reconciled: _appliedOnce,
                state: skir.HostRuntimeState.defaultInstance,
              ),
            ],
            realms: [_realm],
            engines: [_engine],
          ),
        ),
        (topology) => topology.hosts.length == 2,
      );
      expect(listed.realmOwnedBy(_host.hostId), _realm);
      expect(listed.engines.single.ownerHost.name, "paper_eu");
      expect(listed.engines.single.realm.ownerHost.name, "host_1");

      final observed = await announce(
        skir.OrganizationTopologyChanged.wrapObservationsReported(
          skir.HostExecutionObservation(
            host: paperHost(
              "host1",
              revision: 2,
              engines: ["paper"],
              reconciled: _appliedOnce,
              state: hostRuntimeState(),
            ),
            realm: null,
            engine: null,
          ),
        ),
        (topology) =>
            topology.hosts.first.state.status == skir.HostRuntimeStatus.active,
      );
      expect(observed.hosts.first.revision, 1);
      expect(observed.hosts.map((host) => host.hostId.id), ["host1", "host2"]);

      final configured = await announce(
        skir.OrganizationTopologyChanged.createConfigurationChanged(
          host: paperHost(
            "host1",
            revision: 3,
            engines: ["paper"],
            reconciled: _appliedOnce,
            state: skir.HostRuntimeState.defaultInstance,
          ),
          realm: _realm,
          engine: null,
          removedResources: [_engine.engineId],
        ),
        (topology) => topology.hosts.first.revision == 3,
      );
      expect(configured.realms.single.realmId, _realm.realmId);
      expect(configured.engines, isEmpty);

      final removed = await announce(
        skir.OrganizationTopologyChanged.wrapReplace(
          skir.OrganizationTopologySnapshot(
            hosts: [
              paperHost(
                "host1",
                revision: 3,
                engines: ["paper"],
                reconciled: _appliedOnce,
                state: skir.HostRuntimeState.defaultInstance,
              ),
              paperHost(
                "host2",
                engines: ["paper"],
                reconciled: _appliedOnce,
                state: skir.HostRuntimeState.defaultInstance,
              ),
            ],
            realms: [],
            engines: [],
          ),
        ),
        (topology) => topology.realms.isEmpty,
      );
      expect(removed.hosts.first.revision, 3);
    });

    test("an unknown watch event fails the projection with an unknown "
        "response error", () async {
      final world = testWorld([
        signedIn(ada, organization: acme),
        servicesBackend(
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      await world.initialized();
      world.container.listen(_topology, (_, _) {});
      await world.container.read(_topology.future);

      world.nats.announceTopology(
        _organization,
        skir.OrganizationTopologyChanged.unknown,
      );

      final failed = await world.container.eventually(
        _topology,
        (value) => value.hasError,
        description: "the failed projection",
      );
      expect(
        failed.error,
        isA<ApiException>().having((error) => error.code, "code", 422),
      );
    });

    test("a snapshot delayed past a reconnect keeps the accepted "
        "configuration and takes the incoming membership", () async {
      final world = testWorld([
        signedIn(ada, organization: acme),
        servicesBackend(
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [_realm],
            engines: [_engine],
          ),
        ),
      ]);
      await world.initialized();
      world.container.listen(_topology, (_, _) {});
      await world.container.read(_topology.future);
      final reply = Completer<Uint8List>();
      world.nats.registerHandler(_watchSubject, (_) => reply.future);

      world.nats
        ..disconnect()
        ..reconnect();
      await eventually(
        () => expect(world.nats.requestsTo(_watchSubject), hasLength(2)),
      );
      final configuredHost =
          (paperHost(
                  "host1",
                  revision: 3,
                  engines: ["paper"],
                  reconciled: _appliedOnce,
                  state: skir.HostRuntimeState.defaultInstance,
                ).toMutable()
                ..entrypoint = "CONFIRMED"
                ..topologyRevision = skir.ReconciledRevision(
                  desired: 3,
                  applied: 2,
                )
                ..state = skir.HostRuntimeState(
                  status: skir.HostRuntimeStatus.reconciling,
                  message: null,
                  updatedAt: DateTime.utc(2026),
                ))
              .toFrozen();
      world.container
          .read(serviceResourceRepositoryProvider(_organization))
          .acceptConfiguration(
            skir.HostConfigurationChange(
              host: configuredHost,
              realm: _realm,
              engine: null,
              removedResources: [_engine.engineId],
            ),
          );
      await world.container.eventually(
        _topology,
        (value) => value.value?.hosts.single.revision == 3,
        description: "the accepted configuration",
      );

      reply.complete(
        skir.WatchOrganizationTopologyResponse.serializer.toBytes(
          skir.WatchOrganizationTopologyResponse.wrapList(
            skir.OrganizationTopologySnapshot(
              hosts: [_host],
              realms: [],
              engines: [],
            ),
          ),
        ),
      );
      final reconciled = (await world.container.eventually(
        _topology,
        (value) => value.value?.realms.isEmpty ?? false,
        description: "the delayed snapshot",
      )).requireValue;
      expect(reconciled.hosts.single, configuredHost);
      expect(reconciled.engines, isEmpty);

      world.nats.announceTopology(
        _organization,
        skir.OrganizationTopologyChanged.wrapObservationsReported(
          skir.HostExecutionObservation(
            host: paperHost(
              "host1",
              engines: ["paper"],
              reconciled: _appliedOnce,
              state: hostRuntimeState(updatedAt: DateTime.utc(2027)),
            ),
            realm: null,
            engine: null,
          ),
        ),
      );
      final observed = (await world.container.eventually(
        _topology,
        (value) =>
            value.value?.hosts.single.state.status ==
            skir.HostRuntimeStatus.active,
        description: "the later observation",
      )).requireValue;
      expect(observed.hosts.single.revision, 3);
      expect(observed.hosts.single.entrypoint, "CONFIRMED");
    });

    test(
      "a manual refresh reloads the snapshot over one subscription",
      () async {
        final world = testWorld([
          signedIn(ada, organization: acme),
          servicesBackend(
            topology: skir.OrganizationTopologySnapshot(
              hosts: [],
              realms: [],
              engines: [],
            ),
          ),
        ]);
        await world.initialized();
        world.container.listen(_topology, (_, _) {});
        await world.container.read(_topology.future);
        world.nats.registerHandler(
          _watchSubject,
          (_) => skir.WatchOrganizationTopologyResponse.serializer.toBytes(
            skir.WatchOrganizationTopologyResponse.wrapList(
              skir.OrganizationTopologySnapshot(
                hosts: [_host],
                realms: [_realm],
                engines: [],
              ),
            ),
          ),
        );

        world.container.read(_topology.notifier).refresh();

        await world.container.eventually(
          _topology,
          (value) => value.value?.realms.length == 1,
          description: "the refreshed snapshot",
        );
        expect(world.nats.connection.subscriptionSubjects, [_listenSubject]);
      },
    );

    test("commands of one organization change only its topology, and a "
        "closed watch leaves its subscription", () async {
      final globex = organization("Globex");
      final world = testWorld([
        signedIn(ada, organization: acme, others: [globex]),
        servicesBackend(
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      await world.initialized();
      world.nats
        ..registerHandler(
          "cloud.to.user.ada.organization.globex.topology.watch",
          (_) => skir.WatchOrganizationTopologyResponse.serializer.toBytes(
            skir.WatchOrganizationTopologyResponse.wrapList(
              skir.OrganizationTopologySnapshot(
                hosts: [_host],
                realms: [],
                engines: [],
              ),
            ),
          ),
        )
        ..registerHandler(
          _configureSubject,
          (_) => skir.ConfigureServiceHostResponse.serializer.toBytes(
            skir.ConfigureServiceHostResponse.createSuccess(
              host: paperHost(
                "host1",
                revision: 2,
                engines: ["paper"],
                reconciled: _appliedOnce,
                state: skir.HostRuntimeState.defaultInstance,
              ),
              realm: null,
              engine: null,
              removedResources: [],
            ),
          ),
        );
      final other = organizationTopologyControllerProvider(
        globex.organizationId,
      );
      final watch = world.container.listen(_topology, (_, _) {});
      world.container.listen(other, (_, _) {});
      await world.container.read(_topology.future);
      await world.container.read(other.future);

      await world.servicesOf(_organization).configure(_host);

      await world.container.eventually(
        _topology,
        (value) => value.value?.hosts.single.revision == 2,
        description: "the configured Acme host",
      );
      expect(world.container.read(other).requireValue.hosts.single.revision, 1);
      watch.close();
      world.container.invalidate(_topology);
      await eventually(
        () => expect(world.nats.connection.subscriptionSubjects, [
          "cloud.from.organization.globex.topology.watch",
        ]),
      );
    });

    test("host configuration sends the host, its expected revision and the "
        "execution", () async {
      final world = testWorld([
        signedIn(ada, organization: acme),
        servicesBackend(
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      await world.initialized();
      world.container.listen(_topology, (_, _) {});
      await world.container.read(_topology.future);
      skir.ConfigureServiceHostRequest? sent;
      world.nats.registerHandler(_configureSubject, (data) {
        sent = skir.ConfigureServiceHostRequest.serializer.fromBytes(data);
        return skir.ConfigureServiceHostResponse.serializer.toBytes(
          skir.ConfigureServiceHostResponse.createSuccess(
            host: paperHost(
              "host1",
              revision: 2,
              engines: ["paper"],
              reconciled: _appliedOnce,
              state: skir.HostRuntimeState.defaultInstance,
            ),
            realm: null,
            engine: null,
            removedResources: [],
          ),
        );
      });
      final execution = skir.HostExecutionConfiguration(
        realm: skir.HostedRealmConfiguration(
          primaryEngine: skir.EngineTarget(
            engineId: "paper",
            versionConstraint: "*",
          ),
        ),
        primaryEngine: null,
      );

      await world.servicesOf(_organization).configure(_host, execution);

      expect(sent?.hostId, _host.hostId);
      expect(sent?.expectedRevision, 1);
      expect(sent?.execution, execution);
    });

    for (final conflict in [false, true]) {
      for (final eventFirst in [false, true]) {
        final outcome = conflict ? "conflict" : "success";
        final order = eventFirst ? "after" : "before";
        test("a configuration $outcome and its watch event converge to one "
            "topology when the reply arrives $order the event", () async {
          final world = testWorld([
            signedIn(ada, organization: acme),
            servicesBackend(
              topology: skir.OrganizationTopologySnapshot(
                hosts: [_host],
                realms: [_realm],
                engines: [],
              ),
            ),
          ]);
          await world.initialized();
          world.container.listen(_topology, (_, _) {});
          await world.container.read(_topology.future);
          final reply = Completer<skir.ConfigureServiceHostResponse>();
          world.nats.registerHandler(
            _configureSubject,
            (_) async => skir.ConfigureServiceHostResponse.serializer.toBytes(
              await reply.future,
            ),
          );
          final change = skir.HostConfigurationChange(
            host: paperHost(
              "host1",
              revision: 2,
              engines: ["paper"],
              reconciled: _appliedOnce,
              state: skir.HostRuntimeState.defaultInstance,
            ),
            realm: null,
            engine: null,
            removedResources: [_realm.realmId],
          );
          final event =
              skir.OrganizationTopologyChanged.wrapConfigurationChanged(change);

          final command = world.servicesOf(_organization).configure(_host);
          await eventually(
            () =>
                expect(world.nats.requestsTo(_configureSubject), hasLength(1)),
          );
          if (eventFirst) world.nats.announceTopology(_organization, event);
          reply.complete(
            conflict
                ? skir.ConfigureServiceHostResponse.createConflictError(
                    actual: change,
                  )
                : skir.ConfigureServiceHostResponse.wrapSuccess(change),
          );
          await command;
          if (!eventFirst) world.nats.announceTopology(_organization, event);

          final converged = (await world.container.eventually(
            _topology,
            (value) => value.value?.hosts.single.revision == 2,
            description: "the configured host",
          )).requireValue;
          expect(converged.realms, isEmpty);
        });
      }
    }

    test("a configure reply arriving after the watch restarted updates the "
        "new watch", () async {
      final world = testWorld([
        signedIn(ada, organization: acme),
        servicesBackend(
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      await world.initialized();
      world.container.listen(_topology, (_, _) {});
      await world.container.read(_topology.future);
      final reply = Completer<skir.ConfigureServiceHostResponse>();
      world.nats.registerHandler(
        _configureSubject,
        (_) async => skir.ConfigureServiceHostResponse.serializer.toBytes(
          await reply.future,
        ),
      );
      final command = world.servicesOf(_organization).configure(_host);
      await eventually(
        () => expect(world.nats.requestsTo(_configureSubject), hasLength(1)),
      );

      world.container.invalidate(_topology);
      await world.container.read(_topology.future);
      reply.complete(
        skir.ConfigureServiceHostResponse.createSuccess(
          host: paperHost(
            "host1",
            revision: 2,
            engines: ["paper"],
            reconciled: _appliedOnce,
            state: skir.HostRuntimeState.defaultInstance,
          ),
          realm: null,
          engine: null,
          removedResources: [],
        ),
      );
      await command;

      await world.container.eventually(
        _topology,
        (value) => value.value?.hosts.single.revision == 2,
        description: "the configured host on the new watch",
      );
    });
  });

  group("topology recovery", () {
    testWidgets("a service coming back online reloads the topology", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        servicesBackend(
          services: [
            service(
              "host1",
              name: "host_one",
              role: skir.ServiceRole.createHost(version: "1"),
              status: skir.ServiceStatus.offline,
            ),
          ],
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [_realm],
            engines: [],
          ),
        ),
      ]);
      expect(panel.world.nats.requestsTo(_watchSubject), hasLength(1));

      panel.world.nats.announceServices(
        _organization,
        skir.OrganizationServicesChanged.wrapUpdate(
          service(
            "host1",
            name: "host_one",
            role: skir.ServiceRole.createHost(version: "1"),
            status: skir.ServiceStatus.online,
          ),
        ),
      );

      await panel.eventually(
        () => expect(panel.world.nats.requestsTo(_watchSubject), hasLength(2)),
      );
    });

    testWidgets("a service coming back online while the snapshot loads joins "
        "that snapshot", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        servicesBackend(
          services: [
            service(
              "host1",
              name: "host_one",
              role: skir.ServiceRole.createHost(version: "1"),
              status: skir.ServiceStatus.offline,
            ),
          ],
        ),
      ]);
      final reply = Completer<Uint8List>();
      panel.world.nats.registerHandler(_watchSubject, (_) => reply.future);
      panel.container.read(_topology.notifier).refresh();
      await panel.eventually(
        () => expect(panel.world.nats.requestsTo(_watchSubject), hasLength(2)),
      );

      panel.world.nats.announceServices(
        _organization,
        skir.OrganizationServicesChanged.wrapUpdate(
          service(
            "host1",
            name: "host_one",
            role: skir.ServiceRole.createHost(version: "1"),
            status: skir.ServiceStatus.online,
          ),
        ),
      );
      await panel.settle();
      expect(panel.world.nats.requestsTo(_watchSubject), hasLength(2));

      reply.complete(
        skir.WatchOrganizationTopologyResponse.serializer.toBytes(
          skir.WatchOrganizationTopologyResponse.wrapList(
            skir.OrganizationTopologySnapshot(
              hosts: [_host],
              realms: [_realm],
              engines: [],
            ),
          ),
        ),
      );
      await panel.eventually(
        () =>
            expect(panel.container.read(_topology).value?.realms, hasLength(1)),
      );
      await panel.settle();
      expect(panel.world.nats.requestsTo(_watchSubject), hasLength(2));
    });
  });
}
