import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "selection_test_support.dart";

void main() {
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
  });
}
