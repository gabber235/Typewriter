import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";
import "selection_test_support.dart";

void main() {
  group("Selection state machine", () {
    test("single select on empty selection adds item", () {
      final container = ProviderContainer.test();

      final idA = MockSelectableIdentifier("A");
      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      expect(container.read(selectionProvider), [idA]);
    });

    test("single select replaces existing selection", () {
      final container = ProviderContainer.test();

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);
      container
          .read(selectionProvider.notifier)
          .select(idB, isMultiSelect: false);

      expect(container.read(selectionProvider), [idB]);
    });

    test("single select on already selected sole item clears selection", () {
      final container = ProviderContainer.test();

      final idA = MockSelectableIdentifier("A");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);
      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      expect(container.read(selectionProvider), isEmpty);
    });

    test(
      "single select on already selected item with multiple keeps only that item",
      () {
        final container = ProviderContainer.test();

        final idA = MockSelectableIdentifier("A");
        final idB = MockSelectableIdentifier("B");

        container.read(selectionProvider.notifier).selectAll([idA, idB]);
        container
            .read(selectionProvider.notifier)
            .select(idA, isMultiSelect: false);

        expect(container.read(selectionProvider), [idA]);
      },
    );

    test("multi-select adds to existing selection", () {
      final container = ProviderContainer.test();

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);
      container
          .read(selectionProvider.notifier)
          .select(idB, isMultiSelect: true);

      expect(container.read(selectionProvider), [idA, idB]);
    });

    test("multi-select on already selected item removes it", () {
      final container = ProviderContainer.test();

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container.read(selectionProvider.notifier).selectAll([idA, idB]);
      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: true);

      expect(container.read(selectionProvider), [idB]);
    });

    test("selectAll replaces selection by default", () {
      final container = ProviderContainer.test();

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");
      final idC = MockSelectableIdentifier("C");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);
      container.read(selectionProvider.notifier).selectAll([idB, idC]);

      expect(container.read(selectionProvider), [idB, idC]);
    });

    test("selectAll appends when replaceCurrentSelection is false", () {
      final container = ProviderContainer.test();

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);
      container.read(selectionProvider.notifier).selectAll([
        idB,
      ], replaceCurrentSelection: false);

      expect(container.read(selectionProvider), [idA, idB]);
    });

    test("unselect removes specific item", () {
      final container = ProviderContainer.test();

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container.read(selectionProvider.notifier).selectAll([idA, idB]);
      container.read(selectionProvider.notifier).unselect(idA);

      expect(container.read(selectionProvider), [idB]);
    });

    test("unselect on non-existent item is no-op", () {
      final container = ProviderContainer.test();

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);
      container.read(selectionProvider.notifier).unselect(idB);

      expect(container.read(selectionProvider), [idA]);
    });

    test("unselectAll removes multiple items", () {
      final container = ProviderContainer.test();

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");
      final idC = MockSelectableIdentifier("C");

      container.read(selectionProvider.notifier).selectAll([idA, idB, idC]);
      container.read(selectionProvider.notifier).unselectAll([idA, idC]);

      expect(container.read(selectionProvider), [idB]);
    });

    test("clear empties selection", () {
      final container = ProviderContainer.test();

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container.read(selectionProvider.notifier).selectAll([idA, idB]);
      container.read(selectionProvider.notifier).clear();

      expect(container.read(selectionProvider), isEmpty);
    });
  });

  group("Selection with HardwareKeyboard", () {
    testWidgets("select defaults to single-select when shift not pressed", (
      tester,
    ) async {
      late ProviderContainer container;

      await tester.pumpTestApp(
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return const SizedBox();
          },
        ),
      );

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container.read(selectionProvider.notifier).select(idA);
      container.read(selectionProvider.notifier).select(idB);

      expect(container.read(selectionProvider), [idB]);
    });

    testWidgets("select defaults to multi-select when shift is pressed", (
      tester,
    ) async {
      late ProviderContainer container;

      await tester.pumpTestApp(
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return const SizedBox();
          },
        ),
      );

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container.read(selectionProvider.notifier).select(idA);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      container.read(selectionProvider.notifier).select(idB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      expect(container.read(selectionProvider), [idA, idB]);
    });

    testWidgets("shift released returns to single-select behavior", (
      tester,
    ) async {
      late ProviderContainer container;

      await tester.pumpTestApp(
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return const SizedBox();
          },
        ),
      );

      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");
      final idC = MockSelectableIdentifier("C");

      container.read(selectionProvider.notifier).select(idA);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      container.read(selectionProvider.notifier).select(idB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      container.read(selectionProvider.notifier).select(idC);

      expect(container.read(selectionProvider), [idC]);
    });
  });
}
