import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "selection_test_support.dart";

void main() {
  group("hasSelection and isSelected providers", () {
    test("hasSelection returns false when empty", () {
      final container = ProviderContainer.test();

      expect(container.read(hasSelectionProvider), isFalse);
    });

    test("hasSelection returns true when items selected", () {
      final container = ProviderContainer.test();
      final idA = MockSelectableIdentifier("A");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      expect(container.read(hasSelectionProvider), isTrue);
    });

    test("isSelected returns true for selected item", () {
      final container = ProviderContainer.test();
      final idA = MockSelectableIdentifier("A");
      final idB = MockSelectableIdentifier("B");

      container.read(selectionProvider.notifier).selectAll([idA, idB]);

      expect(container.read(isSelectedProvider(idA)), isTrue);
      expect(container.read(isSelectedProvider(idB)), isTrue);
    });

    test("isSelected returns false for non-selected item", () {
      final container = ProviderContainer.test();
      final idA = MockSelectableIdentifier("A");
      final idC = MockSelectableIdentifier("C");

      container
          .read(selectionProvider.notifier)
          .select(idA, isMultiSelect: false);

      expect(container.read(isSelectedProvider(idC)), isFalse);
    });
  });

  group("Selected provider", () {
    test("returns empty list when no selection", () {
      final container = ProviderContainer.test();

      final selected = container.read(selectedProvider);

      expect(selected.hasValue, isTrue);
      expect(selected.requireValue, isEmpty);
    });

    test("returns resolved selectables for valid identifiers", () {
      final container = ProviderContainer.test();
      final idA = MockSelectableIdentifier(
        "A",
        RecordValue({"field": const StringValue("valueA")}),
      );
      final idB = MockSelectableIdentifier(
        "B",
        RecordValue({"field": const StringValue("valueB")}),
      );

      container.read(selectionProvider.notifier).selectAll([idA, idB]);

      final selected = container.read(selectedProvider);

      expect(selected.hasValue, isTrue);
      expect(selected.requireValue.length, 2);
      expect(selected.requireValue[0].name, "Mock A");
      expect(selected.requireValue[1].name, "Mock B");
    });

    test("returns loading state when identifier returns loading", () {
      final container = ProviderContainer.test();
      final idA = MockSelectableIdentifier("A");
      final loadingId = LoadingSelectableIdentifier("loading");

      container.read(selectionProvider.notifier).selectAll([idA, loadingId]);

      final selected = container.read(selectedProvider);

      expect(selected.isLoading, isTrue);
    });

    test("typed update reaches every selectable", () {
      final container = ProviderContainer.test();
      final idA = MockSelectableIdentifier(
        "A",
        RecordValue({"field": const StringValue("oldA")}),
      );
      final idB = MockSelectableIdentifier(
        "B",
        RecordValue({"field": const StringValue("oldB")}),
      );

      container.read(selectionProvider.notifier).selectAll([idA, idB]);

      final selectables = container.read(selectedProvider).requireValue;
      final mockA = selectables[0] as MockSelectable;
      final mockB = selectables[1] as MockSelectable;

      container
          .read(selectionEditorSourceProvider)
          .update(DataPath.root.field("field"), const StringValue("newValue"));

      expect(mockA.lastSetPath, DataPath.root.field("field"));
      expect(mockA.lastSetValue, const StringValue("newValue"));
      expect(mockB.lastSetPath, DataPath.root.field("field"));
      expect(mockB.lastSetValue, const StringValue("newValue"));
    });
  });
}
