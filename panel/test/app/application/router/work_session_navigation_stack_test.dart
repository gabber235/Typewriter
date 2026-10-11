import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

LocalWorkScope _scope(String organization) => LocalWorkScope(
  userId: "user",
  organizationId: skir.recordId("organization:$organization"),
);

final class _Fixture {
  _Fixture({Widget servicesPage = const Text("Services")}) {
    access = RouteAccessCoordinator(
      authentication: AuthenticationRouteAccess()
        ..setDecision(const RouteAuthenticationDecision.authenticated()),
      organizations: OrganizationRouteAccess()
        ..setState(
          const OrganizationRouteAccessState.available(
            principalId: "user",
            organizationIds: {"one", "two"},
          ),
        ),
    );
    router = _MountedAppRouter(
      access,
      WorkSessionLossController(() => scope, () => protected),
      confirmWorkSessionLoss: (_) => confirm(),
      confirmWorkSessionPop: confirm,
      servicesPage: servicesPage,
    );
  }
  late final RouteAccessCoordinator access;
  late final AppRouter router;
  LocalWorkScope scope = _scope("two");
  bool protected = false;
  bool decision = false;
  int confirmations = 0;
  Completer<bool>? pending;
  Future<bool> confirm() async {
    confirmations++;
    return pending?.future ?? decision;
  }

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    await router.navigate(OrganizationRoute(organizationId: "two"));
    await tester.pumpAndSettle();
    protected = true;
  }

  List<Object> get ids =>
      router.stackData.map((route) => route.matchId).toList();
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    access.dispose();
  }
}

/// Uses the production router and guards with inert mounted pages.
final class _MountedAppRouter extends AppRouter {
  _MountedAppRouter(
    super.access,
    super.workSessionLoss, {
    super.confirmWorkSessionLoss,
    super.confirmWorkSessionPop,
    this.servicesPage = const Text("Services"),
  });

  final Widget servicesPage;
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: PageInfo(
        IndexRoute.name,
        builder: (_) => const Scaffold(body: Text("Index")),
      ),
      path: "/",
    ),
    AutoRoute(
      page: PageInfo(
        AuthRoute.name,
        builder: (_) => const Scaffold(body: Text("Auth")),
      ),
      path: "/auth",
    ),
    AutoRoute(
      page: PageInfo(
        OrganizationRoute.name,
        builder: (data) => Scaffold(
          body: Column(
            children: [
              Text("Organization ${data.params.getString("organizationId")}"),
              const Expanded(child: AutoRouter()),
            ],
          ),
        ),
      ),
      path: "/organization/:organizationId",
      children: [
        AutoRoute(
          page: PageInfo(
            ServicesRoute.name,
            builder: (_) => Scaffold(body: servicesPage),
          ),
          path: "services",
          initial: true,
        ),
        AutoRoute(
          page: PageInfo(
            RealmRoute.name,
            builder: (_) => const Scaffold(body: AutoRouter()),
          ),
          path: "realm/:realmId",
          children: [
            AutoRoute(
              page: PageInfo(
                LibraryRoute.name,
                builder: (_) => const Scaffold(body: Text("Library")),
              ),
              path: "library",
              initial: true,
            ),
          ],
        ),
        AutoRoute(
          page: PageInfo(
            MembersRoute.name,
            builder: (_) => const Scaffold(body: Text("Members")),
          ),
          path: "members",
        ),
      ],
    ),
    AutoRoute(
      page: PageInfo(
        BookRoute.name,
        builder: (_) => const Scaffold(body: Text("Book")),
      ),
      path: "/organization/:organizationId/realm/:realmId/book/:bookId",
    ),
  ];
}

