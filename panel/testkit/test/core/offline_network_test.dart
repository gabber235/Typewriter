import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final backend = Uri.parse(AppConfig.nats.desktopUrl);

  test("a test world cannot open a socket to the address the panel is "
      "built against", () async {
    testWorld([signedIn(ada, organization: acme)]);

    await expectLater(
      Socket.connect(backend.host, backend.port),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          "message",
          contains("${backend.host}:${backend.port}"),
        ),
      ),
    );
  });

  testWidgets("a pumped panel cannot open a socket either", (tester) async {
    await tester.pumpPanel([signedIn(ada, organization: acme)]);

    await tester.runAsync(
      () => expectLater(
        Socket.connect(backend.host, backend.port),
        throwsA(isA<StateError>()),
      ),
    );
  });

  testWidgets("a signed in panel connects to NATS only through the world's "
      "double", (tester) async {
    final panel = await tester.pumpPanel([signedIn(ada, organization: acme)]);

    await panel.eventually(
      () => expect(panel.world.nats.connection.actorId, ada.id),
    );
    expect(
      await panel.container.read(natsProvider.future),
      isA<FakeNatsClient>(),
    );
  });
}
