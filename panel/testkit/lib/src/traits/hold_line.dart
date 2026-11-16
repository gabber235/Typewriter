import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The hold's outcome line sits in [layout], for the maintainer's trial.
Trait holdLine(HoldLineLayout layout) => _HoldLine(layout);

final class _HoldLine extends Trait {
  const _HoldLine(this.layout);

  final HoldLineLayout layout;

  @override
  Slot get slot => const Slot("holdLine");

  @override
  String get description => "holdLine(${layout.name})";

  @override
  void applyTo(WorldBuilder world) => world.holdLineLayout = layout;
}
