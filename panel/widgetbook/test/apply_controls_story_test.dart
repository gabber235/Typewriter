import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editing/apply_controls.stories.dart";

void main() {
  testWidgets("Apply and Discard reconcile the field across repeated edits", (
    tester,
  ) async {
    await tester.pumpWidget(applyControlsStory());
    await tester.pumpAndSettle();
    final field = find.byType(TextField);
    expect(find.text("Apply"), findsNothing);
    await tester.enterText(field, "Draft");
    await tester.pump();
    expect(find.text("Apply"), findsOneWidget);
    await tester.tap(find.text("Discard"));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, "Saved value");
    expect(find.text("Apply"), findsNothing);
    await tester.enterText(field, "Accepted");
    await tester.pump();
    await tester.tap(find.text("Apply"));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, "Accepted");
    expect(find.text("Apply"), findsNothing);
    await tester.enterText(field, "Later");
    await tester.pump();
    expect(find.text("Apply"), findsOneWidget);
    await tester.tap(find.text("Discard"));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, "Accepted");
    expect(find.text("Apply"), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    "unknown delivery retains the field and allowed recovery actions",
    (tester) async {
      await tester.pumpWidget(applyControlsStory(uncertain: true));
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      await tester.enterText(field, "Pending");
      await tester.pump();
      await tester.tap(find.text("Apply"));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, "Pending");
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, "Apply"))
            .onPressed,
        isNull,
      );
      expect(find.text("Refresh"), findsOneWidget);
      expect(find.text("Retry"), findsNothing);
      expect(find.text("Discard"), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
