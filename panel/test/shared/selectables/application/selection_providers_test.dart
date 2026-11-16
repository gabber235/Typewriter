import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

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

      container.read(selectionProvider.notifier).replace([idA, idB]);

      final selected = container.read(selectedProvider);

      expect(selected.hasValue, isTrue);
      expect(selected.requireValue.length, 2);
      expect(selected.requireValue[0].name, "A");
      expect(selected.requireValue[1].name, "B");
    });

    test("returns loading state when identifier returns loading", () {
      final container = ProviderContainer.test();
      final idA = TestSelectableIdentifier(id: "A");
      const loadingId = LoadingSelectableIdentifier("loading");

      container.read(selectionProvider.notifier).replace([idA, loadingId]);

      final selected = container.read(selectedProvider);

      expect(selected.isLoading, isTrue);
    });
  });

  group("an item that disappears", () {
    test("leaves the selection once its resource no longer holds it", () async {
      final container = ProviderContainer.test();
      final idA = TestSelectableIdentifier(id: "A");
      final idB = TestSelectableIdentifier(id: "B");
      container
        ..listen(selectionProvider, (_, _) {})
        ..listen(selectModeProvider, (_, _) {});
      container.read(selectionProvider.notifier).toggle(idA);
      container.read(selectionProvider.notifier).toggle(idB);

      container.read(testSelectablesGoneProvider.notifier).remove("B");

      expect(
        container.read(selectedProvider).requireValue.map((item) => item.id),
        [idA],
      );
      await pumpEventQueue();
      expect(container.read(selectionProvider), [idA]);
      expect(container.read(selectModeProvider), isTrue);
    });

    test("stays selected while its resource never held it, as before its "
        "data arrived", () async {
      final container = ProviderContainer.test();
      final early = TestSelectableIdentifier(id: "early");
      container.listen(selectionProvider, (_, _) {});
      container.read(testSelectablesGoneProvider.notifier).remove("early");
      container.read(selectionProvider.notifier).replace([early]);

      await pumpEventQueue();

      expect(container.read(selectionProvider), [early]);
    });

    test("stays selected while its resource is still loading", () async {
      final container = ProviderContainer.test();
      const loading = LoadingSelectableIdentifier("loading");
      container.listen(selectionProvider, (_, _) {});
      container.read(selectionProvider.notifier).replace([loading]);

      await pumpEventQueue();

      expect(container.read(selectionProvider), [loading]);
    });
  });
}
