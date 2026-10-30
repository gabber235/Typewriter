import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// A page holding state the user made: text typed into its field.
const _page = PanelLocation.component(
  Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 300,
      child: TextField(decoration: InputDecoration(labelText: "Note")),
    ),
  ),
);

void main() {
  for (final (kind, title, action) in [
    (NatsFailureKind.authentication, "Access denied", "Sign out"),
    (NatsFailureKind.permission, "Access denied", "Sign out"),
    (NatsFailureKind.protocol, "Connection incompatible", "Retry"),
    (NatsFailureKind.unavailable, "Server unavailable", "Retry"),
    (NatsFailureKind.timeout, "Server unavailable", "Retry"),
    (NatsFailureKind.noResponders, "Server unavailable", "Retry"),
    (NatsFailureKind.closed, "Connection failed", "Retry"),
    (NatsFailureKind.unknown, "Connection failed", "Retry"),
  ]) {
    testWidgets("$kind shows its actionable failure category", (tester) async {
      final panel = await tester.pumpPanel([signedIn(ada)], at: _page);

      panel.world.nats.disconnect(
        failure: NatsClientException(kind: kind, message: "safe message"),
      );
      await panel.settle();

      expect(panel.shows(title), isTrue);
      expect(panel.labeled(action), findsOneWidget);
      expect(panel.field("Note").exists, isFalse);
    });
  }

  testWidgets("an unknown failure never shows its secret cause", (
    tester,
  ) async {
    const secret = "super-secret-token";
    final panel = await tester.pumpPanel([signedIn(ada)], at: _page);

    panel.world.nats.disconnect(
      failure: const NatsClientException(
        kind: NatsFailureKind.unknown,
        message: secret,
        cause: secret,
      ),
    );
    await panel.settle();

    expect(panel.shows("Connection failed"), isTrue);
    expect(find.textContaining(secret), findsNothing);
  });

  testWidgets("a connected panel shows its page", (tester) async {
    final panel = await tester.pumpPanel([signedIn(ada)], at: _page);

    expect(panel.field("Note").exists, isTrue);
  });

  testWidgets("Retry opens a new connection", (tester) async {
    final panel = await tester.pumpPanel([signedIn(ada)], at: _page);
    final failed = panel.world.nats.connection;
    panel.world.nats.disconnect(
      failure: NatsClientException(
        kind: NatsFailureKind.unavailable,
        message: "safe message",
      ),
    );
    await panel.settle();

    await panel.tapOn(panel.labeled("Retry"));

    expect(panel.world.nats.connection, isNot(same(failed)));
  });

  testWidgets("Sign out on an access denial signs the user out", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([signedIn(ada)], at: _page);
    panel.world.nats.disconnect(
      failure: NatsClientException(
        kind: NatsFailureKind.permission,
        message: "safe message",
      ),
    );
    await panel.settle();

    await panel.tapOn(panel.labeled("Sign out"));

    await panel.eventually(() => expect(panel.world.session.user, isNull));
  });

  testWidgets("an outage keeps the page and its input until reconnected", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([signedIn(ada)], at: _page);
    final note = panel.field("Note");
    await note.type("draft");

    panel.world.nats.disconnect();
    await panel.settle();
    expect(note.exists, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    await panel.settle();

    panel.world.nats.reconnect();
    await panel.settle();
    expect(note.value, "draft");
    expect(note.isFocused, isFalse);
  });
}
