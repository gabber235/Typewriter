import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("the panel tells the organization which resource the user has "
      "open, and that they left once it closes", (tester) async {
    final first = book("First");
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);

    await panel.resources.row("First").open();

    await panel.eventually(() {
      final event = panel.world.nats
          .presencePublished(ada.id, acme.organizationId)
          .last;
      expect(event, isA<skir.PresenceEvent_activeWrapper>());
      final location =
          (event as skir.PresenceEvent_activeWrapper).value.location;
      expect(
        location,
        skir.PresenceLocation.createResource(
          realmId: skir.recordId("service:main"),
          resourceId: first.bookId,
        ),
      );
    });

    await tester.pumpWidget(const SizedBox.shrink());
    expect(
      panel.world.nats.presencePublished(ada.id, acme.organizationId).last,
      isA<skir.PresenceEvent_leftWrapper>(),
    );
  });

  testWidgets("another member's newest location shows until they leave", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([signedIn(ada, organization: acme)]);

    panel.world.nats.announcePresence(
      grace.id,
      skir.PresenceEvent.createActive(
        sessionId: "grace-tab",
        sequence: 2,
        location: skir.PresenceLocation.createServices(),
      ),
      organization: acme.organizationId,
    );
    await panel.eventually(
      () => expect(panel.world.othersPresent, {
        grace.id: skir.PresenceLocation.createServices(),
      }),
    );

    // A heartbeat that arrives late carries an older sequence.
    panel.world.nats.announcePresence(
      grace.id,
      skir.PresenceEvent.createActive(
        sessionId: "grace-tab",
        sequence: 1,
        location: skir.PresenceLocation.createMembers(),
      ),
      organization: acme.organizationId,
    );
    await panel.settle();
    expect(panel.world.othersPresent, {
      grace.id: skir.PresenceLocation.createServices(),
    });

    panel.world.nats.announcePresence(
      grace.id,
      skir.PresenceEvent.createLeft(sessionId: "grace-tab"),
      organization: acme.organizationId,
    );
    await panel.eventually(() => expect(panel.world.othersPresent, isEmpty));
  });

  testWidgets("a member who stops sending heartbeats disappears after 45 "
      "seconds", (tester) async {
    final panel = await tester.pumpPanel([signedIn(ada, organization: acme)]);
    panel.world.nats.announcePresence(
      grace.id,
      skir.PresenceEvent.createActive(
        sessionId: "grace-tab",
        sequence: 1,
        location: skir.PresenceLocation.createServices(),
      ),
      organization: acme.organizationId,
    );
    await panel.eventually(
      () => expect(panel.world.othersPresent, contains(grace.id)),
    );

    await tester.pump(const Duration(seconds: 30));
    expect(panel.world.othersPresent, contains(grace.id));

    await tester.pump(const Duration(seconds: 30));
    expect(panel.world.othersPresent, isEmpty);
  });

  testWidgets("the user's own session never shows as someone else, and "
      "presence in another organization never shows", (tester) async {
    final panel = await tester.pumpPanel([signedIn(ada, organization: acme)]);
    await panel.eventually(
      () => expect(
        panel.world.nats.presencePublished(ada.id, acme.organizationId),
        isNotEmpty,
      ),
    );
    final own =
        (panel.world.nats.presencePublished(ada.id, acme.organizationId).last
                as skir.PresenceEvent_activeWrapper)
            .value;

    panel.world.nats.announcePresence(
      ada.id,
      skir.PresenceEvent.createActive(
        sessionId: own.sessionId,
        sequence: own.sequence + 1,
        location: own.location,
      ),
      organization: acme.organizationId,
    );
    panel.world.nats.announcePresence(
      grace.id,
      skir.PresenceEvent.createActive(
        sessionId: "grace-tab",
        sequence: 1,
        location: skir.PresenceLocation.createServices(),
      ),
      organization: organization("Globex").organizationId,
    );
    await panel.settle();

    expect(panel.world.othersPresent, isEmpty);
  });
}
