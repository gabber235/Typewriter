import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const serviceRefusal = "Only an owner can remove an owner.";
  const plainRefusal = "This did not go through. Try again.";

  testWidgets("a hold over three rows sends them together, keeps going past "
      "a refusal, and refuses each row on its own", (tester) async {
    final source = await tester.showAnimatedItems(numberedItems(3));
    final first = Completer<void>();
    final plan = HoldPlan<String>(
      weight: HoldWeight.heavy,
      verb: "Remove",
      rows: source.rows,
      targets: (_) => {"2", "0", "1"},
      outcome: (ids) => "Remove ${ids.length} rows?",
      each: (_, id) => switch (id) {
        "0" => first.future,
        "1" => throw const ApiException(code: 403, message: serviceRefusal),
        _ => throw StateError("the socket closed"),
      },
    );

    final attempt = plan.begin(source.ref)!;
    expect(attempt.ids, ["0", "1", "2"], reason: "targets run in list order");
    final result = runHold(attempt, () => source.ref);
    await tester.pump();
    for (final row in ["Row 0", "Row 1", "Row 2"]) {
      expect(
        tester.textDecorationOf(find.text(row)),
        TextDecoration.lineThrough,
      );
    }

    first.complete();
    await result;
    await tester.pump();

    expect(
      tester.textDecorationOf(find.text("Row 0")),
      TextDecoration.lineThrough,
      reason: "a sent row stays sending until its item leaves",
    );
    for (final row in ["Row 1", "Row 2"]) {
      expect(
        tester.textDecorationOf(find.text(row)),
        isNot(TextDecoration.lineThrough),
      );
    }
    expect(find.text(serviceRefusal), findsOneWidget);
    expect(find.text(plainRefusal), findsOneWidget);
    expect(find.textContaining("socket"), findsNothing);
    expect(tester.takeException(), isStateError, reason: "it is reported");
    expect(source.rows["1"]!.jams, 1);
    expect(source.rows["2"]!.jams, 0);
  });
}
