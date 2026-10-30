import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _scope = "cloud.to.user.ada.organization.acme";
const _updateSubject = "$_scope.services.update";
const _configureSubject = "$_scope.topology.configure";
const _nameRule =
    "Use at least three lowercase letters or digits separated by underscores";

final _service = service(
  "paper",
  name: "gabbe",
  createdAt: DateTime.utc(2026, 8, 21),
  status: null,
);

final _appliedOnce = skir.ReconciledRevision(desired: 1, applied: 1);

final _host = paperHost(
  "paper",
  engines: ["paper"],
  reconciled: _appliedOnce,
  state: hostRuntimeState(updatedAt: DateTime.utc(2026, 8, 21)),
);

final _realmPath = editorRootPath.field("realm");
final _enginePath = editorRootPath.field("engine");

void main() {
  group("service name", () {
    testWidgets("a valid name keeps the focused field and saves the name "
        "with the service's own revision", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        servicesBackend(
          services: [
            service(
              "paper",
              name: "gabbe",
              createdAt: DateTime.utc(2026, 8, 21),
            ),
          ],
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      await panel.services.card("Paper host", "Gabbe").select();
      skir.UpdateOrganizationServiceRequest? sent;
      panel.world.nats.registerHandler(_updateSubject, (data) {
        sent = skir.UpdateOrganizationServiceRequest.serializer.fromBytes(data);
        return skir.UpdateOrganizationServiceResponse.serializer.toBytes(
          skir.UpdateOrganizationServiceResponse.wrapSuccess(
            (_service.toMutable()
                  ..revision = 2
                  ..name = "gabb")
                .toFrozen(),
          ),
        );
      });

      await panel.field("Name").type("gabb");

      await panel.eventually(() => expect(sent?.name, "gabb"));
      expect(sent?.expectedRevision, 1);
      expect(panel.field("Name").isFocused, isTrue);
      expect(panel.field("Name").value, "gabb");
    });

    testWidgets("a runtime report keeps the focused name field", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        servicesBackend(
          services: [
            service(
              "paper",
              name: "gabbe",
              createdAt: DateTime.utc(2026, 8, 21),
            ),
          ],
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      await panel.services.card("Paper host", "Gabbe").select();
      await panel.field("Name").focus();

      panel.world.nats.announceTopology(
        acme.organizationId,
        skir.OrganizationTopologyChanged.wrapObservationsReported(
          skir.HostExecutionObservation(
            host:
                (_host.toMutable()
                      ..state = skir.HostRuntimeState(
                        status: skir.HostRuntimeStatus.reconciling,
                        message: null,
                        updatedAt: DateTime.utc(2026, 8, 22),
                      ))
                    .toFrozen(),
            realm: null,
            engine: null,
          ),
        ),
      );
      await panel.settle();

      expect(panel.services.statusOf("Paper host", "Gabbe"), "Reconciling");
      expect(panel.field("Name").isFocused, isTrue);
      expect(panel.field("Name").value, "gabbe");
      expect(panel.world.nats.requestsTo(_updateSubject), isEmpty);
    });

    for (final observed in [false, true]) {
      testWidgets("an invalid name stays in the focused field with the naming "
          "rule${observed ? " through a runtime report" : " for five idle seconds"} "
          "and is never sent", (tester) async {
        final panel = await tester.pumpPanel([
          signedIn(ada, organization: acme),
          servicesBackend(
            services: [
              service(
                "paper",
                name: "gabbe",
                createdAt: DateTime.utc(2026, 8, 21),
              ),
            ],
            topology: skir.OrganizationTopologySnapshot(
              hosts: [_host],
              realms: [],
              engines: [],
            ),
          ),
        ]);
        await panel.services.card("Paper host", "Gabbe").select();

        await panel.field("Name").type("ga");
        if (observed) {
          panel.world.nats.announceTopology(
            acme.organizationId,
            skir.OrganizationTopologyChanged.wrapObservationsReported(
              skir.HostExecutionObservation(
                host: _host,
                realm: null,
                engine: null,
              ),
            ),
          );
        } else {
          await tester.pump(const Duration(seconds: 5));
        }
        await panel.settle();

        expect(panel.field("Name").isFocused, isTrue);
        expect(panel.field("Name").value, "ga");
        expect(panel.shows(_nameRule), isTrue);
        expect(panel.world.nats.requestsTo(_updateSubject), isEmpty);
      });
    }

    testWidgets("runtime fields of a service cannot be written", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        servicesBackend(
          services: [
            service(
              "paper",
              name: "gabbe",
              createdAt: DateTime.utc(2026, 8, 21),
            ),
          ],
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      await panel.services.card("Paper host", "Gabbe").select();
      final host = panel.container.read(inspectionSessionProvider).hosts.first;
      final runtime = host.document.bindings.entries.firstWhere(
        (entry) => !entry.value.editable,
      );

      expect(
        await host.write(
          skir.BindingRef(
            bindingId: runtime.key,
            path: skir.ValuePath(segments: const []),
          ),
          skir.DataValue.wrapStringValue("changed"),
          context: host.rootInvocation,
        ),
        isA<PortablePresentationWriteRejected>(),
      );
    });

    testWidgets("inspecting a service with its host shows one Name field", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        servicesBackend(
          services: [
            service(
              "paper",
              name: "gabbe",
              createdAt: DateTime.utc(2026, 8, 21),
            ),
          ],
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);

      panel.container.read(selectionProvider.notifier).selectAll([
        ServiceIdentifier(_service.serviceId),
        ServiceHostIdentifier(_host.hostId),
      ]);
      await panel.settle();

      expect([
        for (final field in visibleTextFields())
          if (field.spoken.startsWith("Name")) field.spoken,
      ], hasLength(1));
    });

    testWidgets("inspecting two hosts of one service shows one Name field "
        "and one configuration that drafts both hosts", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        servicesBackend(
          services: [
            service(
              "paper",
              name: "gabbe",
              createdAt: DateTime.utc(2026, 8, 21),
            ),
          ],
          topology: skir.OrganizationTopologySnapshot(
            hosts: [
              _host,
              paperHost(
                "paper_backup",
                service: _service.serviceId,
                engines: ["paper"],
                reconciled: _appliedOnce,
                state: hostRuntimeState(updatedAt: DateTime.utc(2026, 8, 21)),
              ),
            ],
            realms: [],
            engines: [],
          ),
        ),
      ]);

      panel.container.read(selectionProvider.notifier).selectAll([
        ServiceHostIdentifier(_host.hostId),
        ServiceHostIdentifier(skir.recordId("service_host:paper_backup")),
      ]);
      await panel.settle();

      expect([
        for (final field in visibleTextFields())
          if (field.spoken.startsWith("Name")) field.spoken,
      ], hasLength(1));
      expect(panel.inspector.operations, ["Unbind (2)"]);

      await panel.inspector.toggle("Host a Realm");

      expect(
        panel.shows("2 drafts"),
        isTrue,
        reason: "The shared configuration drafts a change for each host",
      );
    });
  });

  group("host configuration", () {
    testWidgets("checking Host a Realm drafts a Realm target until Apply", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        servicesBackend(
          services: [
            service(
              "paper",
              name: "gabbe",
              createdAt: DateTime.utc(2026, 8, 21),
            ),
          ],
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      await panel.services.card("Paper host", "Gabbe").select();
      expect(panel.shows("Host a Realm"), isTrue);
      expect(panel.shows("Run an execution engine"), isTrue);
      expect(panel.shows("Realm target"), isFalse);

      await panel.inspector.toggle("Host a Realm");

      expect(panel.inspector.isChecked("Host a Realm"), isTrue);
      expect(panel.shows("Realm target"), isTrue);
      expect(panel.applyControls.actions, ["Discard", "Apply"]);
      expect(panel.world.nats.requestsTo(_configureSubject), isEmpty);
    });

    testWidgets("an incomplete host configuration is never sent", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        servicesBackend(
          services: [
            service(
              "paper",
              name: "gabbe",
              createdAt: DateTime.utc(2026, 8, 21),
            ),
          ],
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      await panel.services.card("Paper host", "Gabbe").select();
      final owner = panel.appliedEditor
        ..update(_realmPath, hostWorkload("RealmHosted", {"target": ""}));

      expect(await panel.apply(owner), isA<MutationInvalid>());
      expect(panel.world.nats.requestsTo(_configureSubject), isEmpty);
    });

    testWidgets("Apply sends the Realm target and the hosted Realm engine "
        "once and only as a host configuration", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        servicesBackend(
          services: [
            service(
              "paper",
              name: "gabbe",
              createdAt: DateTime.utc(2026, 8, 21),
            ),
          ],
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      await panel.services.card("Paper host", "Gabbe").select();
      final owner = panel.appliedEditor;
      skir.ConfigureServiceHostRequest? sent;
      panel.world.nats.registerHandler(_configureSubject, (data) {
        sent = skir.ConfigureServiceHostRequest.serializer.fromBytes(data);
        return skir.ConfigureServiceHostResponse.serializer.toBytes(
          skir.ConfigureServiceHostResponse.createSuccess(
            host: paperHost(
              "paper",
              revision: 2,
              engines: ["paper"],
              reconciled: _appliedOnce,
              state: hostRuntimeState(updatedAt: DateTime.utc(2026, 8, 21)),
            ),
            realm: realmInstance("paper", host: "paper"),
            engine: engineInstance(
              "paper",
              realm: realmInstance("paper", host: "paper"),
              host: "paper",
              hostName: "gabbe",
            ),
            removedResources: [],
          ),
        );
      });

      owner
        ..update(_realmPath, hostWorkload("RealmHosted", {"target": "paper@*"}))
        ..update(
          _enginePath,
          hostWorkload("EngineEnabled", {
            "target": "paper@*",
            "realm": "realm_instance:elsewhere",
          }),
        );
      expect(owner.draftDiagnostics, isEmpty);
      expect(panel.world.nats.requestsTo(_configureSubject), isEmpty);

      expect(await panel.apply(owner), isA<MutationSuccess>());

      expect(panel.world.nats.requestsTo(_configureSubject), hasLength(1));
      expect(
        sent?.execution.realm?.primaryEngine,
        skir.EngineTarget(engineId: "paper", versionConstraint: "*"),
      );
      expect(
        sent?.execution.primaryEngine?.realm,
        skir.EngineRealmSelection.hostedRealm,
      );
      expect(panel.world.nats.requestsTo(_updateSubject), isEmpty);
      expect(owner.hasWork, isFalse);
    });

    testWidgets("an engine without a hosted Realm needs another host's Realm", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        servicesBackend(
          services: [
            service(
              "paper",
              name: "gabbe",
              createdAt: DateTime.utc(2026, 8, 21),
            ),
          ],
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      await panel.services.card("Paper host", "Gabbe").select();
      final owner = panel.appliedEditor
        ..update(
          _enginePath,
          hostWorkload("EngineEnabled", {"target": "paper@*", "realm": ""}),
        );
      expect(
        owner.draftDiagnostics.map((issue) => issue.path),
        contains(_enginePath.field("realm")),
      );
      expect(await panel.apply(owner), isA<MutationInvalid>());

      owner
        ..update(_realmPath, hostWorkload("RealmHosted", {"target": "paper@*"}))
        ..update(_realmPath, hostWorkload("RealmDisabled"));
      expect(await panel.apply(owner), isA<MutationInvalid>());
      expect(panel.world.nats.requestsTo(_configureSubject), isEmpty);

      owner.discardDraft();
      expect(owner.hasWork, isFalse);
    });

    final assignable = {
      "another host's Realm with the engine target": (
        realmInstance("compatible", host: "external"),
        true,
      ),
      "a Realm of another version": (
        realmInstance("incompatible", host: "external", version: "^2"),
        false,
      ),
      "a Realm of another engine": (
        realmInstance("other", host: "external", engine: "other"),
        false,
      ),
      "the Realm this host runs": (
        realmInstance("hosted", host: "paper"),
        false,
      ),
    };
    for (final MapEntry(key: realm, value: (instance, accepted))
        in assignable.entries) {
      testWidgets("an engine ${accepted ? "accepts" : "refuses"} $realm as its "
          "assigned Realm", (tester) async {
        final panel = await tester.pumpPanel([
          signedIn(ada, organization: acme),
          servicesBackend(
            services: [
              service(
                "paper",
                name: "gabbe",
                createdAt: DateTime.utc(2026, 8, 21),
              ),
            ],
            topology: skir.OrganizationTopologySnapshot(
              hosts: [
                paperHost(
                  "paper",
                  engines: ["paper", "other"],
                  reconciled: _appliedOnce,
                  state: hostRuntimeState(updatedAt: DateTime.utc(2026, 8, 21)),
                ),
              ],
              realms: [instance],
              engines: [],
            ),
          ),
        ]);
        await panel.services.card("Paper host", "Gabbe").select();
        final owner = panel.appliedEditor
          ..update(_realmPath, hostWorkload("RealmDisabled"))
          ..update(
            _enginePath,
            hostWorkload("EngineEnabled", {
              "target": "paper@*",
              "realm": instance.realmId.id,
            }),
          );

        expect(
          owner.draftDiagnostics.map((issue) => issue.message),
          accepted ? isEmpty : ["Choose an available Realm"],
        );
      });
    }

    testWidgets("Apply sends the assigned Realm of another host", (
      tester,
    ) async {
      final compatible = realmInstance("compatible", host: "external");
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        servicesBackend(
          services: [
            service(
              "paper",
              name: "gabbe",
              createdAt: DateTime.utc(2026, 8, 21),
            ),
          ],
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [compatible],
            engines: [],
          ),
        ),
      ]);
      await panel.services.card("Paper host", "Gabbe").select();
      final owner = panel.appliedEditor;
      skir.ConfigureServiceHostRequest? sent;
      panel.world.nats.registerHandler(_configureSubject, (data) {
        sent = skir.ConfigureServiceHostRequest.serializer.fromBytes(data);
        return skir.ConfigureServiceHostResponse.serializer.toBytes(
          skir.ConfigureServiceHostResponse.createSuccess(
            host: paperHost(
              "paper",
              revision: 2,
              engines: ["paper"],
              reconciled: _appliedOnce,
              state: hostRuntimeState(updatedAt: DateTime.utc(2026, 8, 21)),
            ),
            realm: null,
            engine: engineInstance(
              "paper",
              realm: compatible,
              host: "paper",
              hostName: "gabbe",
            ),
            removedResources: [],
          ),
        );
      });

      owner.update(
        _enginePath,
        hostWorkload("EngineEnabled", {
          "target": "paper@*",
          "realm": compatible.realmId.id,
        }),
      );
      expect(await panel.apply(owner), isA<MutationSuccess>());

      expect(
        sent?.execution.primaryEngine?.realm,
        skir.EngineRealmSelection.createExistingRealm(
          realmId: compatible.realmId,
        ),
      );
    });

    testWidgets("leaving the organization after confirming drops a host "
        "draft without sending it", (tester) async {
      final globex = organization("Globex");
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme, others: [globex]),
        servicesBackend(
          services: [
            service(
              "paper",
              name: "gabbe",
              createdAt: DateTime.utc(2026, 8, 21),
            ),
          ],
          topology: skir.OrganizationTopologySnapshot(
            hosts: [_host],
            realms: [],
            engines: [],
          ),
        ),
      ]);
      await panel.services.card("Paper host", "Gabbe").select();
      for (final projection in ["services", "topology"]) {
        panel.world.nats.registerHandler(
          "cloud.to.user.ada.organization.globex.$projection.watch",
          (_) => projection == "services"
              ? skir.WatchOrganizationServicesResponse.serializer.toBytes(
                  skir.WatchOrganizationServicesResponse.wrapList([]),
                )
              : skir.WatchOrganizationTopologyResponse.serializer.toBytes(
                  skir.WatchOrganizationTopologyResponse.wrapList(
                    skir.OrganizationTopologySnapshot.defaultInstance,
                  ),
                ),
        );
      }
      panel.appliedEditor.update(
        _realmPath,
        hostWorkload("RealmHosted", {"target": "paper@*"}),
      );
      await panel.settle();
      expect(panel.shows("1 draft"), isTrue);

      unawaited(
        panel.container
            .read(appRouterProvider)
            .navigate(OrganizationRoute(organizationId: "globex")),
      );
      await panel.settle();
      await panel.dialog.choose("Leave", message: "Leave this work session?");

      expect(panel.path, startsWith("/organization/globex"));
      expect(panel.shows("1 draft"), isFalse);
      expect(
        panel.world.nats.connection.requests.where(
          (request) => request.subject.endsWith(".topology.configure"),
        ),
        isEmpty,
      );
    });
  });

  group("removed selection", () {
    final realm = realmInstance("paper", host: "paper");
    final cards = {
      "host": ("Paper host", "Gabbe", "Entry point"),
      "Realm": ("Realm", "Paper", "Owner host"),
      "engine": ("Engine", "paper *", "Owner host"),
    };
    for (final MapEntry(key: kind, value: (badge, name, field))
        in cards.entries) {
      testWidgets("removing the selected $kind clears the selection and the "
          "inspector", (tester) async {
        final panel = await tester.pumpPanel([
          signedIn(ada, organization: acme),
          servicesBackend(
            services: [
              service(
                "paper",
                name: "gabbe",
                createdAt: DateTime.utc(2026, 8, 21),
              ),
            ],
            topology: skir.OrganizationTopologySnapshot(
              hosts: [_host],
              realms: [realm],
              engines: [
                engineInstance(
                  "paper",
                  realm: realm,
                  host: "paper",
                  hostName: "gabbe",
                ),
              ],
            ),
          ),
        ]);
        await panel.services.card(badge, name).select();
        expect(panel.shows(field), isTrue);

        panel.world.nats.announceTopology(
          acme.organizationId,
          skir.OrganizationTopologyChanged.wrapReplace(
            skir.OrganizationTopologySnapshot.defaultInstance,
          ),
        );
        await panel.settle();

        expect(panel.container.read(selectionProvider), isEmpty);
        expect(panel.shows(field), isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets("a rename in flight through a dropout is sent once and the "
      "name stays after the connection comes back", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      servicesBackend(
        services: [
          service("paper", name: "gabbe", createdAt: DateTime.utc(2026, 8, 21)),
        ],
        topology: skir.OrganizationTopologySnapshot(
          hosts: [_host],
          realms: [],
          engines: [],
        ),
      ),
    ]);
    await panel.services.card("Paper host", "Gabbe").select();
    final reply = Completer<Uint8List>();
    panel.world.nats.registerHandler(_updateSubject, (_) => reply.future);

    // The save spinner keeps animating while the reply is held, so the
    // name is typed without waiting for the panel to settle.
    await panel.field("Name").focus();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: "renamed",
        selection: TextSelection.collapsed(offset: 7),
      ),
    );
    await panel.eventually(
      () => expect(panel.world.nats.requestsTo(_updateSubject), hasLength(1)),
    );
    panel.world.nats
      ..disconnect()
      ..reconnect();
    reply.complete(
      skir.UpdateOrganizationServiceResponse.serializer.toBytes(
        skir.UpdateOrganizationServiceResponse.wrapSuccess(
          (_service.toMutable()
                ..revision = 2
                ..name = "renamed")
              .toFrozen(),
        ),
      ),
    );

    await panel.eventually(() => expect(panel.field("Name").value, "renamed"));
    expect(panel.world.nats.requestsTo(_updateSubject), hasLength(1));
  });
}
