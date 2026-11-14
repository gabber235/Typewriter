import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final codes = [joinCode("first"), joinCode("second")];
  final traits = [
    signedIn(ada, organization: acme),
    membershipService(joinCodes: codes),
  ];
  const revokeAll = "Revoke 2 join codes? Nobody new can join with them.";

  testWidgets("holding Revoke all for the full hold revokes both codes", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      traits,
      at: membersPage(const JoinCodesRoute()),
    );
    await panel.pressShifted(LogicalKeyboardKey.space);

    await panel.holdButton(revokeAll);

    await panel.eventually(
      () => expect(panel.shows("No active join codes"), isTrue),
    );
  });

  for (final (way, share, kind, drift) in [
    ("releasing early", 0.5, PointerDeviceKind.mouse, null),
    (
      "dragging the pointer off",
      1.0,
      PointerDeviceKind.mouse,
      const Offset(0, 400),
    ),
    ("a touch that scrolls", 1.0, PointerDeviceKind.touch, const Offset(0, 60)),
  ]) {
    testWidgets("$way revokes nothing", (tester) async {
      final panel = await tester.pumpPanel(
        traits,
        at: membersPage(const JoinCodesRoute()),
      );
      await panel.pressShifted(LogicalKeyboardKey.space);

      await panel.holdButton(revokeAll, share: share, kind: kind, drift: drift);

      expect(panel.shows("No active join codes"), isFalse);
    });
  }

  testWidgets("Enter held on a focused Revoke all revokes both codes once "
      "the hold fills", (tester) async {
    final panel = await tester.pumpPanel(
      traits,
      at: membersPage(const JoinCodesRoute()),
    );
    await panel.pressShifted(LogicalKeyboardKey.space);
    await panel.tabTo(revokeAll, limit: 30);

    await panel.holdKey(LogicalKeyboardKey.enter, share: 0.4);
    expect(panel.shows("No active join codes"), isFalse);

    await panel.holdKey(LogicalKeyboardKey.enter);
    await panel.eventually(
      () => expect(panel.shows("No active join codes"), isTrue),
    );
  });

  testWidgets("a screen reader hears what Revoke all does and its long press "
      "revokes both codes", (tester) async {
    final panel = await tester.pumpPanel(
      traits,
      at: membersPage(const JoinCodesRoute()),
    );
    await panel.pressShifted(LogicalKeyboardKey.space);

    expect(panel.holdHint(revokeAll), "Long press to confirm");
    await panel.longPressWithScreenReader(revokeAll);

    await panel.eventually(
      () => expect(panel.shows("No active join codes"), isTrue),
    );
  });

  testWidgets("Escape while Enter holds a focused hold button cancels the "
      "hold, though Enter stays down past its time", (tester) async {
    var removed = 0;
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        CommandButton(
          command: removeHoldCommand(onEach: () => removed++),
          label: "Remove",
        ),
      ),
    );
    await panel.tabTo("Remove it? It does not come back.");

    await panel.keyDown(LogicalKeyboardKey.enter);
    await panel.holdFor(0.4);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await panel.holdFor(1);
    await panel.keyUp(LogicalKeyboardKey.enter);

    expect(removed, 0);
    expect(panel.shows("Removed"), isFalse);
  });

  testWidgets("a completed hold types its done word, and the label returns "
      "once holdDoneShow passed", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        CommandButton(command: removeHoldCommand(), label: "Remove"),
      ),
    );

    await panel.holdButton("Remove");

    expect(panel.shows("Removed"), isTrue);
    final shown = tester.element(find.byType(CommandButton)).timing;
    await tester.pump(shown.holdDoneShow);
    await panel.settle();
    expect(panel.shows("Removed"), isFalse);
    expect(panel.shows("Remove"), isTrue);
  });

  testWidgets("a held button sinks and shrinks as the hold fills, trembles "
      "late in it, and springs back once it completes", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        CommandButton(
          command: removeHoldCommand(),
          face: ButtonFace.outlined,
          label: "Remove",
        ),
      ),
    );
    final face = find.byType(Button);
    final rest = tester.getRect(face);

    final gesture = await panel.pressButton("Remove");
    await panel.holdFor(0.5);
    final half = tester.getRect(face);
    // A quarter into the tremble window, where its swing is widest.
    await panel.holdFor(0.385);
    final trembling = tester.getRect(face);
    await panel.holdFor(1);
    await gesture.up();
    await panel.settle();

    expect(half.center.dy, greaterThan(rest.center.dy + 1), reason: "sinks");
    expect(half.width, lessThan(rest.width * 0.98), reason: "shrinks");
    expect(
      (trembling.center.dx - rest.center.dx).abs(),
      greaterThan(1),
      reason: "trembles sideways",
    );
    expect(tester.getRect(face), rest, reason: "springs back");
  });

  for (final (face, black) in [
    (ButtonFace.filled, true),
    (ButtonFace.outlined, false),
  ]) {
    testWidgets("a held ${face.name} button fills "
        "${black ? "black" : "red"} and shows no press splash, by pointer "
        "and by key", (tester) async {
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          CommandButton(
            command: removeHoldCommand(),
            face: face,
            label: "Remove",
          ),
        ),
      );
      final button = find.byType(CommandButton);
      final shown = tester.element(button);
      final fill = black ? shown.holdFillOnFilledColor : shown.holdFillColor;
      final other = black ? shown.holdFillColor : shown.holdFillOnFilledColor;

      final gesture = await panel.pressButton("Remove");
      await panel.holdFor(0.5);

      expect(tester.renderObject(button), paints..rect(color: fill));
      expect(tester.renderObject(button), isNot(paints..rect(color: other)));
      expect(tester.inkOf(button), isNull, reason: "pointer");
      await gesture.up();
      await panel.settle();

      await panel.tabTo("Remove it? It does not come back.");
      await panel.keyDown(LogicalKeyboardKey.enter);
      await panel.holdFor(0.5);
      expect(tester.inkOf(button), isNull, reason: "key");
      await panel.keyUp(LogicalKeyboardKey.enter);
    });
  }

  testWidgets("a press command splashes while held, runs once when let go "
      "and shows its key cap", (tester) async {
    var runs = 0;
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        CommandButton(
          command: ActionShortcut(
            id: "run",
            label: "Run",
            description: "Run it",
            activators: const [SingleActivator(LogicalKeyboardKey.keyR)],
            priority: 1,
            run: ActionRun.press((_) => runs++),
          ),
          label: "Run",
        ),
      ),
    );

    final gesture = await panel.pressButton("Run");
    await tester.pump(tester.settleTimeOf(MotionToken.splash));
    expect(tester.inkOf(find.byType(CommandButton)), isNotNull);
    expect(runs, 0);
    await gesture.up();
    await panel.settle();

    expect(runs, 1);
    expect(panel.shows("R"), isTrue);
  });

  testWidgets("a command with no run is shown unavailable", (tester) async {
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        const CommandButton(
          command: ActionShortcut(
            id: "run",
            label: "Run",
            description: "Run it",
            activators: [SingleActivator(LogicalKeyboardKey.keyR)],
            priority: 1,
          ),
          label: "Run",
        ),
      ),
    );

    expect(semanticsButton("Run").isEnabled, isFalse);
  });

  for (final face in [ButtonFace.filled, ButtonFace.outlined]) {
    for (final available in [true, false]) {
      testWidgets(
        "${face.name} command button ${available ? "shows" : "omits"} the "
        "key cap when its key is ${available ? "" : "un"}available",
        (tester) async {
          final panel = await tester.pumpPanel(
            const [],
            at: PanelLocation.component(
              CommandButton(
                command: ShortcutTestOperation(
                  activators: [
                    if (available)
                      const SingleActivator(LogicalKeyboardKey.keyR),
                  ],
                ).shortcut,
                face: face,
                icon: const Icon(Icons.bolt),
                label: "Run",
              ),
            ),
          );

          expect(panel.shows("Run"), isTrue);
          expect(panel.shows("R"), available);
        },
      );
    }
  }

  testWidgets("narrow command button keeps its key cap without overflowing", (
    tester,
  ) async {
    const label = "Run this operation with a long label";
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox(
          width: 150,
          child: CommandButton(
            command: const ShortcutTestOperation(
              activators: [SingleActivator(LogicalKeyboardKey.keyR)],
            ).shortcut,
            face: ButtonFace.filled,
            icon: const Icon(Icons.bolt),
            label: label,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(panel.shows("R"), isTrue);
    expect(find.bySemanticsLabel(RegExp("^$label")), findsOneWidget);
  });
}
