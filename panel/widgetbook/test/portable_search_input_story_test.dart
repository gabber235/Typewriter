import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/portable_search_input.stories.dart";

void main() {
  testWidgets("inline search story expands and explicitly selects a reward", (
    tester,
  ) async {
    await tester.pumpWidget(portableSearchInputStory(width: 260));
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.text("Description"));
    await tester.tap(find.byKey(const ValueKey("authored_search_summary")));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text("Description")).dy,
      greaterThan(before.dy),
    );
    await tester.tap(find.text("Experience reward"));
    await tester.pumpAndSettle();
    expect(find.text("Experience reward"), findsOneWidget);
    expect(find.byType(QueryBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
