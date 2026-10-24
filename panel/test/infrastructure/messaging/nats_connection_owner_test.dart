import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test(
    "retry publishes a fresh session before closing the previous client",
    () async {
      final fixture = _ConnectionFixture();
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
    final fixture = _ConnectionFixture();
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
    final fixture = _ConnectionFixture();
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
    expect(
      _ConnectionFixture.settings.toString(),
      isNot(contains("fixture-token")),
    );
    expect(
      _ConnectionFixture.settings.toString(),
      isNot(contains("fixture-seed")),
    );
  });
}

final class _ConnectionFixture {
  _ConnectionFixture() {
    owner = NatsConnectionOwner(
      settings: settings,
      clientFactory: _create,
      sessionFactory: () => clients.length.toString().padLeft(32, "0"),
      onReplacement: (client) {
        published.add(client);
        onReplacement?.call(client);
      },
    );
  }

  static final settings = NatsConnectionSettings(
    url: "nats://fixture:4222",
    token: "fixture-token",
    user: const UserInfo(sub: "fixture-user"),
    sentinel: skir.GetSentinelCredentialsResponse_Success(
      jwt: "fixture-jwt",
      seed: "fixture-seed",
    ),
    organization: skir.recordId("organization:fixture"),
  );
  final clients = <FakeNatsClient>[];
  final published = <NatsClient>[];
  late final NatsConnectionOwner owner;
  void Function(NatsClient)? onReplacement;

  FakeNatsClient _create(NatsClientConfiguration configuration) {
    final client = FakeNatsClient(
      actorId: configuration.actorId,
      organizationId: configuration.organizationId,
      connectionSession: configuration.connectionSession,
    );
    clients.add(client);
    return client;
  }

  Future<void> close() async {
    await owner.close();
    await Future.wait(clients.map((client) => client.close()));
  }
}
