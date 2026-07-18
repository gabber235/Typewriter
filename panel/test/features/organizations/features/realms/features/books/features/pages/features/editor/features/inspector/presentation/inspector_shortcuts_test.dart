import "dart:math";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/selection.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/inspector.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/operations.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../../../../../../../support/test_utils.dart";

void main() {
  group("Inspector shortcuts", () {
    testWidgets("period shrinks and comma expands (small step)", (
      tester,
    ) async {
      final testSelectable = TestSelectableIdentifier(id: "test-item");

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 1600,
            height: 800,
            child: DesktopInspector(child: const SizedBox.shrink()),
          ),
        ),
        overrides: [
          selectionProvider.overrideWithValue([testSelectable]),
          operationsProvider.overrideWithValue([]),
        ],
        settle: true,
      );

      final focusScope = tester.widget<FocusScope>(
        find.descendant(
          of: find.byType(DesktopInspector),
          matching: find.byType(FocusScope),
        ),
      );
      focusScope.focusNode?.requestFocus();
      await tester.pumpAndSettle();

      final container = tester.container();
      final initial = container.read(inspectorSizeProvider);
      expect(initial, equals(kInspectorDefaultSize));

      final inspectorWidth = MediaQuery.of(
        tester.element(find.byType(DesktopInspector)),
      ).size.width;
      final inspectorMax =
          (inspectorWidth * kInspectorMaxFactor).floorToDouble() - 1.0;
      final inspectorMin = min(kInspectorMinSize, inspectorMax);
      final effectiveBefore = initial.clamp(
        max(0.0, inspectorMin),
        inspectorMax,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.period);
      await tester.pump();

      final afterShrink = container.read(inspectorSizeProvider);
      expect(afterShrink, equals(effectiveBefore - kInspectorResizeSmallStep));

      await tester.sendKeyEvent(LogicalKeyboardKey.comma);
      await tester.pump();

      final afterExpand = container.read(inspectorSizeProvider);
      expect(afterExpand, equals(effectiveBefore));
    });

    testWidgets("shift+period shrinks and shift+comma expands (large step)", (
      tester,
    ) async {
      final testSelectable = TestSelectableIdentifier(id: "test-item");

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 1600,
            height: 800,
            child: DesktopInspector(child: const SizedBox.shrink()),
          ),
        ),
        overrides: [
          selectionProvider.overrideWithValue([testSelectable]),
          operationsProvider.overrideWithValue([]),
        ],
        settle: true,
      );

      final focusScope = tester.widget<FocusScope>(
        find.descendant(
          of: find.byType(DesktopInspector),
          matching: find.byType(FocusScope),
        ),
      );
      focusScope.focusNode?.requestFocus();
      await tester.pumpAndSettle();

      final container = tester.container();
      final initial = container.read(inspectorSizeProvider);

      final inspectorWidth = MediaQuery.of(
        tester.element(find.byType(DesktopInspector)),
      ).size.width;
      final inspectorMax =
          (inspectorWidth * kInspectorMaxFactor).floorToDouble() - 1.0;
      final inspectorMin = min(kInspectorMinSize, inspectorMax);
      final effectiveBefore = initial.clamp(
        max(0.0, inspectorMin),
        inspectorMax,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.period);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.period);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      final afterShrink = container.read(inspectorSizeProvider);
      expect(afterShrink, equals(effectiveBefore - kInspectorResizeLargeStep));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.comma);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.comma);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      final afterExpand = container.read(inspectorSizeProvider);
      expect(afterExpand, equals(effectiveBefore));
    });
  });
}
