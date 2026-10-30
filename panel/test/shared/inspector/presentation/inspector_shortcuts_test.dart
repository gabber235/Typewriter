import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const title = "A book with an unusually long title that needs fitting";
  final item = TestSelectableIdentifier(id: "test-item");

  group("the heading of the selected item stays inside the inspector", () {
    final long = TestSelectableIdentifier(id: title);

    testWidgets("on a phone", (tester) async {
      final panel = await tester.pumpPanel(
        [window(const Size(400, 800))],
        at: const PanelLocation.component(
          SizedBox.expand(child: InspectorScaffold(child: SizedBox.expand())),
        ),
      );
      panel.container.read(selectionProvider.notifier).selectAll([long]);
      await panel.settle();
      await panel.inspector.pull(const Offset(0, -500));

      panel.inspector.expectHeadingInside(title.formatted);
    });

    testWidgets("in the narrowest desktop inspector", (tester) async {
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          SizedBox(
            width: 1600,
            height: 800,
            child: InspectorScaffold(child: const SizedBox.expand()),
          ),
        ),
      );
      await panel.selectAll([long]);
      await panel.inspector.focusHeading(long.id.formatted);
      for (var step = 0; step < 10; step++) {
        await panel.pressShifted(LogicalKeyboardKey.period);
      }

      expect(panel.inspector.rect.width, lessThan(kInspectorDefaultSize));
      panel.inspector.expectHeadingInside(title.formatted);
    });
  });

  testWidgets("the heading counts every selected item, resolved or not", (
    tester,
  ) async {
    final pending = LoadingSelectableIdentifier("pending");
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox(
          width: 1600,
          height: 800,
          child: InspectorScaffold(child: const SizedBox.expand()),
        ),
      ),
    );
    await panel.selectAll([item]);
    final selection = panel.container.read(selectionProvider.notifier);
    expect(panel.inspector.heading(item.id.formatted), findsOneWidget);

    selection.selectAll([item, pending]);
    await panel.settle();
    expect(panel.inspector.heading(item.id.formatted), findsNothing);

    selection.selectAll([item]);
    await panel.settle();
    expect(panel.inspector.heading(item.id.formatted), findsOneWidget);
  });

  testWidgets("changing the page beside it keeps the inspector width", (
    tester,
  ) async {
    final page = ValueNotifier("First page");
    addTearDown(page.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox(
          width: 1600,
          height: 800,
          child: InspectorScaffold(
            child: ValueListenableBuilder(
              valueListenable: page,
              builder: (context, name, _) => Text(name),
            ),
          ),
        ),
      ),
    );
    await panel.selectAll([item]);
    await panel.inspector.focusHeading(item.id.formatted);
    await panel.press(LogicalKeyboardKey.period);
    final resized = panel.inspector.rect.width;

    page.value = "Second page";
    await panel.settle();

    expect(panel.shows("Second page"), isTrue);
    expect(panel.inspector.rect.width, resized);
  });

  testWidgets("period shrinks the inspector and comma restores it; with "
      "shift held, both take a larger step", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox(
          width: 1600,
          height: 800,
          child: InspectorScaffold(child: const SizedBox.expand()),
        ),
      ),
    );
    await panel.selectAll([item]);
    await panel.inspector.focusHeading(item.id.formatted);
    final original = panel.inspector.rect.width;

    Future<double> shrinkAndRestore(
      Future<void> Function(LogicalKeyboardKey key) press,
    ) async {
      await press(LogicalKeyboardKey.period);
      final shrunk = panel.inspector.rect.width;
      await press(LogicalKeyboardKey.comma);
      expect(panel.inspector.rect.width, original);
      return original - shrunk;
    }

    final small = await shrinkAndRestore(panel.press);
    final large = await shrinkAndRestore(panel.pressShifted);

    expect(small, greaterThan(0));
    expect(large, greaterThan(small));
  });
}
