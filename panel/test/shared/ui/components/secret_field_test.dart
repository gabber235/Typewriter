import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const secret = "join-4821";
  final neverExpiring = SizedBox(
    width: 600,
    child: SecretField(
      title: "Join Code",
      description: "Invite new members.",
      onGenerate: () => SecretFieldRevealed(value: secret, expiresAt: null),
    ),
  );

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
    // The generate button says it copied, in place of a toast.
    expect(find.text("Copied"), findsOneWidget);

    await tester.pump(const Duration(seconds: 31));
    await panel.settle();

    expect(panel.reads(secret), isFalse);
    expect(panel.shows("Expired"), isTrue);
    expect(find.text("Copy"), findsNothing);
    expect(find.text("Regenerate"), findsOneWidget);
  });

  testWidgets("a refused clipboard keeps the generated secret and says only "
      "the copy failed", (tester) async {
    tester.refuseClipboard();
    final panel = await tester.showComponent(neverExpiring);

    await panel.tapOn(find.text("Generate"));

    await panel.eventually(() => expect(panel.reads(secret), isTrue));
    expect(panel.failures, [
      "Generate failed. Could not copy to the clipboard",
    ]);
    expect(find.text("Copied"), findsNothing);
    expect(find.text("Copy"), findsOneWidget);
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
    expect(find.text("Copied"), findsOneWidget);
  });

  testWidgets("a secret without expiry stays revealed", (tester) async {
    tester.recordClipboard();
    final panel = await tester.showComponent(neverExpiring);

    await panel.tapOn(find.text("Generate"));
    await tester.pump(const Duration(hours: 1));
    await panel.settle();

    await panel.eventually(() => expect(panel.reads(secret), isTrue));
    expect(panel.shows("Expired"), isFalse);
  });
}
