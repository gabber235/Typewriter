import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/shell/appbar.stories.dart";
import "package:widgetbook_workspace/stories/shared/ui/components/anchored_popup.stories.dart";

void main() {
  testWidgets("app bar breadcrumbs preview and accept a selection", (
    tester,
  ) async {
    await tester.pumpWidget(const AppBarStory(width: 800));
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(700, 500));
    await mouse.moveTo(tester.getCenter(find.text("Typewriter")));
    await tester.pumpAndSettle();
    expect(find.text("Another workspace"), findsOneWidget);
    expect(find.byKey(const ValueKey("popup barrier")), findsNothing);
    await tester.tap(find.text("Another workspace"));
    await tester.pumpAndSettle();
    expect(find.text("Another workspace"), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
