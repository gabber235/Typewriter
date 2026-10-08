import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/ui/components/anchored_popup.stories.dart";

void main() {
  testWidgets("popup story supports hovering and closing nested tooltips", (
    tester,
  ) async {
    await tester.pumpWidget(const AnchoredPopupStory());
    await tester.pumpAndSettle();
    await tester.tap(find.text("Open activity"));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byTooltip("Close")));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip("Close"));
    await tester.pumpAndSettle();
    expect(find.text("Activity"), findsNothing);
    expect(find.text("Open activity"), findsOneWidget);
    expect(tester.takeException(), isNull);
    await mouse.removePointer();
  });
}
