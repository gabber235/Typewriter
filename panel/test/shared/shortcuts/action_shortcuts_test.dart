import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test("primary action uses adaptive Enter keys without repeats", () {
    final shortcuts = shortcutsFor(PrimaryActionIntent);

    expect(shortcuts, hasLength(2));
    expect(
      shortcuts,
      everyElement(
        isA<SingleActivator>()
            .having((value) => value.control || value.meta, "modifier", isTrue)
            .having((value) => value.includeRepeats, "includeRepeats", isFalse),
      ),
    );
    expect(
      shortcuts.map((value) => (value as SingleActivator).trigger),
      containsAll([LogicalKeyboardKey.enter, LogicalKeyboardKey.numpadEnter]),
    );
  });

  testWidgets("a focused action set shows its action and runs it on its key", (
    tester,
  ) async {
    var invocations = 0;
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ActionSurface([numberedAction(0, onInvoke: (_) => invocations++)]),
      ),
    );

    expect(panel.shows("Action 0"), isTrue);
    await panel.press(LogicalKeyboardKey.keyA);

    expect(invocations, 1);
  });

  testWidgets("a removed action leaves the row and its key does nothing", (
    tester,
  ) async {
    final invocations = <int>[];
    final include = ValueNotifier(true);
    addTearDown(include.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: include,
          builder: (context, include, _) => ActionSurface([
            for (var i = 0; i < 2; i++)
              if (include || i.isEven)
                numberedAction(i, onInvoke: (_) => invocations.add(i)),
          ]),
        ),
      ),
    );
    expect(panel.shows("Action 0"), isTrue);
    expect(panel.shows("Action 1"), isTrue);

    include.value = false;
    await panel.settle();

    expect(panel.shows("Action 0"), isTrue);
    expect(panel.shows("Action 1"), isFalse);
    await panel.press(LogicalKeyboardKey.keyB);
    await panel.press(LogicalKeyboardKey.keyA);
    expect(invocations, [0]);
  });

  testWidgets("a running action cannot start again until it finished", (
    tester,
  ) async {
    var invocations = 0;
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ActionSurface([
          numberedAction(
            2,
            onInvoke: (_) async {
              invocations++;
              await Future<void>.delayed(const Duration(milliseconds: 300));
            },
          ),
        ]),
      ),
    );
    final action = find.bySemanticsLabel(RegExp("^Action 2"));

    await tester.tap(action);
    await tester.pump();
    expect(tester.getSemantics(action).isTappable, isFalse);
    await tester.tap(action, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 150));
    expect(invocations, 1);

    await tester.pump(const Duration(milliseconds: 200));
    await panel.settle();
    expect(tester.getSemantics(action).isTappable, isTrue);
    await tester.tap(action);
    await tester.pump(const Duration(milliseconds: 400));
    expect(invocations, 2);
  });

  testWidgets("an action without a callback cannot be activated", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(ActionSurface([numberedAction(3)])),
    );

    expect(panel.shows("Action 3"), isTrue);
    expect(tester.getSemantics(find.text("Action 3")).isTappable, isFalse);
  });

  testWidgets("retains highest priority actions when width constrained", (
    tester,
  ) async {
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ActionSurface(List.generate(5, numberedAction), rowWidth: 500),
      ),
    );

    expect(find.text("Action 0").hitTestable(), findsNothing);
    expect(find.text("Action 4").hitTestable(), findsOneWidget);
  });
}
