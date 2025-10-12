import "dart:math";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/widgets/app/components/sidebar.dart";

import "../../../../test_utils.dart";

Widget _focusableChild(FocusNode node) =>
    Focus(focusNode: node, child: const SizedBox.shrink());

void main() {

  group("Sidebar shortcuts", () {
    testWidgets("comma shrinks and period expands (small step)", (
      tester,
    ) async {
      final focusNode = FocusNode(debugLabel: "sidebar_focus");

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 1200,
            height: 800,
            child: Sidebar(child: _focusableChild(focusNode)),
          ),
        ),
        settle: true,
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      final container = tester.container();
      final initial = container.read(sidebarSizeProvider);
      expect(initial, equals(kSidebarDefaultSize));

      final sidebarWidth = MediaQuery.of(
        tester.element(find.byType(Sidebar)),
      ).size.width;
      final sidebarMax =
          (sidebarWidth * kSidebarMaxFactor).floorToDouble() - 1.0;
      final sidebarMin = min(kSidebarMinSize, sidebarMax);
      final effectiveBefore = initial.clamp(max(0.0, sidebarMin), sidebarMax);

      await tester.sendKeyEvent(LogicalKeyboardKey.comma);
      await tester.pump();

      final afterShrink = container.read(sidebarSizeProvider);
      expect(afterShrink, equals(effectiveBefore - kSidebarResizeSmallStep));

      await tester.sendKeyEvent(LogicalKeyboardKey.period);
      await tester.pump();

      final afterExpand = container.read(sidebarSizeProvider);
      expect(afterExpand, equals(effectiveBefore));
    });

    testWidgets("shift+comma shrinks and shift+period expands (large step)", (
      tester,
    ) async {
      final focusNode = FocusNode(debugLabel: "sidebar_focus");

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 1200,
            height: 800,
            child: Sidebar(child: _focusableChild(focusNode)),
          ),
        ),
        settle: true,
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      final container = tester.container();
      final initial = container.read(sidebarSizeProvider);

      final sidebarWidth = MediaQuery.of(
        tester.element(find.byType(Sidebar)),
      ).size.width;
      final sidebarMax =
          (sidebarWidth * kSidebarMaxFactor).floorToDouble() - 1.0;
      final sidebarMin = min(kSidebarMinSize, sidebarMax);
      final effectiveBefore = initial.clamp(max(0.0, sidebarMin), sidebarMax);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.comma);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.comma);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      final afterShrink = container.read(sidebarSizeProvider);
      expect(afterShrink, equals(effectiveBefore - kSidebarResizeLargeStep));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.period);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.period);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      final afterExpand = container.read(sidebarSizeProvider);
      expect(afterExpand, equals(effectiveBefore));
    });
  });
}
