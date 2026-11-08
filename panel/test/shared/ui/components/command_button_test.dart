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

  testWidgets("a press command runs once on tap and shows its key cap", (
    tester,
  ) async {
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

    await panel.tapOn(find.text("Run"));

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
