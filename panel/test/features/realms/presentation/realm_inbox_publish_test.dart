import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final first = book("First");

  testWidgets("with a ready publication Ctrl or Cmd+Enter publishes once and "
      "the Publish button shows its key cap", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);
    await panel.openSurface(first.bookId);
    await panel.reportPublication(readyPublicationStatus());
    final publication = panel.world.requireRealm.publication
      ..send = () async => const SubmissionResult.confirmed(
        skir.PublishAuthoringResponse.noChanges,
      );
    await panel.pressShifted(LogicalKeyboardKey.keyP);
    // The inbox's Publish button and the action row's both show it.
    expect(
      find.descendant(
        of: find.bySemanticsLabel("Publish").first,
        matching: find.byIcon(Icons.keyboard_return_rounded),
      ),
      findsOneWidget,
    );

    await panel.pressPrimary(LogicalKeyboardKey.enter);

    expect(publication.candidates, hasLength(1));
  });

  testWidgets("with a blocked publication no Publish shows and Ctrl or "
      "Cmd+Enter sends no publish request", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);
    await panel.openSurface(first.bookId);
    await panel.reportPublication(blockedPublicationStatus());
    final publication = panel.world.requireRealm.publication;
    await panel.pressShifted(LogicalKeyboardKey.keyP);

    await panel.pressPrimary(LogicalKeyboardKey.enter);

    expect(find.text("Publish"), findsNothing);
    expect(publication.candidates, isEmpty);
  });
}
