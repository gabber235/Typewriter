import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/trait.dart";
import "package:typewriter_testkit/src/core/world.dart";

/// The panel plays [table] in place of the standard motion token table.
Trait playsMotion(TypewriterMotion table) => _MotionTable(table);

final class _MotionTable extends Trait {
  const _MotionTable(this.table);

  final TypewriterMotion table;

  @override
  Slot get slot => const Slot("motionTable");

  @override
  String get description => "playsMotion";

  @override
  void applyTo(WorldBuilder world) => world.motionTable = table;
}

/// This table with every loop limited to one round, as the test world
/// installs it.
extension OneRoundLoops on TypewriterMotion {
  TypewriterMotion get oneRoundLoops {
    var table = this;
    for (final token in MotionToken.values) {
      final spec = table.spec(token);
      if (spec.motion case final LoopMotion loop) {
        table = table.withSpec(token, spec.copyWith(motion: loop.limitedTo(1)));
      }
    }
    return table;
  }
}
