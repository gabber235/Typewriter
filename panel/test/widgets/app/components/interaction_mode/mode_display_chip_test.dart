import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/widgets/app/components/interaction_mode/mode_display_chip.dart";

import "../../../../test_utils.dart";

void main() {
  group("ModeDisplayChip", () {
    testWidgets("converts label to uppercase", (tester) async {
      const testCases = [
        "normal",
        "Insert",
        "MOVE",
        "rEsIzE",
        "custom mode",
      ];

      for (final label in testCases) {
        await tester.pumpTestApp(
          child: Center(
            child: ModeDisplayChip(
              label: label,
              color: Colors.blue,
            ),
          ),
        );

        expect(find.text(label.toUpperCase()), findsOneWidget);
        if (label != label.toUpperCase()) {
          expect(find.text(label), findsNothing);
        }
      }
    });

    testWidgets("handles empty label", (tester) async {
      await tester.pumpTestApp(
        child: const Center(
          child: ModeDisplayChip(
            label: "",
            color: Colors.blue,
          ),
        ),
      );

      expect(find.text(""), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets("maintains consistent size with different labels",
        (tester) async {
      const shortLabel = "A";
      const longLabel = "Very Long Mode Name";

      await tester.pumpTestApp(
        child: const Center(
          child: ModeDisplayChip(
            label: shortLabel,
            color: Colors.blue,
          ),
        ),
      );

      final shortSize = tester.getSize(find.byType(ModeDisplayChip));

      await tester.pumpTestApp(
        child: const Center(
          child: ModeDisplayChip(
            label: longLabel,
            color: Colors.blue,
          ),
        ),
      );

      final longSize = tester.getSize(find.byType(ModeDisplayChip));

      expect(
        shortSize.height,
        longSize.height,
        reason: "Height should be consistent due to fixed padding",
      );

      expect(
        shortSize.width,
        lessThan(longSize.width),
        reason: "Width should be different due to text content",
      );
    });
  });
}
