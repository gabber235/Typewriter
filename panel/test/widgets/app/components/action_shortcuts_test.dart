import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/widgets/generic/components/action_shortcuts.dart";

import "../../../test_utils.dart";

ActionShortcut testAction(
  int i, {
  FutureOr<void> Function(WidgetRef ref)? onInvoke,
}) {
  return ActionShortcut(
    id: "action_$i",
    label: "Action $i",
    description: "Action $i description",
    activators: [const SingleActivator(LogicalKeyboardKey.keyA)],
    priority: i,
    onInvoke: onInvoke,
  );
}

void main() {
  group("ActionShortcuts Registration", () {
    testWidgets("registers an action shortcut", (tester) async {
      final shortcut = testAction(0);

      await tester.pumpTestApp(
        child: Column(
          children: [
            ActionSet(shortcuts: [shortcut]),
            const ActionRow(),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Action 0"), findsOneWidget);

      final container = tester.container();
      final state = container.read(actionShortcutsProvider);
      expect(state.containsKey("action_0"), isTrue);
    });
  });

  group("ActionShortcuts Cleanup", () {
    testWidgets("sweeps unmounted actions", (tester) async {
      Widget withAction({required bool include}) {
        return Column(
          children: [
            ActionSet(
              shortcuts: [
                for (var i = 0; i < 2; i++)
                  if (include || i.isEven) testAction(i),
              ],
            ),
            const ActionRow(),
          ],
        );
      }

      await tester.pumpTestApp(
        child: withAction(include: true),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        expect(find.text("Action $i"), findsOneWidget);
      }

      await tester.pumpTestApp(
        child: withAction(include: false),
      );
      await tester.pump();
      await tester.pump();

      for (var i = 0; i < 2; i++) {
        if (i.isEven) {
          expect(find.text("Action $i"), findsOne);
        } else {
          expect(find.text("Action $i"), findsNothing);
        }
      }
      final container = tester.container();
      final state = container.read(actionShortcutsProvider);
      for (var i = 0; i < 2; i++) {
        if (i.isEven) {
          expect(state.containsKey("action_$i"), isTrue);
        } else {
          expect(state.containsKey("action_$i"), isFalse);
        }
      }
    });
  });

  group("ActionShortcuts Async Execution", () {
    testWidgets("shows loading spinner while async action runs",
        (tester) async {
      final shortcut = testAction(
        2,
        onInvoke: (ref) async {
          await Future.delayed(const Duration(milliseconds: 300));
        },
      );

      await tester.pumpTestApp(
        child: Column(
          children: [
            ActionSet(shortcuts: [shortcut]),
            const ActionRow(),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Action 2"), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text("Action 2"));
      await tester.pump(); // start async -> spinner visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(150.ms);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(200.ms);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets("non-invokable action not clickable and no spinner",
        (tester) async {
      final shortcut = testAction(3);

      await tester.pumpTestApp(
        child: Column(
          children: [
            ActionSet(shortcuts: [shortcut]),
            const ActionRow(),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Action 3"), findsOneWidget);
      await tester.tap(find.text("Action 3"));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group("ActionShortcuts Overflow", () {
    testWidgets("retains highest priority actions when width constrained",
        (tester) async {
      final shortcuts = List.generate(
        5,
        testAction,
      );

      await tester.pumpTestApp(
        child: Column(
          children: [
            ActionSet(shortcuts: shortcuts),
            const SizedBox(height: 8),
            const SizedBox(
              width: 500, // Force overflow
              child: ActionRow(),
            ),
          ],
        ),
      );

      await tester.pump(); // first build (all offstage for measurement)
      await tester.pump(); // measurement pass -> binary search applied

      expect(find.text("Action 0"), findsNothing);
      expect(find.text("Action 4"), findsOneWidget);
    });
  });
}
