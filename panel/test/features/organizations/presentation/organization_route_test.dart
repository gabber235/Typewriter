import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "initial readiness and returning focus keep the realm workspace interactive",
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final organization = skir.recordId("organization:focus");
      final backend = FakeOrganizations();
      addTearDown(backend.close);
      final realm = backend.addRealm(
        organization,
        id: skir.recordId("realm_instance:focus"),
        name: "focus",
      );
      final service = backend.services(organization).single;
      final services = _Services(service);
      addTearDown(services.updates.close);
      var snapshots = 0;
      final source = _Topology(
        backend.topology(organization),
        onSnapshot: () => snapshots++,
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
          organizationsProvider.overrideWith(_NoOrganizations.new),
          selectedAuthoringScopeProvider.overrideWithValue(null),
          authUserInfoProvider.overrideWithValue(const AsyncLoading()),
          FakeAppearance().override,
        ],
        settle: false,
      );
      final container = tester.container(of: find.byType(OrganizationScaffold));
      await tester.eventually(() {
        expect(container.read(realmInteractionProvider).suspended, isFalse);
        expect(find.text("Checking realm connection"), findsNothing);
      });
      final states = <RealmConnectionState>[];
      final observation = container.listen(
        realmInteractionProvider,
        (_, next) => states.add(next.connectionState),
      );
      addTearDown(observation.close);
      expect(snapshots, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(snapshots, 1);
      expect(states, isNot(contains(RealmConnectionState.checking)));
      expect(find.text("Checking realm connection"), findsNothing);
      await tester.tap(find.text("Edit value"));
      expect(taps, 1);
      expect(tester.takeException(), isNull);

      services.updates.add([
        (service.toMutable()
              ..state =
                  (service.state!.toMutable()
                        ..status = skir.ServiceStatus.offline)
                      .toFrozen())
            .toFrozen(),
      ]);
      await tester.pump();
      expect(
        container.read(realmInteractionProvider).connectionState,
        RealmConnectionState.offline,
      );
      services.updates.add([service]);
      await tester.eventually(() {
        expect(snapshots, 2);
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
  _Topology(this.topology, {required this._onSnapshot});
  final skir.OrganizationTopologySnapshot topology;
  final void Function() _onSnapshot;

  @override
  Stream<skir.OrganizationTopologySnapshot> build(
    skir.RecordId organizationId,
  ) async* {
    _onSnapshot();
    yield topology;
  }
}

class _Services extends CanonicalOrganizationServices {
  _Services(this.initial);
  final skir.Service initial;
  final StreamController<List<skir.Service>> updates =
      StreamController.broadcast(sync: true);

  @override
  Stream<List<skir.Service>> build(skir.RecordId organizationId) async* {
    yield [initial];
    yield* updates.stream;
  }
}

/// A user who belongs to no organization yet.
class _NoOrganizations extends Organizations {
  @override
  Stream<List<skir.Organization>> build() => Stream.value(const []);
}
