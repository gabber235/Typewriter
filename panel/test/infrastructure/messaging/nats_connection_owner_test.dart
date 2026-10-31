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
  late FakeNats server;
  late NatsConnectionOwner owner;
  late List<NatsClient> published;
  void Function(NatsClient client)? onReplacement;

  setUp(() {
    server = FakeNats();
    published = [];
    onReplacement = null;
    owner = NatsConnectionOwner(
      settings: _settings,
      clientFactory: server.connect,
      // Each session is numbered by how many connections came before it.
      sessionFactory: () =>
          server.connections.length.toString().padLeft(32, "0"),
      onReplacement: (client) {
        published.add(client);
        onReplacement?.call(client);
      },
    );
    addTearDown(() async {
      await owner.close();
      await server.close();
    });
  });

  test(
    "retry publishes a fresh session before closing the previous client",
    () async {
      final previous = owner.client;
      onReplacement = (client) {
        expect(client, same(owner.client));
        expect(previous.connectionState, isA<NatsConnected>());
      };

      await owner.retry();

      expect(published, [server.connections.last]);
      expect(server.connections, hasLength(2));
      expect(
        server.connections.last.connectionSession,
        isNot(server.connections.first.connectionSession),
      );
      expect(previous.connectionState, isA<NatsClosed>());
    },
  );

  test("retries are serialized and publish in order", () async {
    await Future.wait([owner.retry(), owner.retry()]);

    expect(server.connections, hasLength(3));
    expect(published, server.connections.skip(1).toList());
    expect(owner.client, same(server.connections.last));
    expect(
      server.connections.take(2).map((client) => client.connectionState),
      everyElement(isA<NatsClosed>()),
    );
  });

  test("closing the owner blocks a later retry", () async {
    await owner.close();

    await expectLater(
      owner.retry(),
      throwsA(
        isA<NatsClientException>().having(
          (error) => error.kind,
          "kind",
          NatsFailureKind.closed,
        ),
      ),
    );
    expect(published, isEmpty);
    expect(server.connections, hasLength(1));
    expect(server.connections.single.connectionState, isA<NatsClosed>());
  });

  test("settings do not print authentication credentials", () {
    final printed = _settings.toString();
    expect(printed, isNot(contains("fixture-token")));
    expect(printed, isNot(contains("fixture-jwt")));
    expect(printed, isNot(contains("fixture-seed")));
  });
}
