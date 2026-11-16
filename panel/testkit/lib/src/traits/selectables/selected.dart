import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The user has [selection] selected when the panel opens, so the inspector
/// shows it, as after clicking it. With [selecting] the items were added one
/// by one instead, as Space or a toggle click adds them, so the selection is
/// in select mode and every item shows its check.
Trait selected(
  List<SelectableIdentifier> selection, {
  bool selecting = false,
}) => _Selected(selection, selecting: selecting);

final class _Selected extends Trait {
  const _Selected(this.selection, {required this.selecting});

  final List<SelectableIdentifier> selection;
  final bool selecting;

  @override
  Slot get slot => const Slot("selection");

  @override
  String get description =>
      "selected(${selection.map((it) => it.id).join(", ")}"
      "${selecting ? ", selecting: true" : ""})";

  @override
  void applyTo(WorldBuilder world) => world.onStart((started) {
    // The selection lives while someone watches it; the world watches it
    // until the page shows it.
    final subscription = started.container.listen(selectionProvider, (_, _) {});
    started.addCleanup(subscription.close);
    final notifier = started.container.read(selectionProvider.notifier);
    if (!selecting) return notifier.replace(selection);
    selection.forEach(notifier.toggle);
  });
}
