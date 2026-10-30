import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final (name, selector) in [
    (
      "choices",
      SelectorPopup<String>(
        asyncValue: const AsyncLoading(),
        name: "books",
        buttonBuilder: (_) => const Text("Choose book"),
        contentBuilder: (items, selected, onSelect) => const SizedBox(),
      ),
    ),
    (
      "selection",
      SelectorPopupWithSelection<String>(
        itemsAsync: const AsyncData(["Book"]),
        selectedAsync: const AsyncLoading(),
        name: "books",
        buttonBuilder: (_) => const Text("Choose book"),
        contentBuilder: (items, selected, onSelect) => const SizedBox(),
      ),
    ),
  ]) {
    testWidgets("a selector announces what loads while its $name load", (
      tester,
    ) async {
      // Reduced motion keeps the shimmer still, so the panel settles.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(selector),
      );

      expect(panel.shows("Loading books"), isTrue);
      expect(panel.shows("Choose book"), isFalse);
    });
  }
}
