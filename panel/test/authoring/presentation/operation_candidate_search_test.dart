import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "an operation form searches the declared candidates of a resource field",
    (tester) async {
      final fixture = AuthoredGraphFixture(candidateSearch: true);
      final requests = <skir.RealmPresentationSearchRequest>[];
      final panel = await fixture.showSourceItem(tester);
      fixture.realmDouble.answerWatchSearch = (request) {
        requests.add(request);
        return Stream.value(
          skir.RealmPresentationSearchUpdate.createSnapshot(
            subscriptionId: request.subscriptionId,
            status: skir.RealmPresentationSearchStatus.ready,
            values: [fixture.option(fixture.destination, "Destination page")],
            guidance: const [],
            diagnostics: const [],
          ),
        );
      };
      await panel.resources.row("Source").operations.choose("Move to");

      await panel.tapOn(
        find.bySemanticsLabel(RegExp("Activate search input")).last,
      );
      await panel.queryBar.type("Dest");
      await panel.settle();
      expect(requests, isNotEmpty);
      expect(
        requests.last.capabilityId,
        AuthoredGraphFixture.moveCandidateSearch,
      );
      expect(requests.last.operationContext, isNotNull);
      expect(requests.last.operationContext!.invocation.targets, [
        fixture.source,
      ]);
      expect(find.text("Destination page"), findsWidgets);
      // The candidate is chosen with the keyboard, like every drop offer.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await panel.tapOn(find.text("Submit"));
      expect(panel.shows("Submit"), isFalse);
      expect(
        fixture.preparations.last.input
            ?.authoredField("destination")
            ?.authoredString,
        fixture.destination.value,
      );
      expect(
        fixture.workspace.document.relations.children[fixture.destination],
        contains(fixture.source),
      );
    },
  );

  testWidgets("fields without candidates keep their default controls", (
    tester,
  ) async {
    final fixture = AuthoredGraphFixture();
    final panel = await fixture.showSourceItem(tester);
    await panel.resources.row("Source").operations.choose("Move to");
    // The destination is a plain text field, not a candidate search.
    expect(
      find.bySemanticsLabel(RegExp("Activate search input")),
      findsNothing,
    );
    expect(visibleTextFields(), hasLength(1));
    await panel.tapOn(find.text("Cancel"));
  });
}
