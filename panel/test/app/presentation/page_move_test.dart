import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "rows ripple in from the right going deeper and from the left going back",
    (tester) async {
      final panel = await tester.pumpOrganizationPages();
      await tester.followLink("Members");
      await panel.settle();

      await tester.followLink("Join Codes");
      expect(tester.firstRowShift().dx, greaterThan(0));
      await panel.settle();

      await tester.followLink("Members");
      expect(tester.firstRowShift().dx, lessThan(0));
    },
  );

  testWidgets("sidebar siblings ripple by sidebar order", (tester) async {
    final panel = await tester.pumpOrganizationPages();
    await tester.followLink("Join Requests");
    await panel.settle();

    await tester.followLink("Join Codes");
    expect(tester.firstRowShift().dy, greaterThan(0));
    await panel.settle();

    await tester.followLink("Join Requests");
    expect(tester.firstRowShift().dy, lessThan(0));
  });

  testWidgets("under reduced motion rows sit at their place at once", (
    tester,
  ) async {
    final panel = await tester.pumpOrganizationPages(reduced: true);
    await tester.followLink("Members");
    await panel.settle();
    await tester.followLink("Join Codes");

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Transform &&
            widget.transform.getTranslation().length > 0.5,
      ),
      findsNothing,
    );
  });
}
