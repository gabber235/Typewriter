import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final first = book("First");
  final firstPath =
      "/organization/acme/realm/main/resource/${first.bookId.value}";

  testWidgets("returning to the panel window keeps the open Realm "
      "interactive without checking its connection again", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);
    expect(panel.shows("Checking realm connection"), isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(panel.shows("Checking realm connection"), isFalse);
    expect(panel.shows("Realm connection lost"), isFalse);
    await panel.resources.row("First").open();
    await panel.eventually(() => expect(panel.path, firstPath));
  });

  testWidgets("a Realm whose host comes back is interactive again", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
      realmHostStopped,
    ]);
    await panel.eventually(
      () => expect(panel.shows("Realm connection lost"), isTrue),
    );

    panel.world.organizations.resumeHost(
      panel.world.requireRealm.scope.realmId,
    );

    await panel.eventually(
      () => expect(panel.shows("Realm connection lost"), isFalse),
    );
    expect(panel.shows("Checking realm connection"), isFalse);
    expect(panel.shows("Realm connection lost"), isFalse);
    await panel.resources.row("First").open();
    await panel.eventually(() => expect(panel.path, firstPath));
  });

  final destinations = {
    "Services": "/organization/acme/services",
    "Members": "/organization/acme/members",
    "Join Requests": "/organization/acme/members/join-requests",
    "Join Codes": "/organization/acme/members/join-codes",
  };
  for (final MapEntry(key: link, value: path) in destinations.entries) {
    testWidgets("the organization sidebar link $link opens its page", (
      tester,
    ) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        membership(),
      ]);

      await panel.tapOn(find.text(link).first);

      await panel.eventually(() => expect(panel.path, path));
    });
  }

  testWidgets("the organization sidebar counts pending join requests", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membership(
        joinRequests: [
          joinRequest("ken", name: "ken"),
          joinRequest("linus", name: "linus"),
          joinRequest("lea", name: "lea"),
        ],
      ),
    ]);

    // The sidebar reads no semantics yet (its nodes drop out of the tree),
    // so the badge is found by the count it shows beside the link.
    await panel.eventually(() => expect(panel.shows("3"), isTrue));
  });

  testWidgets("the organization sidebar shows no badge without pending join "
      "requests", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membership(),
    ]);

    expect(panel.shows("Join Requests"), isTrue);
    expect(panel.shows("0"), isFalse);
  });
}