void main() {
  testWidgets(
    "organization entry retains Services while its first snapshot is pending",
    (tester) async {
      final lifecycle = _MutableLifecycle();
      var subscriptions = 0;
      var cancellations = 0;
      final services = StreamController<List<Service>>(
        onListen: () => subscriptions++,
        onCancel: () => cancellations++,
      );
      final fixture = _Fixture(
        servicesPage: Consumer(
          builder: (context, ref, _) {
            final value = ref.watch(canonicalServicesProvider);
            return Text(value.hasValue ? "Services ready" : "Services pending");
          },
        ),
      );
      final pushes = <Route>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accessTokenProvider.overrideWithValue(
              const AsyncData(AccessToken(token: "fixture-token")),
            ),
            organizationIdProvider.overrideWithValue(
              skir.recordId("organization:two"),
            ),
            canonicalOrganizationServicesProvider(
              skir.recordId("organization:two"),
            ).overrideWith(() => _PendingServices(services.stream)),
            organizationPresenceProvider.overrideWithBuild(
              (ref, notifier) => const {},
            ),
            natsLifecycleProvider.overrideWith(() => lifecycle),
          ],
          child: MaterialApp.router(
            routerConfig: fixture.router.config(
              navigatorObservers: () => [_NavigationObserver(pushes)],
            ),
            theme: buildTheme(Brightness.light),
            builder: (context, child) => Responsive(
              child: AppRequiredWidgets(
                child: RequiredNatsConnection(child: child!),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await fixture.router.navigate(OrganizationRoute(organizationId: "two"));
      await tester.pumpAndSettle();
      expect(find.text("Services pending"), findsOneWidget);
      expect(subscriptions, 1);
      final stack = fixture.ids;
      final pushCount = pushes.length;
      lifecycle.status = const NatsConnecting();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text("Services pending"), findsNothing);
      expect(
        find.text("Services pending", skipOffstage: false),
        findsOneWidget,
      );
      expect(cancellations, 0);

      services.add(const []);
      lifecycle.status = const NatsConnected();
      await tester.pumpAndSettle();
      expect(find.text("Services ready"), findsOneWidget);
      expect(fixture.ids, stack);
      expect(pushes, hasLength(pushCount));
      expect(subscriptions, 1);
      expect(cancellations, 0);

      await fixture.close(tester);
      await tester.pump(const Duration(milliseconds: 1));
      expect(cancellations, 1);
      await tester.runAsync(services.close);
    },
  );

  testWidgets("actual back within the organization remains free", (
    tester,
  ) async {
    final fixture = _Fixture();
    await fixture.mount(tester);
    unawaited(
      fixture.router.push(
        BookRoute(organizationId: "two", realmId: "realm", bookId: "book"),
      ),
    );
    await tester.pumpAndSettle();
    expect(await fixture.router.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text("Organization two"), findsOneWidget);
    expect(fixture.confirmations, 0);
    await fixture.close(tester);
  });

  testWidgets("forced revocation bypasses real back confirmation", (
    tester,
  ) async {
    final fixture = _Fixture();
    await fixture.mount(tester);
    fixture.access.authentication.setDecision(
      const RouteAuthenticationDecision.unauthenticated(),
    );
    expect(await fixture.router.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expect(fixture.router.current.name, IndexRoute.name);
    expect(fixture.confirmations, 0);
    await fixture.close(tester);
  });

  testWidgets(
    "explicit cross organization Realm descendants need one exact admission",
    (tester) async {
      final fixture = _Fixture()..decision = true;
      await fixture.mount(tester);
      await fixture.router.navigate(
        OrganizationRoute(
          organizationId: "one",
          children: [
            RealmRoute(realmId: "realm", children: [LibraryRoute()]),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Organization one"), findsOneWidget);
      expect(find.text("Library"), findsOneWidget);
      expect(fixture.scope, _scope("two"));
      expect(fixture.confirmations, 1);
      await fixture.close(tester);
    },
  );

  testWidgets(
    "stale navigation consent cannot remove a newer same scope page",
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester);
      fixture.pending = Completer<bool>();
      final navigating = fixture.router.navigate(
        OrganizationRoute(organizationId: "one"),
      );
      await tester.pump();
      unawaited(
        fixture.router.push(
          BookRoute(organizationId: "two", realmId: "realm", bookId: "book"),
        ),
      );
      await tester.pumpAndSettle();
      final before = fixture.ids;
      fixture.pending!.complete(true);
      await navigating;
      await tester.pumpAndSettle();
      expect(fixture.ids, before);
      expect(find.text("Book"), findsOneWidget);
      expect(fixture.confirmations, 1);
      await fixture.close(tester);
    },
  );

  testWidgets("another concurrent destination cannot borrow pending consent", (
    tester,
  ) async {
    final fixture = _Fixture();
    await fixture.mount(tester);
    fixture.pending = Completer<bool>();
    final navigating = fixture.router.navigate(
      OrganizationRoute(organizationId: "one"),
    );
    await tester.pump();
    final before = fixture.ids;
    await fixture.router.navigate(IndexRoute());
    expect(fixture.ids, before);
    fixture.pending!.complete(true);
    await navigating;
    await tester.pumpAndSettle();
    expect(find.text("Organization one"), findsOneWidget);
    expect(fixture.confirmations, 1);
    await fixture.close(tester);
  });

  testWidgets(
    "a pending replace pop result does not retain navigation consent",
    (tester) async {
      final fixture = _Fixture()..decision = true;
      await fixture.mount(tester);
      unawaited(
        fixture.router.replace(OrganizationRoute(organizationId: "one")),
      );
      await tester.pumpAndSettle();
      expect(find.text("Organization one"), findsOneWidget);
      expect(fixture.confirmations, 1);
      fixture
        ..scope = _scope("one")
        ..decision = false;
      await fixture.router.navigate(OrganizationRoute(organizationId: "two"));
      await tester.pumpAndSettle();
      expect(find.text("Organization one"), findsOneWidget);
      expect(fixture.confirmations, 2);
      await fixture.close(tester);
    },
  );

  testWidgets(
    "cancelled browser route admission preserves pages and URL configuration",
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester);
      final before = fixture.ids;
      final configuration = fixture.router.delegate().currentConfiguration;
      final incoming = await fixture.router
          .defaultRouteParser()
          .parseRouteInformation(
            RouteInformation(uri: Uri.parse("/organization/one/services")),
          );
      await fixture.router.delegate().setNewRoutePath(incoming);
      await tester.pumpAndSettle();
      expect(fixture.ids, before);
      expect(fixture.router.delegate().currentConfiguration, configuration);
      expect(find.text("Organization two"), findsOneWidget);
      expect(fixture.confirmations, 1);
      await fixture.close(tester);
    },
  );

  for (final operation in ["navigate", "replaceAll", "replacePath"]) {
    testWidgets("cancelled $operation preserves the mounted current stack", (
      tester,
    ) async {
      final fixture = _Fixture();
      await fixture.mount(tester);
      final before = fixture.ids;
      switch (operation) {
        case "navigate":
          await fixture.router.navigate(
            OrganizationRoute(organizationId: "one"),
          );
        case "replaceAll":
          await fixture.router.replaceAll([
            OrganizationRoute(organizationId: "one"),
          ]);
        case "replacePath":
          await fixture.router.replacePath("/organization/one/services");
      }
      await tester.pumpAndSettle();
      expect(fixture.ids, before);
      expect(find.text("Organization two"), findsOneWidget);
      expect(fixture.confirmations, 1);
      await fixture.close(tester);
    });
  }

  testWidgets(
    "approved organization admission asks once and exhausts its consent",
    (tester) async {
      final fixture = _Fixture()..decision = true;
      await fixture.mount(tester);
      await fixture.router.navigate(OrganizationRoute(organizationId: "one"));
      await tester.pumpAndSettle();
      expect(find.text("Organization one"), findsOneWidget);
      expect(fixture.confirmations, 1);
      fixture
        ..scope = _scope("one")
        ..decision = false;
      await fixture.router.navigate(OrganizationRoute(organizationId: "two"));
      await tester.pumpAndSettle();
      expect(find.text("Organization one"), findsOneWidget);
      expect(fixture.confirmations, 2);
      await fixture.close(tester);
    },
  );

  testWidgets("same organization browser navigation is free", (tester) async {
    final fixture = _Fixture();
    await fixture.mount(tester);
    final incoming = await fixture.router
        .defaultRouteParser()
        .parseRouteInformation(
          RouteInformation(uri: Uri.parse("/organization/two/members")),
        );
    await fixture.router.delegate().setNewRoutePath(incoming);
    await tester.pumpAndSettle();
    expect(find.text("Members"), findsOneWidget);
    expect(fixture.confirmations, 0);
    await fixture.close(tester);
  });

  testWidgets(
    "pageless dialog dismissal does not ask to destroy a work scope",
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester);
      final before = fixture.ids;
      unawaited(
        showDialog<void>(
          context: fixture.router.navigatorKey.currentContext!,
          builder: (_) => const AlertDialog(content: Text("Dialog")),
        ),
      );
      await tester.pumpAndSettle();
      expect(await fixture.router.maybePop(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text("Dialog"), findsNothing);
      expect(fixture.ids, before);
      expect(fixture.confirmations, 0);
      await fixture.close(tester);
    },
  );

  testWidgets(
    "actual back cancellation preserves the stack and approval pops once",
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester);
      final before = fixture.ids;
      expect(await fixture.router.maybePop(), isTrue);
      await tester.pumpAndSettle();
      expect(fixture.ids, before);
      fixture.decision = true;
      expect(await fixture.router.maybePop(), isTrue);
      await tester.pumpAndSettle();
      expect(fixture.router.current.name, IndexRoute.name);
      expect(fixture.router.stackData, hasLength(1));
      expect(fixture.confirmations, 2);
      await fixture.close(tester);
    },
  );

  testWidgets(
    "consent cannot pop a different target created while confirmation waits",
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester);
      fixture.pending = Completer<bool>();
      final popping = fixture.router.maybePop();
      await tester.pump();
      unawaited(
        fixture.router.push(
          BookRoute(organizationId: "two", realmId: "realm", bookId: "book"),
        ),
      );
      await tester.pumpAndSettle();
      final before = fixture.ids;
      fixture.pending!.complete(true);
      expect(await popping, isTrue);
      await tester.pumpAndSettle();
      expect(fixture.ids, before);
      expect(find.text("Book"), findsOneWidget);
      expect(fixture.confirmations, 1);
      await fixture.close(tester);
    },
  );

  testWidgets("forced revocation bypasses protected platform admission", (
    tester,
  ) async {
    final fixture = _Fixture();
    await fixture.mount(tester);
    fixture.access.authentication.setDecision(
      const RouteAuthenticationDecision.unauthenticated(),
    );
    final incoming = await fixture.router
        .defaultRouteParser()
        .parseRouteInformation(RouteInformation(uri: Uri.parse("/auth")));
    await fixture.router.delegate().setNewRoutePath(incoming);
    await tester.pumpAndSettle();
    expect(find.text("Auth"), findsOneWidget);
    expect(fixture.confirmations, 0);
    await fixture.close(tester);
  });
}

class _MutableLifecycle extends NatsLifecycle {
  @override
  NatsConnectionState build() => const NatsConnected();

  NatsConnectionState get status => state;

  set status(NatsConnectionState value) => state = value;
}

class _PendingServices extends CanonicalOrganizationServices {
  _PendingServices(this.stream);
  final Stream<List<Service>> stream;

  @override
  Stream<List<Service>> build(skir.RecordId organizationId) => stream;
}

class _NavigationObserver extends NavigatorObserver {
  _NavigationObserver(this.pushes);
  final List<Route> pushes;

  @override
  void didPush(Route route, Route? previousRoute) => pushes.add(route);
}
