import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/hooks/deferred_value.stories.dart";
import "package:widgetbook_workspace/stories/shared/ui/components/animated_status_content.stories.dart";

void main() {
  testWidgets("timing story exposes progress and eventual debounce output", (
    tester,
  ) async {
    await tester.pumpWidget(const DeferredValueStory());
    await tester.pumpAndSettle();
    await tester.tap(find.text("Burst of 10 changes"));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(find.text("Window: 4"), findsOneWidget);
    expect(find.text("Debounce: 0"), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("Incoming: 10"), findsOneWidget);
    expect(find.text("Window: 10"), findsOneWidget);
    expect(find.text("Debounce: 10"), findsOneWidget);
  });

  testWidgets("leaving the timing story cancels an active input burst", (
    tester,
  ) async {
    await tester.pumpWidget(const DeferredValueStory());
    await tester.pumpAndSettle();
    await tester.tap(find.text("Burst of 10 changes"));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets("status story cycles through checking, counts, and quiet", (
    tester,
  ) async {
    await tester.pumpWidget(
      const AnimatedStatusContentStory(reducedMotion: true),
    );
    await tester.pumpAndSettle();
    for (final label in ["Checking", "1 issue", "12 issues"]) {
      await tester.tap(find.text("Next status"));
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text("Next status"));
    await tester.pumpAndSettle();
    expect(find.text("12 issues"), findsNothing);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });
}
