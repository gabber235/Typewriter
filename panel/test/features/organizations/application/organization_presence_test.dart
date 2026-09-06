import "package:flutter_test/flutter_test.dart";
import "package:riverpod/riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/organization/v1/presence.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/provider_test_utils.dart";

const _ownSubject =
    "typewriter.presence.organization.org1.user.authenticated-user";
const _wildcardSubject = "typewriter.presence.organization.org1.user.*";

void main() {
  test("publishes route presence on the authenticated user subject", () async {
    final harness = _Harness(
      route: "/organization/org1/realm/realm1/book/book1/page/page1",
    );
    final subscription = harness.container.listen(
      organizationPresenceProvider,
      (_, _) {},
    );

    await harness.container.read(organizationPresenceProvider.future);

    expect(harness.nats.subscriptionSubjects, [_wildcardSubject]);
    expect(harness.nats.publications, hasLength(1));
    expect(harness.nats.publications.single.subject, _ownSubject);
    final event = wire.PresenceEvent.serializer.fromBytes(
      harness.nats.publications.single.payload,
    );
    final active = switch (event) {
      wire.PresenceEvent_activeWrapper(:final value) => value,
      _ => throw StateError("Expected active presence"),
    };
    expect(active.sequence, 1);
    final page = switch (active.location) {
      wire.PresenceLocation_pageWrapper(:final value) => value,
      _ => throw StateError("Expected page presence"),
    };
    expect(page.realmId, recordId("service:realm1"));
    expect(page.bookId, recordId("book:book1"));
    expect(page.pageId, recordId("page:page1"));
    expect(page.activity, wire.PageActivity.overview);

    subscription.close();
    harness.container.dispose();
    await Future<void>.delayed(Duration.zero);
    final left = wire.PresenceEvent.serializer.fromBytes(
      harness.nats.publications.last.payload,
    );
    expect(left, isA<wire.PresenceEvent_leftWrapper>());
    await harness.nats.dispose();
  });

  test("trusts subject identity and ignores stale session messages", () async {
    final harness = _Harness();
    final subscription = harness.container.listen(
      organizationPresenceProvider,
      (_, _) {},
    );
    await harness.container.read(organizationPresenceProvider.future);

    harness.emit(
      "remote-user",
      wire.PresenceEvent.createActive(
        sessionId: "remote-session",
        sequence: 2,
        location: wire.PresenceLocation.createServices(),
      ),
    );
    await waitForProvider(
      harness.container,
      organizationPresenceProvider,
      (state) => state.value?.length == 1,
      description: "remote presence",
    );
    final key = const PresenceSessionKey("remote-user", "remote-session");
    expect(
      harness.container
          .read(organizationPresenceProvider)
          .requireValue[key]
          ?.userId,
      "remote-user",
    );

    harness.emit(
      "remote-user",
      wire.PresenceEvent.createActive(
        sessionId: "remote-session",
        sequence: 1,
        location: wire.PresenceLocation.createMembers(),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    final retained = harness.container
        .read(organizationPresenceProvider)
        .requireValue[key]!;
    expect(retained.presence.sequence, 2);
    expect(
      retained.presence.location,
      isA<wire.PresenceLocation_servicesWrapper>(),
    );

    harness.emit(
      "remote-user",
      wire.PresenceEvent.createLeft(sessionId: "remote-session"),
    );
    await waitForProvider(
      harness.container,
      organizationPresenceProvider,
      (state) => state.value?.isEmpty ?? false,
      description: "departed remote presence",
    );

    subscription.close();
    harness.container.dispose();
    await harness.nats.dispose();
  });
}

final class _Harness {
  _Harness({String route = "/organization/org1/services"}) {
    container = ProviderContainer.test(
      overrides: [
        userIdProvider.overrideWith((ref) async => "authenticated-user"),
        organizationIdProvider.overrideWithValue(recordId("organization:org1")),
        currentRouteProvider.overrideWithValue(route),
        natsProvider.overrideWithValue(nats),
      ],
    );
  }

  final FakeNatsClient nats = FakeNatsClient();
  late final ProviderContainer container;

  void emit(String userId, wire.PresenceEvent event) {
    nats.emitMessageOnSubject(
      "typewriter.presence.organization.org1.user.$userId",
      wire.PresenceEvent.serializer.toBytes(event),
    );
  }
}
