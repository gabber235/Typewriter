import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const secret = "join-4821";

  testWidgets("a generated secret is revealed, copied, and hidden again when "
      "it expires", (tester) async {
    final clipboard = tester.recordClipboard();
    final panel = await tester.showComponent(
      SizedBox(
        width: 600,
        child: SecretField(
          title: "Join Code",
          description: "Invite new members.",
          onGenerate: () => SecretFieldRevealed(
            value: secret,
            expiresAt: clock.now().add(const Duration(seconds: 30)),
          ),
        ),
      ),
    );
    expect(panel.reads(secret), isFalse);

    await panel.tapOn(find.text("Generate"));

    await panel.eventually(() => expect(panel.reads(secret), isTrue));
    expect(clipboard, [secret]);
    expect(panel.shows("Copied to clipboard"), isTrue);

    await tester.pump(const Duration(seconds: 31));
    await panel.settle();

    expect(panel.reads(secret), isFalse);
    expect(panel.shows("Expired"), isTrue);
    expect(find.text("Copy"), findsNothing);
    expect(find.text("Regenerate"), findsOneWidget);
  });

  testWidgets("with automatic copying off, the secret is copied only on "
      "request", (tester) async {
    final clipboard = tester.recordClipboard();
    final panel = await tester.showComponent(
      SizedBox(
        width: 600,
        child: SecretField(
          title: "Join Code",
          description: "Invite new members.",
          copyOnGenerate: false,
          onGenerate: () => SecretFieldRevealed(value: secret, expiresAt: null),
        ),
      ),
    );

    await panel.tapOn(find.text("Generate"));

    await panel.eventually(() => expect(panel.reads(secret), isTrue));
    expect(clipboard, isEmpty);

    await panel.tapOn(find.text("Copy"));

    expect(clipboard, [secret]);
  });

  testWidgets("a secret without expiry stays revealed", (tester) async {
    tester.recordClipboard();
    final panel = await tester.showComponent(
      SizedBox(
        width: 600,
        child: SecretField(
          title: "Join Code",
          description: "Invite new members.",
          onGenerate: () => SecretFieldRevealed(value: secret, expiresAt: null),
        ),
      ),
    );

    await panel.tapOn(find.text("Generate"));
    await tester.pump(const Duration(hours: 1));
    await panel.settle();

    await panel.eventually(() => expect(panel.reads(secret), isTrue));
    expect(panel.shows("Expired"), isFalse);
  });
}
