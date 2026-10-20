import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/portable_paint.stories.dart";

void main() {
  testWidgets("paint primitives follow every interaction state", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final interaction in const [
      PresentationInteraction(),
      PresentationInteraction(hovered: true),
      PresentationInteraction(selected: true, focused: true),
    ]) {
      await tester.pumpWidget(portablePaintStory(interaction: interaction));
      await tester.pumpAndSettle();
      expect(find.text("Main story"), findsOneWidget);
      expect(find.text("Hover lifts"), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets("book volumes select from the keyboard", (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(compiledBookItemGridStory());
    await tester.pumpAndSettle();
    expect(find.text("Main story"), findsOneWidget);
    expect(find.text("Book"), findsOneWidget);
    List<double?> raisedSpines() => [
      for (final spine in tester.widgetList<AnimatedPositionedDirectional>(
        find.byType(AnimatedPositionedDirectional),
      ))
        if (spine.width == 30 && spine.top == 15) spine.top,
    ];
    expect(raisedSpines(), isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(raisedSpines(), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
