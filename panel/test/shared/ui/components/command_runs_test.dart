import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final first = book("First");

  testWidgets("a key press while a tapped Publish sends sends no second "
      "publish, and the key alone shows Publish busy", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);
    await panel.openSurface(first.bookId);
    await panel.reportPublication(readyPublicationStatus());
    final answer = Completer<SubmissionResult<skir.PublishAuthoringResponse>>();
    final publication = panel.world.requireRealm.publication
      ..send = () => answer.future;
    await panel.pressShifted(LogicalKeyboardKey.keyP);

    await tester.tap(find.widgetWithText(CommandButton, "Publish").first);
    await tester.pump();
    await panel.pressPrimary(LogicalKeyboardKey.enter);

    expect(semanticsButtonsReading("Publishing").isNotEmpty, isTrue);
    answer.complete(
      const SubmissionResult.confirmed(skir.PublishAuthoringResponse.noChanges),
    );
    await panel.settle();
    expect(publication.candidates, hasLength(1));
  });

  testWidgets("Ctrl or Cmd+Enter alone shows Publish busy", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [first]),
    ]);
    await panel.openSurface(first.bookId);
    await panel.reportPublication(readyPublicationStatus());
    final answer = Completer<SubmissionResult<skir.PublishAuthoringResponse>>();
    panel.world.requireRealm.publication.send = () => answer.future;
    await panel.pressShifted(LogicalKeyboardKey.keyP);

    await panel.pressPrimary(LogicalKeyboardKey.enter);
    expect(semanticsButtonsReading("Publishing").isNotEmpty, isTrue);

    answer.complete(
      const SubmissionResult.confirmed(skir.PublishAuthoringResponse.noChanges),
    );
    await panel.settle();
  });

  for (final byKey in [true, false]) {
    testWidgets("a refused publish started by ${byKey ? "key" : "tap"} tells "
        "the author why", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        realm(books: [first]),
      ]);
      await panel.openSurface(first.bookId);
      await panel.reportPublication(readyPublicationStatus());
      panel.world.requireRealm.publication.send = () async =>
          const SubmissionResult.rejected(
            message: "The Realm refused to publish",
          );
      await panel.pressShifted(LogicalKeyboardKey.keyP);

      if (byKey) {
        await panel.pressPrimary(LogicalKeyboardKey.enter);
      } else {
        await panel.tapOn(find.widgetWithText(CommandButton, "Publish").first);
      }

      // The Publish button leaves while the publication is read again, so
      // the reason shows in a snackbar.
      await panel.eventually(
        () => expect(panel.shows("The Realm refused to publish"), isTrue),
      );
    });
  }

  testWidgets("CommandRuns keeps no run for member rows that left", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(members: [member("Grace"), member("Linus")]),
    ], at: membersPage());

    await panel.holdKey(LogicalKeyboardKey.delete);
    await panel.eventually(() => expect(panel.shows("Grace"), isFalse));
    await panel.settle();

    expect(
      panel.commandRuns.commands.where((command) => command.contains("grace")),
      isEmpty,
    );
  });
}
