import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/ui/components/surface.stories.dart";

void main() {
  testWidgets("animated surface story keeps icon and text synchronized", (
    tester,
  ) async {
    await tester.pumpWidget(const SurfaceTransitionStory());
    await tester.pumpAndSettle();
    await tester.tap(find.text("Toggle surface"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final text = tester.element(find.text("Adventure"));
    final appearance = Surface.appearanceOf(text);
    expect(
      tester.widget<Text>(find.text("Adventure")).style?.color,
      appearance.foreground,
    );
    expect(
      IconTheme.of(tester.element(find.byIcon(Icons.label))).color,
      appearance.foreground,
    );
    expect(appearance.foreground, appearance.color.on(text));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "interaction story supports keyboard selection and visible focus",
    (tester) async {
      await tester.pumpWidget(const SurfaceInteractionStory());
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final appearance = tester.element(find.text("Adventure"));
      expect(PresentationInteractionScope.of(appearance).focused, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text("Selected"), findsOneWidget);
      expect(PresentationInteractionScope.of(appearance).selected, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
