import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _settings = NatsConnectionSettings(
  url: "nats://fixture:4222",
  token: "fixture-token",
  user: const UserInfo(sub: "fixture-user"),
  sentinel: skir.GetSentinelCredentialsResponse_Success(
    jwt: "fixture-jwt",
    seed: "fixture-seed",
  ),
  organization: skir.recordId("organization:fixture"),
);

void main() {
  test(
    "retry publishes a fresh session before closing the previous client",
    () async {
      final fixture = OwnedNatsConnections(_settings);
      addTearDown(fixture.close);
      final previous = fixture.owner.client;
      fixture.onReplacement = (client) {
        expect(client, same(fixture.owner.client));
        expect(previous.connectionState, isA<NatsConnected>());
      };

      await fixture.owner.retry();

      expect(fixture.published, [fixture.clients.last]);
      expect(fixture.clients, hasLength(2));
      expect(
        fixture.clients.last.connectionSession,
        isNot(fixture.clients.first.connectionSession),
      );
      expect(previous.connectionState, isA<NatsClosed>());
    },
  );

  test("retries are serialized and publish in order", () async {
    final fixture = OwnedNatsConnections(_settings);
    addTearDown(fixture.close);

    await Future.wait([fixture.owner.retry(), fixture.owner.retry()]);

    expect(fixture.clients, hasLength(3));
    expect(fixture.published, fixture.clients.skip(1).toList());
    expect(fixture.owner.client, same(fixture.clients.last));
    expect(
      fixture.clients.take(2).map((client) => client.connectionState),
      everyElement(isA<NatsClosed>()),
    );
  });

  test("closing the owner blocks a later retry", () async {
    final fixture = OwnedNatsConnections(_settings);
    addTearDown(fixture.close);

    await fixture.owner.close();

    await expectLater(
      fixture.owner.retry(),
      throwsA(
        isA<NatsClientException>().having(
          (error) => error.kind,
          "kind",
          NatsFailureKind.closed,
        ),
      ),
    );
    expect(fixture.published, isEmpty);
    expect(fixture.clients, hasLength(1));
    expect(fixture.clients.single.connectionState, isA<NatsClosed>());
  });

  test("settings do not print authentication credentials", () {
    final printed = _settings.toString();
    expect(printed, isNot(contains("fixture-token")));
    expect(printed, isNot(contains("fixture-jwt")));
    expect(printed, isNot(contains("fixture-seed")));
  });
}
