import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

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
      final idA = TestSelectableIdentifier(id: "A");
      final idB = TestSelectableIdentifier(id: "B");

      container.read(selectionProvider.notifier).selectAll([idA, idB]);

      final selected = container.read(selectedProvider);

      expect(selected.hasValue, isTrue);
      expect(selected.requireValue.length, 2);
      expect(selected.requireValue[0].name, "A");
      expect(selected.requireValue[1].name, "B");
    });

    test("returns loading state when identifier returns loading", () {
      final container = ProviderContainer.test();
      final idA = TestSelectableIdentifier(id: "A");
      const loadingId = _LoadingSelectableIdentifier("loading");

      container.read(selectionProvider.notifier).selectAll([idA, loadingId]);

      final selected = container.read(selectedProvider);

      expect(selected.isLoading, isTrue);
    });
  });
}

final class _LoadingSelectableIdentifier extends SelectableIdentifier {
  const _LoadingSelectableIdentifier(this.id);

  @override
  final String id;

  @override
  AsyncValue<Selectable> create(Ref ref) => const AsyncLoading();
}
