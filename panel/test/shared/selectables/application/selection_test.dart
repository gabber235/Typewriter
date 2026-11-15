import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// The anchor rules of a range that the widget tests in
/// `presentation/selection_model_test.dart` cannot reach on a surface.
void main() {
  final a = TestSelectableIdentifier(id: "A");
  final b = TestSelectableIdentifier(id: "B");
  final c = TestSelectableIdentifier(id: "C");
  final d = TestSelectableIdentifier(id: "D");
  final e = TestSelectableIdentifier(id: "E");
  final order = [a, b, c, d, e];

  test("a range moves its far end across the anchor while the anchor "
      "stays", () {
    final container = ProviderContainer.test();
    container.read(selectionProvider.notifier)
      ..selectOnly(c)
      ..selectRange(e, order: order)
      ..selectRange(a, order: order);

    expect(container.read(selectionProvider), [a, b, c]);
  });

  test("a range keeps the items toggled before its anchor", () {
    final container = ProviderContainer.test();
    container.read(selectionProvider.notifier)
      ..selectOnly(a)
      ..toggle(c)
      ..selectRange(e, order: order);

    expect(container.read(selectionProvider), [a, c, d, e]);
  });

  test("a range with its anchor on another surface starts where focus "
      "left and replaces the selection", () {
    final container = ProviderContainer.test();
    final elsewhere = TestSelectableIdentifier(id: "elsewhere");
    container.read(selectionProvider.notifier)
      ..selectOnly(elsewhere)
      ..selectRange(d, order: order, from: b);

    expect(container.read(selectionProvider), [b, c, d]);
  });
}
