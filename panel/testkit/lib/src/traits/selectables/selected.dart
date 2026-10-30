import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The user has [selection] selected when the panel opens, so the inspector
/// shows it, as after clicking it.
Trait selected(List<SelectableIdentifier> selection) => _Selected(selection);

final class _Selected extends Trait {
  const _Selected(this.selection);

  final List<SelectableIdentifier> selection;

  @override
  Slot get slot => const Slot("selection");

  @override
  String get description =>
      "selected(${selection.map((it) => it.id).join(", ")})";

  @override
  void applyTo(WorldBuilder world) => world.onStart((started) {
    // The selection lives while someone watches it; the world watches it
    // until the page shows it.
    final subscription = started.container.listen(selectionProvider, (_, _) {});
    started
      ..addCleanup(subscription.close)
      ..container.read(selectionProvider.notifier).selectAll(selection);
  });
}
