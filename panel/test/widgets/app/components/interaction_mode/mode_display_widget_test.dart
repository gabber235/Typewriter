import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/interaction_mode/current_interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/mode_display.dart";
import "package:typewriter_panel/widgets/app/components/interaction_mode/mode_display.dart";

import "../../../../test_utils.dart";

class TestModeWithDisplay extends InteractionMode with ModeDisplay {
  @override
  String get name => "TestWithDisplay";

  @override
  Widget buildDisplay(BuildContext context) {
    return const Text("Test Display");
  }
}

class TestModeWithoutDisplay extends InteractionMode {
  @override
  String get name => "TestWithoutDisplay";
}

void main() {
  group("ModeDisplayWidget", () {
    testWidgets("shows display when mode implements ModeDisplay", (
      tester,
    ) async {
      await tester.pumpTestApp(child: const ModeDisplayWidget());

      tester
          .container()
          .read(currentInteractionModeProvider.notifier)
          .setMode(TestModeWithDisplay());
      await tester.pump();

      expect(
        find.text("Test Display"),
        findsOneWidget,
        reason: "Mode with ModeDisplay should show its display widget",
      );
    });

    testWidgets("hides display when mode doesn't implement ModeDisplay", (
      tester,
    ) async {
      await tester.pumpTestApp(child: const ModeDisplayWidget());

      tester
          .container()
          .read(currentInteractionModeProvider.notifier)
          .setMode(TestModeWithoutDisplay());
      await tester.pump();

      expect(
        find.text("Test Display"),
        findsNothing,
        reason: "Mode without ModeDisplay should not show any display",
      );
      expect(
        find.byType(SizedBox),
        findsOneWidget,
        reason: "Should render SizedBox.shrink when no display",
      );
    });

    testWidgets("updates display when mode changes", (tester) async {
      await tester.pumpTestApp(child: const ModeDisplayWidget());

      final notifier = tester.container().read(
        currentInteractionModeProvider.notifier,
      )..setMode(TestModeWithoutDisplay());
      await tester.pump();

      expect(
        find.text("Test Display"),
        findsNothing,
        reason: "Initially should not display anything",
      );

      notifier.setMode(TestModeWithDisplay());
      await tester.pump();

      expect(
        find.text("Test Display"),
        findsOneWidget,
        reason: "Should show display after changing to mode with ModeDisplay",
      );

      notifier.setMode(TestModeWithoutDisplay());
      await tester.pump();

      expect(
        find.text("Test Display"),
        findsNothing,
        reason:
            "Should hide display after changing to mode without ModeDisplay",
      );
    });

    testWidgets("renders SizedBox.shrink when no display", (tester) async {
      await tester.pumpTestApp(child: const ModeDisplayWidget());

      tester
          .container()
          .read(currentInteractionModeProvider.notifier)
          .setMode(TestModeWithoutDisplay());
      await tester.pump();

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(
        sizedBox.width,
        0.0,
        reason: "SizedBox.shrink should have zero width",
      );
      expect(
        sizedBox.height,
        0.0,
        reason: "SizedBox.shrink should have zero height",
      );
    });
  });
}
