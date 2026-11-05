import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _leave = "Leave this work session?";

final _globex = organization("Globex");
final _first = book("First");

/// Ada works in Acme's Realm with work she has not saved, and may also open
/// Globex.
final _working = <Trait>[
  signedIn(ada, organization: acme, others: [_globex]),
  realm(books: [_first]),
  unsavedWork,
];

final _acmeServices = PanelLocation.route(
  OrganizationRoute(organizationId: "acme"),
);

final _globexRoute = OrganizationRoute(organizationId: "globex");

/// The First Book's own surface in Acme's Realm.
final _firstRoute = OrganizationRoute(
  organizationId: "acme",
  children: [
    RealmRoute(
      realmId: "main",
      children: [ResourceRoute(resourceId: _first.bookId.value)],
    ),
  ],
);

void main() {
  group("within the organization", () {
    testWidgets("creation reveal opens the created resource without asking", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(_working);
      final scope = panel.world.requireRealm.scope;
      final intent = panel.container.read(
        Provider(ResourceCreationNavigationIntent.new),
      );

      await intent.reveal(
        AuthoringResourceIdentifier.inScope(scope, _first.bookId),
      );
      await panel.settle();

      expect(panel.dialog.showing(_leave), isFalse);
      expect(panel.path, endsWith("/resource/${_first.bookId.value}"));
      expect(panel.resources.selected, [_first.bookId]);
    });

    testWidgets("back within the organization does not ask", (tester) async {
      final panel = await tester.pumpPanel([
        ..._working,
        membership(),
      ], at: _acmeServices);
      final services = panel.path;
      await panel.open("/organization/acme/members");
      expect(panel.path, "/organization/acme/members");

      await panel.back();

      expect(panel.dialog.showing(_leave), isFalse);
      expect(panel.path, services);
    });

    testWidgets("an address in the same organization opens without asking", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([..._working, membership()]);

      await panel.open("/organization/acme/members");

      expect(panel.dialog.showing(_leave), isFalse);
      expect(panel.path, "/organization/acme/members");
    });

    testWidgets("closing a dialog with back does not ask", (tester) async {
      final panel = await tester.pumpPanel(_working);
      final before = panel.path;
      unawaited(
        showDialog<void>(
          context: panel.router.navigatorKey.currentContext!,
          builder: (_) => const AlertDialog(content: Text("Dialog")),
        ),
      );
      await panel.settle();

      await panel.back();

      expect(panel.shows("Dialog"), isFalse);
      expect(panel.dialog.showing(_leave), isFalse);
      expect(panel.path, before);
    });
  });

  group("leaving the organization", () {
    for (final (name, leave) in <(String, Future<void> Function(AppRouter))>[
      ("navigate", (router) => router.navigate(_globexRoute)),
      ("replaceAll", (router) => router.replaceAll([_globexRoute])),
      (
        "replacePath",
        (router) => router.replacePath("/organization/globex/services"),
      ),
    ]) {
      testWidgets("staying refuses $name and keeps the current page", (
        tester,
      ) async {
        final panel = await tester.pumpPanel(_working);
        final before = panel.path;

        unawaited(leave(panel.router));
        await panel.settle();
        await panel.dialog.choose("Stay", message: _leave);

        expect(panel.dialog.showing(_leave), isFalse);
        expect(panel.path, before);
      });
    }

    testWidgets("staying refuses an address and keeps the current page", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(_working);
      final before = panel.path;

      await panel.open("/organization/globex/services");
      await panel.dialog.choose("Stay", message: _leave);

      expect(panel.dialog.showing(_leave), isFalse);
      expect(panel.path, before);
    });

    testWidgets("a Realm in another organization opens after one answer", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(
        _working,
        at: PanelLocation.route(_globexRoute),
      );

      unawaited(
        panel.router.navigate(
          OrganizationRoute(
            organizationId: "acme",
            children: [
              RealmRoute(realmId: "main", children: [const RealmHomeRoute()]),
            ],
          ),
        ),
      );
      await panel.settle();
      await panel.dialog.choose("Leave", message: _leave);

      expect(panel.dialog.showing(_leave), isFalse);
      expect(panel.path, "/organization/acme/realm/main");
    });

    for (final (name, leave) in <(String, Future<void> Function(AppRouter))>[
      ("navigate", (router) => router.navigate(_globexRoute)),
      ("replace", (router) => router.replace(_globexRoute)),
    ]) {
      testWidgets("an approved $name is spent once the organization opened", (
        tester,
      ) async {
        final panel = await tester.pumpPanel(_working, at: _acmeServices);
        unawaited(leave(panel.router));
        await panel.settle();
        await panel.dialog.choose("Leave", message: _leave);
        expect(panel.path, startsWith("/organization/globex"));

        unawaited(
          panel.router.navigate(OrganizationRoute(organizationId: "acme")),
        );
        await panel.settle();
        await panel.dialog.choose("Stay", message: _leave);

        expect(panel.path, startsWith("/organization/globex"));
      });
    }

    testWidgets("a pending answer does not admit another destination", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(_working, at: _acmeServices);
      final before = panel.path;
      unawaited(panel.router.navigate(_globexRoute));
      await panel.settle();

      unawaited(panel.router.navigate(IndexRoute()));
      await panel.settle();
      expect(panel.path, before);

      await panel.dialog.choose("Leave", message: _leave);
      expect(panel.dialog.showing(_leave), isFalse);
      expect(panel.path, startsWith("/organization/globex"));
    });

    testWidgets("a leave answered after a newer page opened keeps that page", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(_working);
      unawaited(panel.router.navigate(_globexRoute));
      await panel.settle();
      unawaited(panel.router.navigate(_firstRoute));
      await panel.settle();
      final newer = panel.path;

      await panel.dialog.choose("Leave", message: _leave);

      expect(panel.path, newer);
      expect(newer, endsWith("/resource/${_first.bookId.value}"));
    });

    testWidgets(
      "a leave answered after its navigation was superseded is void",
      (tester) async {
        final panel = await tester.pumpPanel(_working);
        final before = panel.path;
        var current = true;
        unawaited(
          panel.router.navigate(_globexRoute, isCurrent: () => current),
        );
        await panel.settle();

        current = false;
        await panel.dialog.choose("Leave", message: _leave);

        expect(panel.path, before);
      },
    );
  });

  group("back out of the organization", () {
    testWidgets("staying keeps the page and leaving goes back once", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(_working, at: _acmeServices);
      final before = panel.path;

      await panel.back();
      await panel.dialog.choose("Stay", message: _leave);
      expect(panel.path, before);

      await panel.back();
      await panel.dialog.choose("Leave", message: _leave);
      expect(panel.dialog.showing(_leave), isFalse);
      expect(panel.path, "/");
    });

    testWidgets("a leave answered after a newer page opened keeps that page", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(_working, at: _acmeServices);
      await panel.back();
      unawaited(panel.router.navigate(_firstRoute));
      await panel.settle();
      final newer = panel.path;

      await panel.dialog.choose("Leave", message: _leave);

      expect(panel.path, newer);
      expect(newer, endsWith("/resource/${_first.bookId.value}"));
    });
  });

  testWidgets("an ended session leaves for sign in without asking", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(_working, at: _acmeServices);

    await panel.container.read(authProvider.notifier).signOut();
    await panel.settle();
    await panel.back();
    await panel.open("/auth");

    expect(panel.dialog.showing(_leave), isFalse);
    expect(panel.path, "/auth");
  });
}
