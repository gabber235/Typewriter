import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets(
    "initial readiness and returning focus keep the realm workspace interactive",
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final organization = skir.recordId("organization:focus");
      final realm = TopologyRealm(
        realmId: skir.recordId("realm_instance:focus"),
        ownerHost: TopologyOwnerHost(
          id: skir.recordId("service_host:focus"),
          name: "focus",
        ),
        revision: 1,
        targetEngine: const TopologyEngineTarget(
          engineId: "typewritermc:paper",
          versionConstraint: "*",
        ),
        state: TopologyRuntimeState(
          status: TopologyRuntimeStatus.active,
          activeArtifactVersion: "1.0.0",
          message: null,
          updatedAt: DateTime.utc(2026),
        ),
      );
      final serviceId = skir.recordId("service:focus");
      final service = Service(
        serviceId: serviceId,
        revision: 1,
        name: "focus",
        role: HostServiceRole(version: "1.0.0"),
        createdAt: DateTime.utc(2026),
        state: ServiceState(
          status: ServiceStateStatus.online,
          lastSeen: DateTime.now(),
        ),
      );
      final services = _Services(service);
      addTearDown(services.updates.close);
      final host = TopologyHost(
        hostId: realm.ownerHost.id,
        serviceId: serviceId,
        revision: 1,
        entrypoint: "PAPER",
        canHostRealm: true,
        supportedEngines: [],
        topologyRevision: const TopologyRevision(desired: 1, applied: 1),
        state: TopologyHostState(
          status: TopologyHostStatus.active,
          message: null,
          updatedAt: DateTime.utc(2026),
        ),
      );
      final source = _Topology(
        OrganizationTopology(
          hosts: [host],
          realmInstances: [realm],
          engineInstances: [],
        ),
      );
      var taps = 0;
      await tester.pumpTestApp(
        child: OrganizationScaffold(
          child: FilledButton(
            onPressed: () => taps++,
            child: const Text("Edit value"),
          ),
        ),
        overrides: [
          organizationIdProvider.overrideWithValue(organization),
          realmIdProvider.overrideWithValue(realm.realmId),
          organizationTopologyControllerProvider(organization)
              .overrideWith(() => source),
          canonicalOrganizationServicesProvider(organization)
              .overrideWith(() => services),
          ...organizationsProviderOverrides(state: DisplayState.noItems),
          selectedAuthoringScopeProvider.overrideWithValue(null),
          authUserInfoProvider.overrideWithValue(const AsyncLoading()),
          ...appearanceProviderOverrides(),
        ],
        settle: false,
      );
      final container = tester.container(of: find.byType(OrganizationScaffold));
      await tester.pumpUntil(() {
        expect(container.read(realmInteractionProvider).suspended, isFalse);
        expect(find.text("Checking realm connection"), findsNothing);
      });
      final states = <RealmConnectionState>[];
      final observation = container.listen(
        realmInteractionProvider,
        (_, next) => states.add(next.connectionState),
      );
      addTearDown(observation.close);
      expect(source.snapshots, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(source.snapshots, 1);
      expect(states, isNot(contains(RealmConnectionState.checking)));
      expect(find.text("Checking realm connection"), findsNothing);
      await tester.tap(find.text("Edit value"));
      expect(taps, 1);
      expect(tester.takeException(), isNull);

      services.updates.add([
        service.copyWith(
          state: service.state!.copyWith(status: ServiceStateStatus.offline),
        ),
      ]);
      await tester.pump();
      expect(
        container.read(realmInteractionProvider).connectionState,
        RealmConnectionState.offline,
      );
      services.updates.add([service]);
      await tester.pumpUntil(() {
        expect(source.snapshots, 2);
        expect(container.read(realmInteractionProvider).suspended, isFalse);
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    "organization sidebar builds distinct member routes and positive badge",
    (tester) async {
      final links = OrganizationSidebarContent.organizationLinks(
        skir.recordId("organization:org1"),
        3,
      );
      final sidebarLinks = links.whereType<SidebarLink>().toList();

      expect(sidebarLinks.map((link) => link.text), [
        "Services",
        "Members",
        "Join Requests",
        "Join Codes",
      ]);
      expect(_leafName(sidebarLinks[1]), MemberListRoute.name);
      expect(_leafName(sidebarLinks[2]), JoinRequestsRoute.name);
      expect(_leafName(sidebarLinks[3]), JoinCodesRoute.name);

      await tester.pumpTestApp(child: Column(children: links));
      final trailing = sidebarLinks[2].trailing! as Semantics;
      expect(trailing.properties.label, "3 pending join requests");
      expect(find.text("3"), findsOneWidget);
    },
  );

  testWidgets("organization sidebar hides pending badge when count is zero", (
    tester,
  ) async {
    final links = OrganizationSidebarContent.organizationLinks(
      skir.recordId("organization:org1"),
      0,
    );

    await tester.pumpTestApp(child: Column(children: links));

    expect(
      find.bySemanticsLabel(RegExp("pending join requests")),
      findsNothing,
    );
    expect(
      links
          .whereType<SidebarLink>()
          .singleWhere((link) => link.text == "Join Requests")
          .trailing,
      isNull,
    );
  });
}

String _leafName(SidebarLink link) => link.route.flattened.last.routeName;

class _Topology extends OrganizationTopologyController {
  _Topology(this.topology);
  final OrganizationTopology topology;
  int snapshots = 0;

  @override
  Stream<OrganizationTopology> build(skir.RecordId organizationId) async* {
    snapshots++;
    yield topology;
  }
}

class _Services extends CanonicalOrganizationServices {
  _Services(this.initial);
  final Service initial;
  final StreamController<List<Service>> updates = StreamController.broadcast(
    sync: true,
  );

  @override
  Stream<List<Service>> build(skir.RecordId organizationId) async* {
    yield [initial];
    yield* updates.stream;
  }
}
